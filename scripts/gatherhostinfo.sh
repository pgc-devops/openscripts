#!/bin/bash

defaults() {

    sftpurl=""
    flg_publish=0
}

defaults

# Output file based on hostname
HOSTNAME=$(hostname)
OUTPUT_FILE="${HOSTNAME}-info.txt"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "Collecting system information for $HOSTNAME..."
echo "Output will be saved to $OUTPUT_FILE"

# Header
{
    echo "========================================"
    echo "System Information Report"
    echo "Hostname: $HOSTNAME"
    echo "Date: $DATE"
    echo "========================================"
} > "$OUTPUT_FILE"

# function to upload results
publish_results() {

    if [ -f "${OUTPUT_FILE}" ]; then
        scp "${OUTPUT_FILE}" "${sftpurl}"
    fi
}

# Function to check if a command exists
check_cmd() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run command with sudo if not root
run_cmd() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        if check_cmd sudo; then
            sudo "$@"
        else
            echo "Cannot run $* (sudo not available)" >> "$OUTPUT_FILE"
        fi
    fi
}

# OS Name and Version
echo -e "\n### OS Information ###" >> "$OUTPUT_FILE"
if [ -f /etc/lsb-release ]; then
    cat /etc/lsb-release >> "$OUTPUT_FILE"
elif [ -f /etc/redhat-release ]; then
    cat /etc/redhat-release >> "$OUTPUT_FILE"
else
    echo "OS release file not found" >> "$OUTPUT_FILE"
fi

# Kernel info
echo -e "\n### Kernel Info ###" >> "$OUTPUT_FILE"
uname -a >> "$OUTPUT_FILE"

# File systems
echo -e "\n### File Systems (df -h) ###" >> "$OUTPUT_FILE"
if check_cmd df; then
    df -h >> "$OUTPUT_FILE"
else
    echo "df command not available" >> "$OUTPUT_FILE"
fi
# Hardware info (dmidecode)
echo -e "\n### Hardware Info (dmidecode) ###" >> "$OUTPUT_FILE"
if check_cmd dmidecode; then
    run_cmd dmidecode >> "$OUTPUT_FILE" 2>/dev/null
else
    echo "dmidecode not installed" >> "$OUTPUT_FILE"
fi

# Block devices (lsblk)
echo -e "\n### Block Devices (lsblk) ###" >> "$OUTPUT_FILE"
if check_cmd lsblk; then
    lsblk >> "$OUTPUT_FILE"
else
    echo "lsblk not installed" >> "$OUTPUT_FILE"
fi

# LVM info
echo -e "\n### LVM Info ###" >> "$OUTPUT_FILE"
if check_cmd pvs && check_cmd lvs; then
    echo -e "\nPhysical Volumes:" >> "$OUTPUT_FILE"
    run_cmd pvs >> "$OUTPUT_FILE" 2>/dev/null
    echo -e "\nLogical Volumes:" >> "$OUTPUT_FILE"
    run_cmd lvs >> "$OUTPUT_FILE" 2>/dev/null
else
    echo "LVM utilities not installed" >> "$OUTPUT_FILE"
fi

# Network info
echo -e "\n### Network Info ###" >> "$OUTPUT_FILE"
if check_cmd ip; then
    ip a >> "$OUTPUT_FILE"
elif check_cmd ifconfig; then
    ifconfig >> "$OUTPUT_FILE"
else
    echo "No network command available" >> "$OUTPUT_FILE"
fi

echo -e "\nCollection complete. File saved as $OUTPUT_FILE"

if [ $flg_publish -eq 1 ]; then

    publish_results

fi

