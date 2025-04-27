#!/bin/bash

# Configuration
CONFIG_FILE="server-health.conf"
LOG_FILE="health.log"
ALERT_FILE="alerts.log"
MAX_CPU=90
MAX_MEM=85
MAX_DISK=90
ADMIN_EMAIL="nishantyadav2207@gmail.com"
ALERT_THRESHOLD=1  # Change for immediate alert notification

ALERT_COUNT=0

# Load configuration
load_config() {
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
}

# Check CPU Usage
check_cpu() {
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
    printf -v cpu_usage "%.1f" "$cpu_usage"
    echo "CPU Usage: $cpu_usage%"  # Debug

    if (( $(echo "$cpu_usage > $MAX_CPU" | bc -l) )); then
        log_alert "CPU" "$cpu_usage" "$MAX_CPU"
    fi
}

# Check Memory Usage
check_memory() {
    mem_usage=$(free -m | awk '/Mem:/ {print ($3/$2)*100}')
    printf -v mem_usage "%.1f" "$mem_usage"
    echo "Memory Usage: $mem_usage%"  # Debug

    if (( $(echo "$mem_usage > $MAX_MEM" | bc -l) )); then
        log_alert "Memory" "$mem_usage" "$MAX_MEM"
    fi
}

# Check Disk Usage
check_disk() {
    disk_usage=$(df -P / | awk 'NR==2 {gsub("%", "", $5); print $5}')
    echo "Disk Usage: $disk_usage%"  # Debug

    if [ "$disk_usage" -gt "$MAX_DISK" ]; then
        log_alert "Disk" "$disk_usage" "$MAX_DISK"
    fi
}

# Log and trigger alert
log_alert() {
    local metric=$1
    local value=$2
    local max=$3
    local message="$metric usage high: ${value}% (Threshold: ${max}%)"

    echo "$(date) - WARNING: $message" >> "$ALERT_FILE"
    ((ALERT_COUNT++))

    if [ "$ALERT_COUNT" -ge "$ALERT_THRESHOLD" ]; then
        send_notification "$message"
        ALERT_COUNT=0  # Reset counter after sending the notification
    fi
}

# Send email/notification
send_notification() {
    local message=$1
    echo "$message" | mail -s "Server Alert" "$ADMIN_EMAIL"
}

# Generate health report
generate_report() {
    echo "----- Server Health Report -----" >> "$LOG_FILE"
    echo "Timestamp: $(date)" >> "$LOG_FILE"
    echo "CPU: ${cpu_usage}% (Max: ${MAX_CPU}%)" >> "$LOG_FILE"
    echo "Memory: ${mem_usage}% (Max: ${MAX_MEM}%)" >> "$LOG_FILE"
    echo "Disk: ${disk_usage}% (Max: ${MAX_DISK}%)" >> "$LOG_FILE"
    echo "--------------------------------" >> "$LOG_FILE"
}

# Main execution
main() {
    load_config
    check_cpu
    check_memory
    check_disk
    generate_report
}

main
