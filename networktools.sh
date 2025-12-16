#!/bin/bash

# CREATIVE & OUT-OF-THE-BOX NETWORK TOOLS

# 1. ASCII ART Network Visualization (Real-time)
network_art_display() {
  echo "🌐 LIVE NETWORK TRAFFIC VISUALIZER 🌐"
  echo "════════════════════════════════════"
  
  while true; do
    clear
    echo "🌐 LIVE NETWORK TRAFFIC VISUALIZER 🌐"
    echo "════════════════════════════════════"
    
    # Get packet counts
    sudo tcpdump -i any -c 50 2>/dev/null | wc -l
    
    # Create visual bars for each protocol
    http_count=$(sudo tcpdump -i any -c 100 "tcp port 80 or tcp port 443" 2>/dev/null | wc -l)
    dns_count=$(sudo tcpdump -i any -c 100 "udp port 53" 2>/dev/null | wc -l)
    ssh_count=$(sudo tcpdump -i any -c 100 "tcp port 22" 2>/dev/null | wc -l)
    
    echo ""
    echo "HTTP/HTTPS: $(printf '█%.0s' $(seq 1 $((http_count/2))))"
    echo "DNS:        $(printf '▓%.0s' $(seq 1 $((dns_count/2))))"
    echo "SSH:        $(printf '▒%.0s' $(seq 1 $((ssh_count/2))))"
    
    sleep 2
  done
}

# 2. Network "Heat Map" - Shows which IPs are "hot"
network_heat_map() {
  echo "🔥 NETWORK HEAT MAP - Most Active IPs 🔥"
  echo "════════════════════════════════════════"
  
  declare -A ip_heat
  
  while true; do
    clear
    echo "🔥 NETWORK HEAT MAP - Most Active IPs 🔥"
    echo "════════════════════════════════════════"
    echo ""
    
    sudo tcpdump -i any -c 200 -n 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq -c | sort -rn | head -10 | while read count ip; do
      heat_level=$((count / 2))
      
      if [ $heat_level -gt 30 ]; then
        emoji="🔴"
      elif [ $heat_level -gt 15 ]; then
        emoji="🟠"
      elif [ $heat_level -gt 5 ]; then
        emoji="🟡"
      else
        emoji="🟢"
      fi
      
      printf "%s %-15s " "$emoji" "$ip"
      printf '█%.0s' $(seq 1 $heat_level)
      printf "\n"
    done
    
    sleep 3
  done
}

# 3. "Packet Detective" - Find suspicious patterns
packet_detective() {
  echo "🔍 PACKET DETECTIVE - Looking for Suspicious Activity 🔍"
  echo "═══════════════════════════════════════════════════════"
  
  sudo tcpdump -i any -A 2>/dev/null | while read -r line; do
    # Detect scanning behavior
    if echo "$line" | grep -qE "FLAGS.*\[S\]" >/dev/null 2>&1; then
      echo "🚨 [SYN SCAN DETECTED] Connection attempt: $line"
    fi
    
    # Detect suspicious ports
    if echo "$line" | grep -E "\.(139|445|3389|22):" >/dev/null 2>&1; then
      echo "⚠️  [SUSPICIOUS PORT] $line"
    fi
    
    # Detect DNS requests to unusual domains
    if echo "$line" | grep -qE "\.tk|\.cc|\.su|\.xyz" >/dev/null 2>&1; then
      echo "👀 [UNUSUAL DOMAIN] DNS query detected: $line"
    fi
    
    # Detect rapid requests (potential flooding)
    if echo "$line" | grep -q "GET.*GET.*GET"; then
      echo "⚡ [RAPID REQUESTS] Potential flooding: $line"
    fi
  done
}

# 4. "Internet Mood Ring" - Shows network health in emojis
internet_mood_ring() {
  echo "😊 INTERNET MOOD RING 😊"
  echo "════════════════════════"
  
  while true; do
    clear
    echo "😊 INTERNET MOOD RING 😊"
    echo "════════════════════════"
    echo ""
    
    # Check latency
    latency=$(ping -c 1 8.8.8.8 2>/dev/null | grep time= | grep -oP 'time=\K[^ ]+')
    
    if [ -z "$latency" ]; then
      echo "😵 NO CONNECTION"
      mood="offline"
    elif (( $(echo "$latency < 20" | bc -l) )); then
      echo "😍 EXCELLENT CONNECTION ($latency ms)"
      mood="excellent"
    elif (( $(echo "$latency < 50" | bc -l) )); then
      echo "😊 GOOD CONNECTION ($latency ms)"
      mood="good"
    elif (( $(echo "$latency < 100" | bc -l) )); then
      echo "😐 OKAY CONNECTION ($latency ms)"
      mood="okay"
    else
      echo "😢 SLOW CONNECTION ($latency ms)"
      mood="slow"
    fi
    
    # Check packet loss
    echo ""
    loss=$(ping -c 10 8.8.8.8 2>&1 | grep -oP '\d+(?=% packet loss)')
    
    if [ "$loss" -eq 0 ]; then
      echo "📊 PACKET LOSS: 0% ✅"
    elif [ "$loss" -lt 5 ]; then
      echo "📊 PACKET LOSS: ${loss}% ⚠️"
    else
      echo "📊 PACKET LOSS: ${loss}% 🔴"
    fi
    
    # Show bandwidth usage
    echo ""
    echo "📡 BANDWIDTH ACTIVITY:"
    sudo ifstat -i wlan0 1 1 2>/dev/null | tail -1 | awk '{print "  ↓ " $1 " KB/s (down)"; print "  ↑ " $2 " KB/s (up)"}'
    
    sleep 3
  done
}

