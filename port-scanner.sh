#!/bin/bash 

port_scanner() {
  local host=$1
  local start_port=${2:-1}
  local end_port=${3:-1024}
  
  for ((port=start_port; port<=end_port; port++)); do
    timeout 0.1 bash -c "</dev/tcp/$host/$port" 2>/dev/null && echo "Port $port: OPEN"
  done
}
