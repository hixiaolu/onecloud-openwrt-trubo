#!/bin/bash
#
# Environment setup script (absolute minimal version)
# Install only core required packages for OpenWrt compilation
#

set -e

echo "=== Starting Minimal Environment Setup ==="

# Show initial status
echo "Initial disk status:"
df -h

# Check network connectivity
echo "Checking network connectivity..."
if ! ping -c 3 8.8.8.8 >/dev/null 2>&1; then
    echo "Network connection failed"
    exit 1
fi

# Skip cleanup operations to save time
echo "Skipping cleanup operations, installing dependencies directly..."

# Update software sources (quiet)
echo "Updating software sources..."
sudo apt-get -qq update

# Install only absolutely necessary packages with better error handling
echo "Installing absolutely necessary dependencies..."
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if sudo apt-get -qq install -y \
        build-essential clang flex bison g++ gawk \
        gcc-multilib g++-multilib \
        git wget curl time file unzip rsync swig \
        libncurses5-dev libssl-dev zlib1g-dev \
        python3 python3-dev python3-distutils python3-setuptools \
        gettext xsltproc; then
        echo "Dependencies installed successfully"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "Installation failed, retrying... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 5
        sudo apt-get -qq update
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "Failed to install dependencies after $MAX_RETRIES attempts"
    # Output system information for diagnosis
    df -h
    free -h
    exit 1
fi

# Verify essential tools are available
echo "Verifying essential tools..."
for tool in git wget curl; do
    if ! command -v $tool >/dev/null 2>&1; then
        echo "Essential tool $tool not found"
        exit 1
    fi
done

# Minimal ccache setup
echo "Setting up ccache..."
ccache -M 4G 2>/dev/null || echo "ccache setup optional, skipping"
ccache -z 2>/dev/null || echo "ccache zeroing optional, skipping"

echo "=== Minimal Environment Setup Completed ==="
echo "Final disk status:"
df -h