#!/bin/bash

# Performance Check Script for Redis and Nginx Optimizations

echo "=========================================="
echo "    Performance Optimization Check"
echo "=========================================="

echo -e "\n=== Redis Status ==="
systemctl status redis-server --no-pager

echo -e "\n=== Redis Configuration ==="
echo "Memory Limit: $(redis-cli config get maxmemory | tail -1)"
echo "Memory Policy: $(redis-cli config get maxmemory-policy | tail -1)"
echo "Save Settings: $(redis-cli config get save | tail -1)"
echo "Append FSync: $(redis-cli config get appendfsync | tail -1)"
echo "TCP Keepalive: $(redis-cli config get tcp-keepalive | tail -1)"

echo -e "\n=== Redis Performance Test ==="
redis-cli ping
redis-cli info memory | grep -E "used_memory|maxmemory"
redis-cli info stats | grep -E "total_commands_processed|total_connections_received"

echo -e "\n=== Nginx Status ==="
systemctl status nginx --no-pager

echo -e "\n=== Nginx Configuration ==="
echo "Worker Processes: $(nginx -T 2>/dev/null | grep 'worker_processes' | head -1)"
echo "Worker Connections: $(nginx -T 2>/dev/null | grep 'worker_connections' | head -1)"
echo "Gzip Enabled: $(nginx -T 2>/dev/null | grep 'gzip on' | wc -l)"

echo -e "\n=== Nginx Performance Test ==="
curl -I http://localhost -w "Response Time: %{time_total}s\n" -s -o /dev/null

echo -e "\n=== System Resources ==="
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memory Usage: $(free -m | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
echo "Disk Usage: $(df -h / | awk 'NR==2{print $5}')"

echo -e "\n=== Network Optimizations ==="
echo "TCP Congestion Control: $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')"
echo "TCP Buffer Size (Max): $(sysctl net.core.rmem_max | awk '{print $3}')"
echo "Queue Discipline: $(sysctl net.core.default_qdisc | awk '{print $3}')"

echo -e "\n=========================================="
echo "    Optimization Check Complete"
echo "=========================================="
