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

# Enhanced network connectivity check with multiple attempts
echo "Checking network connectivity..."
MAX_PING_ATTEMPTS=5
PING_ATTEMPT=0
while [ $PING_ATTEMPT -lt $MAX_PING_ATTEMPTS ]; do
    if ping -c 3 8.8.8.8 >/dev/null 2>&1; then
        echo "Network connectivity verified"
        break
    else
        PING_ATTEMPT=$((PING_ATTEMPT + 1))
        echo "Network check failed, attempt $PING_ATTEMPT/$MAX_PING_ATTEMPTS"
        if [ $PING_ATTEMPT -eq $MAX_PING_ATTEMPTS ]; then
            echo "Network connectivity failed after $MAX_PING_ATTEMPTS attempts"
            exit 1
        fi
        sleep 5
    fi
done

# Enhanced disk space check - Check if we have at least 20GB free space
echo "Checking disk space..."
AVAILABLE_SPACE_KB=$(df . | awk 'NR==2 {print $4}')
AVAILABLE_SPACE_GB=$((AVAILABLE_SPACE_KB / 1024 / 1024))
REQUIRED_SPACE_GB=20

if [ $AVAILABLE_SPACE_GB -lt $REQUIRED_SPACE_GB ]; then
    echo "⚠️  Insufficient disk space: ${AVAILABLE_SPACE_GB}GB available, at least ${REQUIRED_SPACE_GB}GB required"
    echo "Attempting to free up space..."
    # Try to clean up some space
    sudo apt-get clean || echo "Warning: Could not clean apt cache"
    sudo rm -rf /var/log/*.log 2>/dev/null || echo "Warning: Could not clean log files"
    # Recheck space after cleanup
    AVAILABLE_SPACE_KB=$(df . | awk 'NR==2 {print $4}')
    AVAILABLE_SPACE_GB=$((AVAILABLE_SPACE_KB / 1024 / 1024))
    if [ $AVAILABLE_SPACE_GB -lt $REQUIRED_SPACE_GB ]; then
        echo "❌ Still insufficient disk space after cleanup: ${AVAILABLE_SPACE_GB}GB available"
        exit 1
    else
        echo "✅ Disk space after cleanup: ${AVAILABLE_SPACE_GB}GB"
    fi
else
    echo "✅ Sufficient disk space: ${AVAILABLE_SPACE_GB}GB available"
fi

# Skip cleanup operations to save time
echo "Skipping cleanup operations, installing dependencies directly..."

# Update software sources with retry mechanism
echo "Updating software sources..."
MAX_UPDATE_ATTEMPTS=3
UPDATE_ATTEMPT=0
while [ $UPDATE_ATTEMPT -lt $MAX_UPDATE_ATTEMPTS ]; do
    if sudo apt-get -qq update; then
        echo "Software sources updated successfully"
        break
    else
        UPDATE_ATTEMPT=$((UPDATE_ATTEMPT + 1))
        echo "Software sources update failed, attempt $UPDATE_ATTEMPT/$MAX_UPDATE_ATTEMPTS"
        if [ $UPDATE_ATTEMPT -eq $MAX_UPDATE_ATTEMPTS ]; then
            echo "Software sources update failed after $MAX_UPDATE_ATTEMPTS attempts"
            # Output system information for diagnosis
            df -h
            free -h
            exit 1
        fi
        sleep 10
    fi
done

# Install only absolutely necessary packages with better error handling and retry mechanism
echo "Installing absolutely necessary dependencies..."
MAX_INSTALL_ATTEMPTS=3
INSTALL_ATTEMPT=0

while [ $INSTALL_ATTEMPT -lt $MAX_INSTALL_ATTEMPTS ]; do
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
        INSTALL_ATTEMPT=$((INSTALL_ATTEMPT + 1))
        echo "Installation failed, retrying... ($INSTALL_ATTEMPT/$MAX_INSTALL_ATTEMPTS)"
        if [ $INSTALL_ATTEMPT -eq $MAX_INSTALL_ATTEMPTS ]; then
            echo "Failed to install dependencies after $MAX_INSTALL_ATTEMPTS attempts"
            # Output system information for diagnosis
            df -h
            free -h
            # List what packages are available
            echo "Available packages:"
            apt-cache search build-essential || echo "Cannot search packages"
            exit 1
        fi
        sleep 10
        sudo apt-get -qq update
    fi
done

# Verify essential tools are available
echo "Verifying essential tools..."
for tool in git wget curl; do
    if ! command -v $tool >/dev/null 2>&1; then
        echo "Essential tool $tool not found"
        # Try to install the missing tool
        if sudo apt-get -qq install -y $tool; then
            echo "Successfully installed $tool"
        else
            echo "Failed to install $tool"
            exit 1
        fi
    else
        echo "✅ $tool is available"
    fi
done

# Enhanced ccache setup with error handling
echo "Setting up ccache..."
if command -v ccache >/dev/null 2>&1; then
    ccache -M 4G 2>/dev/null || echo "ccache setup optional, skipping"
    ccache -z 2>/dev/null || echo "ccache zeroing optional, skipping"
else
    echo "ccache not available, installing..."
    if sudo apt-get -qq install -y ccache; then
        ccache -M 4G 2>/dev/null || echo "ccache setup optional, skipping"
        ccache -z 2>/dev/null || echo "ccache zeroing optional, skipping"
    else
        echo "Failed to install ccache, continuing without it"
    fi
fi

echo "=== Minimal Environment Setup Completed ==="
echo "Final disk status:"
df -h