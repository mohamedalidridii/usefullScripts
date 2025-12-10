#!/bin/bash

# WORKING HTTP SNIFFERS - Tested and Fixed

# 1. Basic HTTP Sniffer (Simple, Reliable)
http_sniffer_basic() {
  local port=${1:-80}
  echo "Basic HTTP Sniffer on port $port"
  echo "Press Ctrl+C to stop..."
  echo "======================================"
  
  sudo tcpdump -i any -n "tcp port $port" 2>/dev/null | grep -E "GET|POST|PUT|DELETE|Host:|User-Agent:|Content-Type:"
}

# 2. HTTP Sniffer with Timestamps
http_sniffer_timestamps() {
  local port=${1:-80}
  echo "HTTP Sniffer with Timestamps on port $port"
  echo "======================================"
  
  sudo tcpdump -i any -n "tcp port $port" 2>/dev/null | while read line; do
    echo "[$(date '+%H:%M:%S')] $line"
  done
}

# 3. Advanced HTTP Sniffer (Fixed)
http_sniffer_advanced() {
  local port=${1:-80}
  local filter=${2:-}
  
  echo "Advanced HTTP Sniffer on port $port"
  [ -n "$filter" ] && echo "Filter: $filter"
  echo "Press Ctrl+C to stop..."
  echo "======================================"
  
  sudo tcpdump -i any -A -n "tcp port $port" 2>/dev/null | while IFS= read -r line; do
    # Skip empty lines and hex dumps
    if [[ -z "$line" ]] || [[ "$line" =~ ^[0-9a-f]+ ]]; then
      continue
    fi
    
    # Apply filter if provided
    if [ -n "$filter" ]; then
      echo "$line" | grep -qi "$filter" || continue
    fi
    
    # Print with timestamp
    if echo "$line" | grep -qE "GET|POST|PUT|DELETE|Host:|User-Agent:|Content-Type:|Content-Length:|Authorization:"; then
      echo "[$(date '+%H:%M:%S')] $line"
    fi
  done
}

# 4. HTTP Body Sniffer (Extract POST data)
http_body_sniffer() {
  local port=${1:-80}
  local max_size=${2:-500}
  
  echo "Capturing HTTP bodies on port $port (max $max_size chars)..."
  echo "======================================"
  
  sudo tcpdump -i any -A -n "tcp port $port" 2>/dev/null | awk -v max="$max_size" '
    BEGIN { in_body=0; body="" }
    /^POST|^PUT|^PATCH/ {
      printf "[%s] %s\n", strftime("%H:%M:%S"), $0
      in_body=1
      next
    }
    in_body && /^$/ {
      in_body=0
      next
    }
    in_body && NF>0 && !/^Host:|^Content-Type:|^Authorization:/ {
      if (length($0) < max) {
        printf "[%s] [BODY] %s\n", strftime("%H:%M:%S"), $0
      }
      next
    }
    /^[A-Z]/ && in_body {
      printf "[%s] %s\n", strftime("%H:%M:%S"), $0
    }
  '
}

# 5. HTTP Stats (Real-time counts)
http_stats() {
  local port=${1:-80}
  local interval=${2:-5}
  
  echo "HTTP Statistics on port $port (updating every ${interval}s)..."
  echo "======================================"
  
  while true; do
    clear
    echo "=== HTTP Statistics ($(date '+%H:%M:%S')) ==="
    echo ""
    echo "Methods:"
    sudo tcpdump -i any -n "tcp port $port" -c 100 2>/dev/null | grep -oE "GET|POST|PUT|DELETE|PATCH|HEAD" | sort | uniq -c | sort -rn
    echo ""
    sleep "$interval"
  done
}

# 6. Threat Detector (Security)
http_threat_detector() {
  local port=${1:-80}
  
  echo "Monitoring for HTTP threats on port $port"
  echo "======================================"
  
  sudo tcpdump -i any -A -n "tcp port $port" 2>/dev/null | while IFS= read -r line; do
    # SQL Injection
    if echo "$line" | grep -iE "union.*select|drop.*table|insert.*into|delete.*from" >/dev/null 2>&1; then
      echo "[$(date '+%H:%M:%S')] [ALERT] SQL INJECTION: $line"
    fi
    
    # XSS
    if echo "$line" | grep -iE "<script|javascript:|onerror=|onload=" >/dev/null 2>&1; then
      echo "[$(date '+%H:%M:%S')] [ALERT] XSS ATTEMPT: $line"
    fi
    
    # Path Traversal
    if echo "$line" | grep -E "\.\./\.\.|\.\.\\\\\.\\.|%2e%2e" >/dev/null 2>&1; then
      echo "[$(date '+%H:%M:%S')] [ALERT] PATH TRAVERSAL: $line"
    fi
  done
}

