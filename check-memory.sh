#!/bin/bash




memory_profiler() {
  local pid=$1
  local interval=${2:-1}

  while kill -0 "$pid" 2>/dev/null; do
    if [ -f "/proc/$pid/status" ]; then
      rss=$(grep VmRSS "/proc/$pid/status" | awk '{print $2/1024 " MB"}')
      echo "$(date '+%H:%M:%S') PID $pid: $rss"
    fi
    sleep "$interval"
  done
}
