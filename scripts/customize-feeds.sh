#!/bin/bash
#
# Feed定制脚本
# 用于配置纯净Feed源，仅保留必要组件
#

set -e

echo "=== 开始Feeds定制 ==="

# 显示当前目录
echo "当前工作目录: $(pwd)"

# 检查feeds.conf.default文件
if [ -f "feeds.conf.default" ]; then
    echo "当前feeds配置:"
    cat feeds.conf.default
else
    echo "错误: 未找到feeds.conf.default文件"
    exit 1
fi

# 确保只使用官方源和纯净的Argon主题
echo "验证feeds配置的纯净性..."

# 检查是否包含不必要的第三方组件
echo "移除不必要的第三方feed源..."
# 确保没有代理相关的feed源
sed -i '/passwall/d' feeds.conf.default 2>/dev/null || true
sed -i '/helloworld/d' feeds.conf.default 2>/dev/null || true
sed -i '/ssr-plus/d' feeds.conf.default 2>/dev/null || true
sed -i '/openclash/d' feeds.conf.default 2>/dev/null || true
sed -i '/small/d' feeds.conf.default 2>/dev/null || true
sed -i '/kenzo/d' feeds.conf.default 2>/dev/null || true
sed -i '/vssr/d' feeds.conf.default 2>/dev/null || true
sed -i '/bypass/d' feeds.conf.default 2>/dev/null || true

echo "最终feeds配置:"
cat feeds.conf.default

echo "=== Feeds定制完成 ==="