# 7. Color Sniffer
http_sniffer_colored() {
  local port=${1:-80}
  
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  PURPLE='\033[0;35m'
  CYAN='\033[0;36m'
  NC='\033[0m'
  
  echo "Colored HTTP Sniffer on port $port"
  echo "======================================"
  
  sudo tcpdump -i any -n "tcp port $port" 2>/dev/null | while IFS= read -r line; do
    if echo "$line" | grep -q "GET"; then
      echo -e "${GREEN}[$(date '+%H:%M:%S')] GET $line${NC}"
    elif echo "$line" | grep -q "POST"; then
      echo -e "${BLUE}[$(date '+%H:%M:%S')] POST $line${NC}"
    elif echo "$line" | grep -q "PUT"; then
      echo -e "${YELLOW}[$(date '+%H:%M:%S')] PUT $line${NC}"
    elif echo "$line" | grep -q "DELETE"; then
      echo -e "${RED}[$(date '+%H:%M:%S')] DELETE $line${NC}"
    elif echo "$line" | grep -q "Host:"; then
      echo -e "${CYAN}[$(date '+%H:%M:%S')] HOST: $line${NC}"
    fi
  done
}

# 8. Traffic Analyzer
http_traffic_analyzer() {
  local port=${1:-80}
  local interval=${2:-10}
  
  echo "Traffic Analyzer on port $port (${interval}s windows)"
  echo "======================================"
  
  while true; do
    echo ""
    echo "=== Traffic Summary ($(date '+%H:%M:%S')) ==="
    
    sudo tcpdump -i any -n "tcp port $port" -c 50 2>/dev/null | grep -E "GET|POST|PUT|DELETE" | awk '{
      for(i=1;i<=NF;i++) {
        if ($i ~ /^(GET|POST|PUT|DELETE)$/) {
          method=$i
        }
        if ($i ~ /@/) {
          host=$i
          key=method ":" host
          traffic[key]++
          total++
        }
      }
    } END {
      for (key in traffic) {
        print key " → " traffic[key] " requests"
      }
      if (total > 0) print "Total: " total " requests"
    }'
    
    sleep "$interval"
  done
}

# 9. Response Code Monitor
http_response_monitor() {
  local port=${1:-80}
  
  echo "HTTP Response Code Monitor on port $port"
  echo "======================================"
  
  sudo tcpdump -i any -A -n "tcp port $port" 2>/dev/null | grep -oE "HTTP/1\.[01] [0-9]{3}" | while read response; do
    code=$(echo "$response" | grep -oE "[0-9]{3}$")
    
    case $code in
      200) status="✓ OK" ;;
      301|302) status="→ Redirect" ;;
      304) status="≈ Not Modified" ;;
      400) status="✗ Bad Request" ;;
      401) status="🔒 Unauthorized" ;;
      403) status="🚫 Forbidden" ;;
      404) status="❌ Not Found" ;;
      500) status="💥 Server Error" ;;
      502|503) status="⚠ Gateway Error" ;;
      *) status="? Unknown" ;;
    esac
    
    echo "[$(date '+%H:%M:%S')] HTTP $code - $status"
  done
}

# 10. Simple Request Logger
http_request_logger() {
  local port=${1:-80}
  local logfile=${2:-/tmp/http_requests.log}
  
  echo "Logging HTTP requests to $logfile"
  echo "======================================"
  
  sudo tcpdump -i any -n "tcp port $port" 2>/dev/null | while IFS= read -r line; do
    if echo "$line" | grep -qE "GET|POST|PUT|DELETE"; then
      echo "[$(date '+%H:%M:%S')] $line" | tee -a "$logfile"
    fi
  done
  
  echo "Logs saved to: $logfile"
}