# 5. "Network Stalker" - Show what websites users visit in real-time
network_stalker() {
  echo "🕵️ NETWORK STALKER - Real-time Website Monitor 🕵️"
  echo "═══════════════════════════════════════════════"
  echo "⚠️  This shows Host headers (what websites are accessed)"
  echo ""
  
  sudo tcpdump -i any -A "tcp port 80 or tcp port 443" 2>/dev/null | grep -oP "(?<=Host: )[^\r]+" | while read host; do
    case "$host" in
      *youtube*) emoji="🎥" ;;
      *github*) emoji="💻" ;;
      *google*) emoji="🔍" ;;
      *facebook*) emoji="👥" ;;
      *netflix*) emoji="🎬" ;;
      *twitter*) emoji="🐦" ;;
      *reddit*) emoji="🤖" ;;
      *pornhub*|*xvideos*|*xnxx*) emoji="🔞" ;;
      *instagram*) emoji="📸" ;;
      *tiktok*) emoji="🎵" ;;
      *amazon*) emoji="🛍️" ;;
      *bank*|*paypal*) emoji="💰" ;;
      *dating*|*tinder*) emoji="💕" ;;
      *gambling*|*casino*) emoji="🎰" ;;
      *vpn*) emoji="🛡️" ;;
      *proxy*) emoji="🔌" ;;
      *) emoji="🌐" ;;
    esac
    
    echo "[$emoji] $host"
  done
}

# 6. "Packet Roulette" - Random fun facts about captured packets
packet_roulette() {
  echo "🎰 PACKET ROULETTE - Random Network Fun Facts 🎰"
  echo "═════════════════════════════════════════════════"
  
  while true; do
    sudo tcpdump -i any -c 1 -n 2>/dev/null | {
      read line
      
      # Extract info
      if echo "$line" | grep -q "GET\|POST"; then
        protocol="HTTP"
        size=$(echo "$line" | grep -oP 'length \K[0-9]+')
        echo "🎯 You just sent a $protocol packet of ${size:-unknown} bytes!"
      elif echo "$line" | grep -q "UDP"; then
        echo "📡 UDP packet detected - Faster but less reliable!"
      elif echo "$line" | grep -q "DNS"; then
        domain=$(echo "$line" | grep -oP 'A\? \K[^.]*')
        echo "🔍 Someone looked up: $domain"
      fi
      
      # Random fun fact
      facts=(
        "Did you know? HTTP packets travel at ~2/3 the speed of light! 💡"
        "Interesting: Your data traveled through at least 10 different routers! 🛣️"
        "Fun fact: This packet might have bounced off satellites! 🛰️"
        "Cool: Somewhere, someone received your data instantaneously! ⚡"
        "Amazing: This packet is literally traveling the world! 🌍"
      )
      
      echo "${facts[$RANDOM % ${#facts[@]}]}"
      echo ""
      sleep 1
    }
  done
}

# 7. "Network Rave" - Colorful, pulsing network activity
network_rave() {
  colors=(
    '\033[0;31m'  # Red
    '\033[0;32m'  # Green
    '\033[0;33m'  # Yellow
    '\033[0;34m'  # Blue
    '\033[0;35m'  # Purple
    '\033[0;36m'  # Cyan
  )
  NC='\033[0m'
  
  echo "🎉 NETWORK RAVE MODE 🎉"
  echo "═══════════════════════"
  
  while true; do
    clear
    echo "🎉 NETWORK RAVE MODE 🎉"
    echo "═══════════════════════"
    echo ""
    
    color_index=0
    sudo tcpdump -i any -c 20 -n 2>/dev/null | while read line; do
      if echo "$line" | grep -qE "GET|POST|DNS"; then
        color_index=$(( (color_index + 1) % 6 ))
        echo -e "${colors[$color_index]}✨ $line ${NC}"
      fi
    done
    
    echo -e "\n${colors[5]}🎵 Beep boop beep! 🎵${NC}\n"
    sleep 1
  done
}

