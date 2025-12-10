#!/bin/bash

bandwidth_monitor() {
  echo "Monitoring bandwidth usage..."
  echo "PID    Process          Sent(MB)    Recv(MB)"
  
  while true; do
    cat /proc/net/dev | tail -n +3 | awk '{
      sent+=$10; recv+=$2
    } END {
      print "Total: " sent/1024/1024 " MB sent, " recv/1024/1024 " MB received"
    }'
    sleep 2
    clear
  done
}
