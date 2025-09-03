#!/bin/bash
#
# Firmware customization script
# Configure system settings and cleanup operations
#

set -e

echo "=== Starting Firmware Customization ==="

# Modify default IP address
echo "Changing default IP to 192.168.8.88..."
sed -i 's/192.168.1.1/192.168.8.88/g' package/base-files/files/bin/config_generate

# Modify default hostname
echo "Setting hostname to OneCloud-Pure..."
sed -i 's/OpenWrt/OneCloud-Pure/g' package/base-files/files/bin/config_generate

# Modify default shell to bash
echo "Changing default shell to bash..."
sed -i 's/\/bin\/ash/\/bin\/bash/g' package/base-files/files/etc/passwd

# Set default password to 'password'
echo "Setting default password..."
sed -i 's/root::0:0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' package/base-files/files/etc/shadow

# Configure Nginx as alternative to uhttpd
echo "Configuring Nginx as web server..."
# Configure after feeds update
if [ -d "feeds/packages/net/nginx" ]; then
    # Enable nginx modules
    echo "CONFIG_PACKAGE_nginx-all-module=y" >> .config
    echo "CONFIG_PACKAGE_nginx-mod-luci=y" >> .config
    echo "CONFIG_PACKAGE_nginx-util=y" >> .config
    echo "CONFIG_PACKAGE_luci-nginx=y" >> .config
    echo "# CONFIG_PACKAGE_uhttpd is not set" >> .config
    echo "# CONFIG_PACKAGE_uhttpd-mod-ubus is not set" >> .config
    echo "# CONFIG_PACKAGE_uhttpd-mod-lua is not set" >> .config
fi

# Set Argon as default theme
echo "Setting Argon as default theme..."
if [ -d "feeds/argon" ]; then
    # Set default theme in LuCI configuration
    sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
    # Directly specify Argon theme in configuration
    echo "CONFIG_PACKAGE_luci-theme-argon=y" >> .config
    echo "# CONFIG_PACKAGE_luci-theme-bootstrap is not set" >> .config
    echo "# CONFIG_PACKAGE_luci-theme-material is not set" >> .config
    echo "# CONFIG_PACKAGE_luci-theme-openwrt-2020 is not set" >> .config
fi

# Remove unnecessary packages with better error handling
echo "Removing unnecessary packages..."
rm -rf feeds/packages/net/alist 2>/dev/null || true
rm -rf feeds/packages/net/passwall* 2>/dev/null || true
rm -rf feeds/packages/net/ssr-plus 2>/dev/null || true
rm -rf package/alist 2>/dev/null || true

# Remove other unnecessary components with better error handling
find . -name "*passwall*" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*ssr-plus*" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*openclash*" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*helloworld*" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*vssr*" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*bypass*" -type d -exec rm -rf {} + 2>/dev/null || true

# Modify timezone settings
echo "Setting default timezone to Asia/Shanghai..."
if [ -f "package/base-files/files/bin/config_generate" ]; then
    sed -i "/system.@system\[-1\].hostname/a\\\tuci set system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate
    sed -i "/system.@system\[-1\].hostname/a\\\tuci set system.@system[-1].timezone='CST-8'" package/base-files/files/bin/config_generate
fi

# Enable BBR acceleration
echo "Enabling BBR TCP congestion control..."
echo 'net.core.default_qdisc=fq' >> package/base-files/files/etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' >> package/base-files/files/etc/sysctl.conf

# Optimize kernel parameters
echo "Optimizing system kernel parameters..."
cat >> package/base-files/files/etc/sysctl.conf << EOF
# Network optimization
net.netfilter.nf_conntrack_max = 65536
net.netfilter.nf_conntrack_tcp_timeout_established = 1200
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 65536 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000

# File system optimization
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF

# Ensure proper permissions on config files
chmod 644 package/base-files/files/etc/sysctl.conf 2>/dev/null || true
chmod 644 package/base-files/files/etc/shadow 2>/dev/null || true
chmod 644 package/base-files/files/etc/passwd 2>/dev/null || true

echo "=== Firmware Customization Completed ==="