# 8. "Internet Time Traveler" - Predict next traffic pattern
internet_time_traveler() {
  echo "🔮 INTERNET TIME TRAVELER - Predict Next Request 🔮"
  echo "════════════════════════════════════════════════"
  
  declare -A patterns
  
  for i in {1..50}; do
    sudo tcpdump -i any -c 10 -n 2>/dev/null | grep -oE "(GET|POST|DNS)" | while read method; do
      patterns["$method"]=$(( ${patterns["$method"]:-0} + 1 ))
    done
  done
  
  echo ""
  echo "🔮 PREDICTIONS BASED ON PATTERN ANALYSIS:"
  echo ""
  
  for method in "${!patterns[@]}"; do
    percentage=$(( ${patterns[$method]} * 100 / 50 ))
    echo "  $method: ${percentage}% chance it will be next 🎯"
  done
  
  echo ""
  echo "Most likely next request: $(printf '%s\n' "${!patterns[@]}" | sort -k2 -rn | head -1)"
}

# 9. "Network Translator" - Turns packets into poetry
network_translator() {
  echo "📝 NETWORK TRANSLATOR - Packets as Poetry 📝"
  echo "═════════════════════════════════════════"
  
  sudo tcpdump -i any -A "tcp port 80 or tcp port 443" 2>/dev/null | while IFS= read -r line; do
    if echo "$line" | grep -q "GET"; then
      method=$(echo "$line" | grep -oP "GET \K[^ ]+")
      echo "🎭 A brave soul seeks: $method 🌟"
    fi
    
    if echo "$line" | grep -q "Host:"; then
      host=$(echo "$line" | sed 's/Host: //')
      echo "🏰 They venture to the realm of: $host"
    fi
    
    if echo "$line" | grep -q "User-Agent:"; then
      agent=$(echo "$line" | sed 's/User-Agent: //')
      echo "🤖 Riding upon: $agent"
    fi
    
    echo ""
  done
}

# 10. "Bandwidth Visualizer" - ASCII bandwidth meter
bandwidth_visualizer() {
  local interface=${1:-wlan0}
  
  echo "📊 BANDWIDTH VISUALIZER"
  echo "════════════════════════"
  
  while true; do
    clear
    echo "📊 BANDWIDTH VISUALIZER - $interface"
    echo "════════════════════════════════════"
    echo ""
    
    # Get bandwidth using iftop or ifstat
    if command -v iftop &> /dev/null; then
      iftop -i "$interface" -n -s 1 2>/dev/null | head -20
    elif command -v ifstat &> /dev/null; then
      echo "DOWNLOAD SPEED:"
      down=$(sudo ifstat -i "$interface" 1 1 2>/dev/null | tail -1 | awk '{print $1}')
      up=$(sudo ifstat -i "$interface" 1 1 2>/dev/null | tail -1 | awk '{print $2}')
      
      echo "  $(printf '█%.0s' $(seq 1 $((down/10)))) $down KB/s ⬇️"
      echo ""
      echo "UPLOAD SPEED:"
      echo "  $(printf '█%.0s' $(seq 1 $((up/10)))) $up KB/s ⬆️"
    else
      echo "⚠️  Install iftop or ifstat for bandwidth visualization"
      echo "Ubuntu: sudo apt install iftop"
      echo "CentOS: sudo yum install iftop"
      break
    fi
    
    sleep 2
  done
}

# 11. "Network Conspiracy" - Find connections you didn't make
network_conspiracy() {
  echo "🕵️ NETWORK CONSPIRACY - Unexpected Connections 🕵️"
  echo "═════════════════════════════════════════════════"
  
  known_sites=("google" "github" "youtube" "facebook" "cloudflare" "amazon")
  
  sudo tcpdump -i any -n 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort -u | while read ip; do
    # Try to resolve IP
    hostname=$(getent hosts "$ip" 2>/dev/null | awk '{print $2}')
    
    # Check if it's a known site
    is_known=0
    for known in "${known_sites[@]}"; do
      if echo "$hostname" | grep -qi "$known"; then
        is_known=1
        break
      fi
    done
    
    # If unknown, flag it
    if [ $is_known -eq 0 ] && [ -n "$hostname" ]; then
      echo "🚨 SUSPICIOUS: $ip ($hostname)"
    fi
  done
}

# 12. "Network DJ" - Beatmatch network traffic
network_dj() {
  echo "🎧 NETWORK DJ - Making beats from packets 🎧"
  echo "════════════════════════════════════════"
  
  while true; do
    sudo tcpdump -i any -c 1 -n 2>/dev/null >/dev/null
    
    # Create "beat" based on packet count
    packet_count=$(sudo tcpdump -i any -c 50 2>/dev/null | wc -l)
    
    # Make some noise
    if [ $((packet_count % 3)) -eq 0 ]; then
      printf "🎵 "; sleep 0.1
    elif [ $((packet_count % 2)) -eq 0 ]; then
      printf "🎶 "; sleep 0.15
    else
      printf "🎼 "; sleep 0.2
    fi
  done
}
