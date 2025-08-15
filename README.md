# Server Optimization Suite

A comprehensive collection of bash scripts for optimizing Ubuntu server performance, including system updates, network tuning, Redis, and Nginx optimizations.

## 📋 Table of Contents

- [Overview](#overview)
- [Scripts](#scripts)
- [Installation](#installation)
- [Usage](#usage)
- [Optimizations Applied](#optimizations-applied)
- [Monitoring](#monitoring)
- [Requirements](#requirements)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🚀 Overview

This suite provides automated server optimization for Ubuntu systems, focusing on:

- **System Updates**: Automated package updates and security patches
- **Network Performance**: TCP optimizations, BBR congestion control, buffer tuning
- **Redis Optimization**: Memory management, persistence, and performance tuning
- **Nginx Optimization**: Worker processes, compression, caching, and security
- **CPU Performance**: Frequency scaling (where available)
- **Monitoring**: Performance tracking and system health checks

## 📜 Scripts

### 1. `server_optimize.sh` - Main System Optimizer
Comprehensive system optimization including updates, network tuning, and performance monitoring.

**Features:**
- Automated system updates and upgrades
- Network performance optimizations
- CPU performance mode (where supported)
- Disk I/O optimizations
- Performance monitoring tools installation
- Persistent CPU performance service

### 2. `optimize_services.sh` - Redis & Nginx Optimizer
Specialized optimization for Redis and Nginx services.

**Features:**
- Redis memory and performance tuning
- Nginx worker and event model optimization
- Security headers and SSL/TLS configuration
- Configuration backups and validation
- Performance verification

### 3. `performance_check.sh` - Performance Monitor
Real-time performance monitoring and optimization verification.

**Features:**
- Service status monitoring
- Configuration verification
- Performance metrics display
- System resource usage
- Network optimization status

## 🛠️ Installation

### Prerequisites
- Ubuntu 20.04+ (tested on Ubuntu 24.04)
- Root access or sudo privileges
- Internet connection for package updates

### Quick Setup
```bash
# Clone or download the scripts
cd /root/Telegrambot

# Make scripts executable
chmod +x *.sh

# Install required packages (if not already installed)
sudo apt update
sudo apt install -y redis-server nginx
```

## 📖 Usage

### Full System Optimization
```bash
# Run complete system optimization
sudo ./server_optimize.sh
```

This script will:
1. Update and upgrade all packages
2. Install essential tools (git, curl, wget)
3. Apply network performance optimizations
4. Enable CPU performance mode (if supported)
5. Optimize disk I/O
6. Install monitoring tools
7. Create persistent performance services

### Redis & Nginx Optimization
```bash
# Optimize Redis and Nginx specifically
sudo ./optimize_services.sh
```

This script will:
1. Backup original configurations
2. Apply Redis performance optimizations
3. Apply Nginx performance optimizations
4. Verify all changes
5. Create performance monitoring script

### Performance Monitoring
```bash
# Check current performance status
./performance_check.sh
```

This script will display:
- Service status and health
- Current configuration settings
- Performance metrics
- System resource usage
- Network optimization status

## ⚡ Optimizations Applied

### System-Level Optimizations

#### Network Performance
```bash
# TCP Buffer Sizes
net.core.rmem_max = 134217728  # 128MB
net.core.wmem_max = 134217728  # 128MB

# TCP Congestion Control
net.ipv4.tcp_congestion_control = bbr

# Queue Discipline
net.core.default_qdisc = fq

# Connection Tracking
net.netfilter.nf_conntrack_max = 131072

# File Descriptors
fs.file-max = 2097152
```

#### CPU Performance
- Performance mode on all cores (where supported)
- Persistent systemd service for CPU optimization
- Automatic detection of cloud/VPS environments

#### Disk I/O
- SSD-optimized I/O schedulers
- NVMe and SATA SSD detection
- Automatic udev rules creation

### Redis Optimizations

#### Memory Management
```bash
maxmemory = 256MB
maxmemory-policy = allkeys-lru
maxmemory-samples = 5
```

#### Persistence
```bash
save = "900 1 300 10 60 10000"
appendfsync = everysec
appendonly = yes
```

#### Network & Performance
```bash
tcp-keepalive = 300
client-output-buffer-limit = "normal 0 0 0 replica 256mb 64mb 60 pubsub 32mb 8mb 60"
```

### Nginx Optimizations

#### Worker Configuration
```nginx
worker_processes auto;
worker_connections 2048;
worker_cpu_affinity auto;
worker_rlimit_nofile 65535;
```

#### Event Model
```nginx
events {
    worker_connections 2048;
    multi_accept on;
    use epoll;
    accept_mutex off;
}
```

#### Performance Settings
```nginx
# Keepalive
keepalive_timeout 65;
keepalive_requests 100;

# Buffers
client_max_body_size 100M;
client_body_buffer_size 128k;
client_header_buffer_size 1k;

# File Cache
open_file_cache max=1000 inactive=20s;
open_file_cache_valid 30s;
```

#### Gzip Compression
```nginx
gzip on;
gzip_vary on;
gzip_comp_level 6;
gzip_types application/javascript application/json text/css text/plain text/xml;
```

#### Security Headers
```nginx
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
add_header Referrer-Policy "strict-origin-when-cross-origin";
```

## 📊 Monitoring

### Performance Metrics

#### Redis Monitoring
```bash
# Memory usage
redis-cli info memory

# Performance stats
redis-cli info stats

# Configuration check
redis-cli config get maxmemory
```

#### Nginx Monitoring
```bash
# Status check
systemctl status nginx

# Configuration test
nginx -t

# Performance test
curl -I http://localhost -w "Response Time: %{time_total}s\n"
```

#### System Resources
```bash
# CPU usage
top -bn1 | grep "Cpu(s)"

# Memory usage
free -m

# Disk usage
df -h /
```

### Automated Monitoring
The `performance_check.sh` script provides comprehensive monitoring:
- Service status verification
- Configuration validation
- Performance metrics
- Resource usage tracking
- Network optimization status

## 🔧 Requirements

### System Requirements
- **OS**: Ubuntu 20.04+ (tested on Ubuntu 24.04)
- **Architecture**: x86_64
- **Memory**: 2GB+ RAM recommended
- **Storage**: 10GB+ free space
- **Network**: Internet connection for updates

### Software Requirements
- **Redis**: 6.0+ (installed via script)
- **Nginx**: 1.18+ (installed via script)
- **Bash**: 4.4+ (standard on Ubuntu)
- **Systemd**: Required for service management

## 🚨 Troubleshooting

### Common Issues

#### Redis Won't Start
```bash
# Check Redis logs
journalctl -u redis-server.service

# Test configuration
redis-server /etc/redis/redis.conf --test

# Restore backup if needed
cp /etc/redis/redis.conf.backup /etc/redis/redis.conf
```

#### Nginx Configuration Error
```bash
# Test configuration
nginx -t

# Check syntax
nginx -T

# Restore backup if needed
cp /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf
```

#### Network Optimizations Not Applied
```bash
# Check current settings
sysctl net.core.rmem_max
sysctl net.ipv4.tcp_congestion_control

# Apply manually if needed
sysctl -p /etc/sysctl.d/99-network-performance.conf
```

### Performance Issues

#### High Memory Usage
- Check Redis memory usage: `redis-cli info memory`
- Monitor Nginx worker processes: `systemctl status nginx`
- Review system resources: `./performance_check.sh`

#### Slow Response Times
- Verify network optimizations are applied
- Check Nginx worker connections
- Monitor Redis performance stats
- Review system load: `htop`

### Recovery Procedures

#### Restore Original Configurations
```bash
# Redis
cp /etc/redis/redis.conf.backup /etc/redis/redis.conf
systemctl restart redis-server

# Nginx
cp /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf
systemctl reload nginx
```

#### Reset Network Optimizations
```bash
# Remove custom sysctl settings
rm /etc/sysctl.d/99-network-performance.conf
sysctl -p
```

## 🤝 Contributing

### Development
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Testing
- Test on fresh Ubuntu installations
- Verify all optimizations are applied correctly
- Check for compatibility with different server sizes
- Validate backup and restore procedures

### Best Practices
- Always create backups before making changes
- Test configurations before applying
- Monitor performance after optimizations
- Document any new optimizations

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## ⚠️ Disclaimer

These scripts modify system configurations and should be used with caution. Always:
- Test in a development environment first
- Create backups before running
- Monitor system performance after changes
- Understand the implications of each optimization

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review the logs and error messages
3. Verify system requirements
4. Test with default configurations

---

**Note**: These optimizations are designed for production servers and may need adjustment based on specific use cases and server specifications.
