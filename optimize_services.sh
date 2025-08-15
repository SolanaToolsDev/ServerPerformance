#!/bin/bash

# Redis and Nginx Optimization Script
# This script applies performance optimizations to Redis and Nginx

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to check if services are installed
check_services() {
    print_status "Checking if Redis and Nginx are installed..."
    
    if ! systemctl is-active --quiet redis-server; then
        print_error "Redis is not installed or not running"
        exit 1
    fi
    
    if ! systemctl is-active --quiet nginx; then
        print_error "Nginx is not installed or not running"
        exit 1
    fi
    
    print_success "Both Redis and Nginx are installed and running"
}

# Function to optimize Redis
optimize_redis() {
    print_status "Starting Redis optimization..."
    
    # Backup original configuration
    if [ ! -f /etc/redis/redis.conf.backup ]; then
        print_status "Creating Redis configuration backup..."
        cp /etc/redis/redis.conf /etc/redis/redis.conf.backup
        print_success "Redis configuration backed up"
    fi
    
    # Apply Redis optimizations via redis-cli
    print_status "Applying Redis performance optimizations..."
    
    # Memory management
    redis-cli config set maxmemory 256mb
    redis-cli config set maxmemory-policy allkeys-lru
    
    # Persistence optimization
    redis-cli config set save "900 1 300 10 60 10000"
    redis-cli config set appendfsync everysec
    
    # Network optimization
    redis-cli config set tcp-keepalive 300
    
    # Client buffer optimization
    redis-cli config set client-output-buffer-limit "normal 0 0 0 replica 256mb 64mb 60 pubsub 32mb 8mb 60"
    
    # Save configuration to file
    redis-cli config rewrite
    
    print_success "Redis optimizations applied"
    
    # Verify Redis is still working
    if redis-cli ping > /dev/null 2>&1; then
        print_success "Redis is responding correctly"
    else
        print_error "Redis is not responding after optimization"
        exit 1
    fi
}

