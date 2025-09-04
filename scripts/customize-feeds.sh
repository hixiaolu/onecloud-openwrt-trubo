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

# Backup original feeds.conf.default
cp feeds.conf.default feeds.conf.default.backup

# Remove all existing entries to ensure clean state
> feeds.conf.default

# Add only official OpenWrt feeds
echo "# Official OpenWrt feeds" >> feeds.conf.default
echo "src-git packages https://git.openwrt.org/feed/packages.git" >> feeds.conf.default
echo "src-git luci https://git.openwrt.org/project/luci.git" >> feeds.conf.default
echo "src-git routing https://git.openwrt.org/feed/routing.git" >> feeds.conf.default
echo "src-git telephony https://git.openwrt.org/feed/telephony.git" >> feeds.conf.default
echo "" >> feeds.conf.default

# Add only the allowed Argon theme feed
echo "# Argon theme - the only allowed third-party component" >> feeds.conf.default
echo "src-git argon https://github.com/jerrykuku/luci-theme-argon.git" >> feeds.conf.default

echo "Final feeds configuration:"
cat feeds.conf.default

# Validate feeds configuration
echo "Validating feeds configuration..."
FEED_COUNT=$(grep -c "^src-git" feeds.conf.default)
if [ $FEED_COUNT -eq 5 ]; then
    echo "✅ Feeds configuration validated: $FEED_COUNT feeds found"
else
    echo "⚠️  Unexpected number of feeds: $FEED_COUNT (expected 5)"
fi

# Check for any forbidden feeds
FORBIDDEN_FEEDS=$(grep -i -E "(passwall|helloworld|ssr-plus|openclash|small|kenzo|vssr|bypass)" feeds.conf.default || true)
if [ -n "$FORBIDDEN_FEEDS" ]; then
    echo "❌ Forbidden feeds detected:"
    echo "$FORBIDDEN_FEEDS"
    exit 1
else
    echo "✅ No forbidden feeds detected"
fi

echo "=== Feeds Customization Completed ==="