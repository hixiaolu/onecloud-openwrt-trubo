#!/bin/bash
#
# 固件定制脚本
# 用于配置系统设置和清理操作
#

set -e

echo "=== 开始固件定制 ==="

# 修改默认IP地址
echo "修改默认IP为192.168.8.88..."
sed -i 's/192.168.1.1/192.168.8.88/g' package/base-files/files/bin/config_generate

# 修改默认主机名
echo "设置主机名为OneCloud-Pure..."
sed -i 's/OpenWrt/OneCloud-Pure/g' package/base-files/files/bin/config_generate

# 修改默认shell为bash
echo "修改默认shell为bash..."
sed -i 's/\/bin\/ash/\/bin\/bash/g' package/base-files/files/etc/passwd

# 设置默认密码为'password'
echo "设置默认密码..."
sed -i 's/root::0:0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:0:0:99999:7:::/g' package/base-files/files/etc/shadow

# 配置Nginx替代uhttpd
echo "配置Nginx作为Web服务器..."
# 在feeds更新后配置
if [ -d "feeds/packages/net/nginx" ]; then
    # 启用nginx模块
    echo "CONFIG_PACKAGE_nginx-all-module=y" >> .config
    echo "CONFIG_PACKAGE_nginx-mod-luci=y" >> .config
    echo "CONFIG_PACKAGE_nginx-util=y" >> .config
    echo "CONFIG_PACKAGE_luci-nginx=y" >> .config
    echo "# CONFIG_PACKAGE_uhttpd is not set" >> .config
    echo "# CONFIG_PACKAGE_uhttpd-mod-ubus is not set" >> .config
    echo "# CONFIG_PACKAGE_uhttpd-mod-lua is not set" >> .config
fi

# 设置Argon为默认主题
echo "设置Argon为默认主题..."
if [ -d "feeds/argon" ]; then
    # 在LuCI配置中设置默认主题
    sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true
    # 直接在配置中指定Argon主题
    echo "CONFIG_PACKAGE_luci-theme-argon=y" >> .config
    echo "# CONFIG_PACKAGE_luci-theme-bootstrap is not set" >> .config
    echo "# CONFIG_PACKAGE_luci-theme-material is not set" >> .config
    echo "# CONFIG_PACKAGE_luci-theme-openwrt-2020 is not set" >> .config
fi

# 移除不必要的软件包
echo "移除不必要的软件包..."
rm -rf feeds/packages/net/alist 2>/dev/null || true
rm -rf feeds/packages/net/passwall* 2>/dev/null || true
rm -rf feeds/packages/net/ssr-plus 2>/dev/null || true
rm -rf package/alist 2>/dev/null || true

# 移除其他不必要组件
find . -name "*passwall*" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*ssr-plus*" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*openclash*" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*helloworld*" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*vssr*" -type d -exec rm -rf {} + 2>/dev/null || true
find . -name "*bypass*" -type d -exec rm -rf {} + 2>/dev/null || true

# 修改时区设置
echo "设置默认时区为亚洲/上海..."
if [ -f "package/base-files/files/bin/config_generate" ]; then
    sed -i "/system.@system\[-1\].hostname/a\\\tuci set system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate
    sed -i "/system.@system\[-1\].hostname/a\\\tuci set system.@system[-1].timezone='CST-8'" package/base-files/files/bin/config_generate
fi

# 启用BBR加速
echo "启用BBR TCP拥塞控制..."
echo 'net.core.default_qdisc=fq' >> package/base-files/files/etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' >> package/base-files/files/etc/sysctl.conf

# 优化内核参数
echo "优化系统内核参数..."
cat >> package/base-files/files/etc/sysctl.conf << EOF
# 网络优化
net.netfilter.nf_conntrack_max = 65536
net.netfilter.nf_conntrack_tcp_timeout_established = 1200
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 65536 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.core.netdev_max_backlog = 5000

# 文件系统优化
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF

echo "=== 固件定制完成 ==="