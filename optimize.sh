#!/bin/bash

# Server Optimization Script
# This script updates the system, enables performance mode on all cores,
# and applies network performance tweaks

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

# Function to update and upgrade system
update_system() {
    print_status "Starting system update and upgrade..."
    
    # Update package lists
    print_status "Updating package lists..."
    apt update -y
    
    # Install essential tools
    print_status "Installing essential tools (git, curl, wget)..."
    apt install -y git curl wget
    
    # Upgrade all packages
    print_status "Upgrading all packages..."
    apt upgrade -y
    
    # Install security updates
    print_status "Installing security updates..."
    apt dist-upgrade -y
    
    # Clean up old packages
    print_status "Cleaning up old packages..."
    apt autoremove -y
    apt autoclean
    
    print_success "System update completed"
}

# Function to enable performance mode on all CPU cores
enable_performance_mode() {
    print_status "Enabling performance mode on all CPU cores..."
    
    # Check if cpufrequtils is installed
    if ! command -v cpufreq-set &> /dev/null; then
        print_status "Installing cpufrequtils..."
        apt install -y cpufrequtils
    fi
    
    # Get number of CPU cores
    CPU_CORES=$(nproc)
    print_status "Found $CPU_CORES CPU cores"
    
    # Check if CPU frequency scaling is available
    if [ ! -d "/sys/devices/system/cpu/cpu0/cpufreq" ]; then
        print_warning "CPU frequency scaling not available (common in cloud/VPS environments)"
        print_status "Skipping CPU performance mode setting"
        return 0
    fi
    
    # Check available governors
    if [ ! -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors" ]; then
        print_warning "CPU governors not available"
        print_status "Skipping CPU performance mode setting"
        return 0
    fi
    
    # Enable performance mode on all cores
    for ((i=0; i<CPU_CORES; i++)); do
        print_status "Setting performance mode for CPU core $i"
        if cpufreq-set -c $i -g performance 2>/dev/null; then
            print_success "Performance mode set for CPU core $i"
        else
            print_warning "Could not set performance mode for CPU core $i"
        fi
    done
    
    # Verify the settings
    print_status "Verifying CPU frequency settings..."
    if command -v cpufreq-info &> /dev/null; then
        cpufreq-info | grep -E "current CPU frequency|governor" | head -$(($(nproc) * 2))
    fi
    
    print_success "CPU performance mode configuration completed"
}

# Function to apply network performance tweaks
apply_network_tweaks() {
    print_status "Applying network performance tweaks..."
    
    # Create sysctl configuration file
    cat > /etc/sysctl.d/99-network-performance.conf << 'EOF'
# Network Performance Optimizations

# Increase TCP buffer sizes
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144

# TCP window scaling
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# TCP congestion control (BBR for better performance)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# Increase connection tracking
net.netfilter.nf_conntrack_max = 131072
net.netfilter.nf_conntrack_tcp_timeout_established = 86400

# TCP keepalive settings
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 75
net.ipv4.tcp_keepalive_probes = 9

# TCP fast open
net.ipv4.tcp_fastopen = 3

# Increase file descriptor limits
fs.file-max = 2097152

# Increase max user processes
kernel.pid_max = 65536

# Disable IPv6 autoconfig (if not needed)
# net.ipv6.conf.all.autoconf = 0
# net.ipv6.conf.default.autoconf = 0

# Optimize for low latency
net.core.netdev_max_backlog = 5000
net.core.netdev_budget = 600
net.core.netdev_budget_usecs = 8000

# TCP timestamp optimization
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1

# Increase local port range
net.ipv4.ip_local_port_range = 1024 65535

# TCP memory optimization
net.ipv4.tcp_mem = 786432 1048576 1572864

# Disable TCP slow start after idle
net.ipv4.tcp_slow_start_after_idle = 0

# Enable TCP window scaling
net.ipv4.tcp_window_scaling = 1

# Increase TCP max syn backlog
net.ipv4.tcp_max_syn_backlog = 8192

# Enable TCP selective acknowledgments
net.ipv4.tcp_sack = 1

# Optimize for high throughput
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
EOF

    # Apply sysctl settings
    sysctl -p /etc/sysctl.d/99-network-performance.conf
    
    print_success "Network performance tweaks applied"
}

# Function to optimize disk I/O
optimize_disk_io() {
    print_status "Applying disk I/O optimizations..."
    
    # Create udev rules for SSD optimization
    cat > /etc/udev/rules.d/60-ssd-scheduler.rules << 'EOF'
# Set scheduler for SSDs to none (for NVMe) or deadline (for SATA SSDs)
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
EOF

    # Reload udev rules
    udevadm control --reload-rules
    udevadm trigger
    
    print_success "Disk I/O optimizations applied"
}

# Function to set up performance monitoring
setup_monitoring() {
    print_status "Setting up basic performance monitoring..."
    
    # Install htop for better process monitoring
    if ! command -v htop &> /dev/null; then
        apt install -y htop
    fi
    
    # Install iotop for I/O monitoring
    if ! command -v iotop &> /dev/null; then
        apt install -y iotop
    fi
    
    # Install nethogs for network monitoring
    if ! command -v nethogs &> /dev/null; then
        apt install -y nethogs
    fi
    
    print_success "Performance monitoring tools installed"
}

# Function to create a systemd service for persistent CPU performance mode
create_performance_service() {
    print_status "Creating persistent CPU performance mode service..."
    
    # Check if CPU frequency scaling is available
    if [ ! -d "/sys/devices/system/cpu/cpu0/cpufreq" ]; then
        print_warning "CPU frequency scaling not available - skipping service creation"
        return 0
    fi
    
    cat > /etc/systemd/system/cpu-performance.service << 'EOF'
[Unit]
Description=Set CPU to performance mode
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'if [ -d "/sys/devices/system/cpu/cpu0/cpufreq" ]; then for i in $(seq 0 $(($(nproc)-1))); do echo performance > /sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor 2>/dev/null || true; done; fi'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

    # Enable and start the service
    systemctl daemon-reload
    systemctl enable cpu-performance.service
    systemctl start cpu-performance.service
    
    print_success "CPU performance service created and enabled"
}

# Function to display system information
display_system_info() {
    print_status "Displaying system information..."
    
    echo "=== System Information ==="
    echo "OS: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    echo "CPU Cores: $(nproc)"
    echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
    echo "Disk Usage: $(df -h / | tail -1 | awk '{print $5}')"
    
    echo -e "\n=== CPU Frequency Settings ==="
    if command -v cpufreq-info &> /dev/null; then
        cpufreq-info | grep -E "current CPU frequency|governor" | head -$(($(nproc) * 2))
    fi
    
    echo -e "\n=== Network Interfaces ==="
    ip addr show | grep -E "^[0-9]+:|inet " | head -10
    
    echo -e "\n=== Current Network Settings ==="
    sysctl -a | grep -E "net\.core\.(rmem|wmem)_max|net\.ipv4\.tcp_congestion_control" | head -5
}

# Main execution
main() {
    echo "=========================================="
    echo "    Server Optimization Script"
    echo "=========================================="
    
    # Check if running as root
    check_root
    
    # Update timestamp
    print_status "Starting optimization at $(date)"
    
    # Perform system updates
    update_system
    
    # Enable performance mode
    enable_performance_mode
    
    # Apply network tweaks
    apply_network_tweaks
    
    # Optimize disk I/O
    optimize_disk_io
    
    # Set up monitoring tools
    setup_monitoring
    
    # Create persistent performance service
    create_performance_service
    
    # Display system information
    display_system_info
    
    print_success "Server optimization completed successfully!"
    print_warning "A system reboot is recommended to apply all changes"
    print_status "You can reboot with: sudo reboot"
    
    echo "=========================================="
}

# Run main function
main "$@"