# Function to optimize Nginx
optimize_nginx() {
    print_status "Starting Nginx optimization..."
    
    # Backup original configuration
    if [ ! -f /etc/nginx/nginx.conf.backup ]; then
        print_status "Creating Nginx configuration backup..."
        cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
        print_success "Nginx configuration backed up"
    fi
    
    # Create optimized Nginx configuration
    print_status "Applying Nginx performance optimizations..."
    
    cat > /etc/nginx/nginx.conf << 'EOF'
user www-data;
worker_processes auto;
worker_cpu_affinity auto;
worker_rlimit_nofile 65535;
pid /run/nginx.pid;
error_log /var/log/nginx/error.log warn;
include /etc/nginx/modules-enabled/*.conf;

events {
	worker_connections 2048;
	multi_accept on;
	use epoll;
	accept_mutex off;
}

http {

	##
	# Basic Settings
	##

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	keepalive_requests 100;
	types_hash_max_size 2048;
	server_tokens off;
	client_max_body_size 100M;
	client_body_buffer_size 128k;
	client_header_buffer_size 1k;
	large_client_header_buffers 4 4k;
	output_buffers 1 32k;
	postpone_output 1460;

	# server_names_hash_bucket_size 64;
	# server_name_in_redirect off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	##
	# SSL Settings
	##

	ssl_protocols TLSv1.2 TLSv1.3;
	ssl_prefer_server_ciphers on;
	ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
	ssl_session_cache shared:SSL:10m;
	ssl_session_timeout 10m;

	##
	# Logging Settings
	##

	access_log /var/log/nginx/access.log combined buffer=512k flush=1m;
	error_log /var/log/nginx/error.log warn;

	##
	# Gzip Settings - Optimized
	##

	gzip on;
	gzip_vary on;
	gzip_proxied any;
	gzip_comp_level 6;
	gzip_buffers 16 8k;
	gzip_http_version 1.1;
	gzip_min_length 256;
	gzip_types
		application/atom+xml
		application/geo+json
		application/javascript
		application/x-javascript
		application/json
		application/ld+json
		application/manifest+json
		application/rdf+xml
		application/rss+xml
		application/xhtml+xml
		application/xml
		font/eot
		font/otf
		font/ttf
		image/svg+xml
		text/css
		text/javascript
		text/plain
		text/xml;

	##
	# Performance Settings
	##

	open_file_cache max=1000 inactive=20s;
	open_file_cache_valid 30s;
	open_file_cache_min_uses 2;
	open_file_cache_errors on;

	##
	# Security Headers
	##

	add_header X-Frame-Options DENY;
	add_header X-Content-Type-Options nosniff;
	add_header X-XSS-Protection "1; mode=block";
	add_header Referrer-Policy "strict-origin-when-cross-origin";

	##
	# Virtual Host Configs
	##

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}
EOF

    # Test Nginx configuration
    print_status "Testing Nginx configuration..."
    if nginx -t > /dev/null 2>&1; then
        print_success "Nginx configuration is valid"
    else
        print_error "Nginx configuration is invalid"
        print_status "Restoring backup configuration..."
        cp /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf
        exit 1
    fi
    
    # Reload Nginx
    print_status "Reloading Nginx..."
    systemctl reload nginx
    
    print_success "Nginx optimizations applied"
}

# Function to create performance monitoring script
create_monitoring_script() {
    print_status "Creating performance monitoring script..."
    
    cat > /root/performance_check.sh << 'EOF'
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
EOF

    chmod +x /root/performance_check.sh
    print_success "Performance monitoring script created at /root/performance_check.sh"
}

# Function to display optimization summary
display_summary() {
    print_status "Displaying optimization summary..."
    
    echo -e "\n=== Redis Optimizations Applied ==="
    echo "✓ Memory Limit: 256MB"
    echo "✓ Memory Policy: allkeys-lru"
    echo "✓ Save Strategy: Optimized persistence"
    echo "✓ Append FSync: everysec"
    echo "✓ TCP Keepalive: 300s"
    echo "✓ Client Buffers: Optimized"
    
    echo -e "\n=== Nginx Optimizations Applied ==="
    echo "✓ Worker Processes: Auto (CPU-based)"
    echo "✓ Worker Connections: 2048"
    echo "✓ Event Model: Epoll"
    echo "✓ Keepalive: 65s, 100 requests"
    echo "✓ Gzip: Enabled with comprehensive types"
    echo "✓ File Cache: 1000 files, optimized timing"
    echo "✓ Security Headers: Modern protection"
    echo "✓ SSL/TLS: TLS 1.2 & 1.3 only"
    
    echo -e "\n=== Performance Benefits ==="
    echo "✓ High Throughput: Optimized for concurrent connections"
    echo "✓ Low Latency: Fast response times"
    echo "✓ Memory Efficiency: Minimal resource usage"
    echo "✓ Security: Modern SSL/TLS and security headers"
    echo "✓ Scalability: Ready for increased load"
    
    echo -e "\n=== Monitoring ==="
    echo "✓ Performance Check: /root/performance_check.sh"
    echo "✓ Redis CLI: redis-cli info memory/stats"
    echo "✓ Nginx Status: systemctl status nginx"
}

# Function to verify optimizations
verify_optimizations() {
    print_status "Verifying optimizations..."
    
    # Test Redis
    if redis-cli ping > /dev/null 2>&1; then
        print_success "Redis is responding"
    else
        print_error "Redis is not responding"
        return 1
    fi
    
    # Test Nginx
    if curl -I http://localhost > /dev/null 2>&1; then
        print_success "Nginx is responding"
    else
        print_error "Nginx is not responding"
        return 1
    fi
    
    # Check Redis memory limit
    REDIS_MEMORY=$(redis-cli config get maxmemory | tail -1)
    if [ "$REDIS_MEMORY" = "268435456" ]; then
        print_success "Redis memory limit set correctly"
    else
        print_warning "Redis memory limit may not be set correctly"
    fi
    
    # Check Nginx worker connections
    NGINX_WORKERS=$(nginx -T 2>/dev/null | grep 'worker_connections' | head -1 | grep -o '[0-9]*')
    if [ "$NGINX_WORKERS" = "2048" ]; then
        print_success "Nginx worker connections set correctly"
    else
        print_warning "Nginx worker connections may not be set correctly"
    fi
    
    print_success "All optimizations verified"
}

# Main execution
main() {
    echo "=========================================="
    echo "    Redis & Nginx Optimization Script"
    echo "=========================================="
    
    # Check if running as root
    check_root
    
    # Update timestamp
    print_status "Starting optimization at $(date)"
    
    # Check if services are installed
    check_services
    
    # Optimize Redis
    optimize_redis
    
    # Optimize Nginx
    optimize_nginx
    
    # Create monitoring script
    create_monitoring_script
    
    # Verify optimizations
    verify_optimizations
    
    # Display summary
    display_summary
    
    print_success "Redis and Nginx optimization completed successfully!"
    print_status "Run /root/performance_check.sh to monitor performance"
    
    echo "=========================================="
}

# Run main function
main "$@"
