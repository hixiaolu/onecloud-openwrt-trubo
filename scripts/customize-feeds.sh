#!/bin/bash
#
# Feed customization script
# Configure clean feed sources, keep only necessary components
#

set -e

echo "=== Starting Feeds Customization ==="

# Show current directory
echo "Current working directory: $(pwd)"

# Check feeds.conf.default file
if [ -f "feeds.conf.default" ]; then
    echo "Current feeds configuration:"
    cat feeds.conf.default
else
    echo "Error: feeds.conf.default file not found"
    exit 1
fi

# Ensure only official sources and clean Argon theme are used
echo "Verifying feeds configuration purity..."

# Check for unnecessary third-party components
echo "Removing unnecessary third-party feed sources..."
# Ensure no proxy-related feed sources
sed -i '/passwall/d' feeds.conf.default 2>/dev/null || true
sed -i '/helloworld/d' feeds.conf.default 2>/dev/null || true
sed -i '/ssr-plus/d' feeds.conf.default 2>/dev/null || true
sed -i '/openclash/d' feeds.conf.default 2>/dev/null || true
sed -i '/small/d' feeds.conf.default 2>/dev/null || true
sed -i '/kenzo/d' feeds.conf.default 2>/dev/null || true
sed -i '/vssr/d' feeds.conf.default 2>/dev/null || true
sed -i '/bypass/d' feeds.conf.default 2>/dev/null || true

echo "Final feeds configuration:"
cat feeds.conf.default

echo "=== Feeds Customization Completed ==="