#!/bin/bash

# Pure Bash DNS resolver using /dev/udp and binary packet construction
# Requires: bash 4.2+, xxd, od, dd, timeout

# Helper: Convert string to hex
str_to_hex() {
    echo -n "$1" | od -An -tx1 | tr -d ' \n'
}

# Helper: Convert decimal to hex (2 bytes, big-endian)
dec_to_hex16() {
    printf "%04x" "$1"
}

# Parse domain name into DNS wire format (labels)
# example.com -> 07 6578616d706c65 03 636f6d 00
domain_to_wire() {
    local domain="$1"
    local wire=""
    
    # Split by dots and encode each label
    IFS='.' read -ra labels <<< "$domain"
    for label in "${labels[@]}"; do
        local len=${#label}
        wire+=$(printf "%02x" "$len")
        wire+=$(echo -n "$label" | od -An -tx1 | tr -d ' \n')
    done
    
    # Root label (0x00)
    wire+="00"
    echo "$wire"
}

# Wire format to domain (reverse operation)
wire_to_domain() {
    local wire="$1"
    local domain=""
    local pos=0
    
    while [[ $pos -lt ${#wire} ]]; do
        # Read length byte
        local len_hex="${wire:$pos:2}"
        local len=$((16#$len_hex))
        
        if [[ $len -eq 0 ]]; then
            break
        fi
        
        pos=$((pos + 2))
        
        # Read label
        local label_hex="${wire:$pos:$((len * 2))}"
        local label=$(echo "$label_hex" | xxd -r -p 2>/dev/null)
        domain+="$label."
        pos=$((pos + len * 2))
    done
    
    # Remove trailing dot
    echo "${domain%.*}"
}

# Construct DNS query packet
build_dns_query() {
    local domain="$1"
    local transaction_id="$2"  # Random 16-bit ID
    
    # DNS Header (12 bytes)
    local header=""
    
    # Transaction ID (2 bytes)
    header+="$transaction_id"
    
    # Flags: QR(0)=0, Opcode(4 bits)=0, AA=0, TC=0, RD(1)=1, RA=0, Z=0, RCODE(4)=0
    # 00 01 0000 0000 = 0x0100
    header+="0100"
    
    # Questions (2 bytes)
    header+="0001"
    
    # Answer RRs (2 bytes)
    header+="0000"
    
    # Authority RRs (2 bytes)
    header+="0000"
    
    # Additional RRs (2 bytes)
    header+="0000"
    
    # Question Section
    local question=""
    question+=$(domain_to_wire "$domain")
    
    # Query Type: A record (0x0001)
    question+="0001"
    
    # Query Class: IN (0x0001)
    question+="0001"
    
    echo "$header$question"
}

# Parse DNS response header
parse_dns_header() {
    local response="$1"
    
    if [[ ${#response} -lt 24 ]]; then
        echo "Response too short"
        return 1
    fi
    
    # Extract fields (each byte pair is 2 chars)
    local tx_id="${response:0:4}"
    local flags="${response:4:4}"
    local qdcount="${response:8:4}"
    local ancount="${response:12:4}"
    local nscount="${response:16:4}"
    local arcount="${response:20:4}"
    
    # Convert hex to decimal
    local flags_dec=$((16#$flags))
    local rcode=$((flags_dec & 0x0F))
    
    echo "TxID: 0x$tx_id, Flags: 0x$flags, QD: $((16#$qdcount)), AN: $((16#$ancount)), RCODE: $rcode"
}

# Parse A record from response
parse_a_record() {
    local response="$1"
    local offset=12  # Skip header
    
    if [[ ${#response} -lt 24 ]]; then
        return 1
    fi
    
    # Skip question section (simplified - assumes single question)
    local pos=$offset
    while [[ $pos -lt ${#response} ]]; do
        local byte="${response:$pos:2}"
        if [[ "$byte" == "00" ]]; then
            pos=$((pos + 2 + 8))  # Skip root label + type/class
            break
        fi
        # Jump past label (length byte + label)
        local len=$((16#$byte))
        pos=$((pos + 2 + len * 2))
    done
    
    # Now in answer section - skip name (usually pointer 0xC0 + offset)
    if [[ $pos -lt ${#response} ]]; then
        # Check for name compression (0xC0)
        if [[ "${response:$pos:2}" == "c0" ]]; then
            pos=$((pos + 4))  # Skip compressed name pointer
        else
            # Skip uncompressed name
            while [[ $pos -lt ${#response} ]]; do
                local byte="${response:$pos:2}"
                if [[ "$byte" == "00" ]]; then
                    pos=$((pos + 2))
                    break
                fi
                local len=$((16#$byte))
                pos=$((pos + 2 + len * 2))
            done
        fi
        
        # Type (2 bytes)
        if [[ $pos -ge ${#response} ]]; then return 1; fi
        local type="${response:$pos:4}"
        pos=$((pos + 4))
        
        # Class (2 bytes)
        if [[ $pos -ge ${#response} ]]; then return 1; fi
        local class="${response:$pos:4}"
        pos=$((pos + 4))
        
        # TTL (4 bytes)
        if [[ $pos -ge ${#response} ]]; then return 1; fi
        local ttl="${response:$pos:8}"
        pos=$((pos + 8))
        
        # RDLENGTH (2 bytes)
        if [[ $pos -ge ${#response} ]]; then return 1; fi
        local rdlen="${response:$pos:4}"
        pos=$((pos + 4))
        
        # RDATA - for A record, 4 bytes (IPv4)
        if [[ "$type" == "0001" ]] && [[ $((16#$rdlen)) -eq 4 ]]; then
            if [[ $((pos + 8)) -gt ${#response} ]]; then return 1; fi
            local rdata="${response:$pos:8}"
            # Convert hex pairs to decimal octets
            local octet1=$((16#${rdata:0:2}))
            local octet2=$((16#${rdata:2:2}))
            local octet3=$((16#${rdata:4:2}))
            local octet4=$((16#${rdata:6:2}))
            echo "$octet1.$octet2.$octet3.$octet4"
            return 0
        fi
    fi
    
    return 1
}

# Main DNS resolver
resolve_dns() {
    local domain="$1"
    local nameserver="${2:-8.8.8.8}"
    
    echo "[*] Resolving: $domain"
    echo "[*] Nameserver: $nameserver"
    
    # Generate random transaction ID
    local tx_id=$(printf "%04x" $((RANDOM % 65536)))
    
    # Build query packet
    local query_hex=$(build_dns_query "$domain" "$tx_id")
    
    echo "[*] Query (hex): $query_hex"
    
    # Create temp file for response
    local tmpfile=$(mktemp)
    trap "rm -f $tmpfile" EXIT
    
    # Send query via UDP with timeout
    {
        echo -n "$query_hex" | xxd -r -p >&3
        # Read response with 2 second timeout
        timeout 2 dd if=/proc/$$/fd/3 bs=1 count=512 2>/dev/null | tee "$tmpfile"
    } 3<>/dev/udp/$nameserver/53 2>/dev/null
    
    local response_hex=$(od -An -tx1 < "$tmpfile" | tr -d ' \n')
    
    if [[ -z "$response_hex" ]]; then
        echo "[-] No response received"
        return 1
    fi
    
    echo "[*] Response (first 96 hex chars): ${response_hex:0:96}"
    
    # Parse response
    echo "[*] Header info:"
    parse_dns_header "$response_hex"
    local header_status=$?
    
    if [[ $header_status -ne 0 ]]; then
        echo "[-] Failed to parse header"
        return 1
    fi
    
    # Extract answer
    local ip=$(parse_a_record "$response_hex")
    if [[ -n "$ip" ]]; then
        echo "[+] Answer: $ip"
        return 0
    else
        echo "[-] Could not parse answer section"
        return 1
    fi
}

# Run resolver
resolve_dns "${1:-google.com}" "${2:-8.8.8.8}"
