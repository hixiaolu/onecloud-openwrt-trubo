#!/bin/bash
#
# 环境准备脚本 (超级精简版)
# 仅安装最核心的依赖包
#

set -e

echo "=== 开始环境准备 ==="

# 显示初始状态
echo "初始磁盘状态:"
df -h

# 最小化清理 (几乎不清理，避免超时)
echo "快速清理..."
sudo rm -rf /usr/share/dotnet 2>/dev/null || true

# 更新软件源
echo "更新软件源..."
sudo apt-get -qq update

# 仅安装绝对必要的依赖 (超级精简)
echo "安装核心依赖..."
sudo apt-get -qq install -y \
  build-essential git wget \
  python3 gawk gettext \
  libncurses5-dev zlib1g-dev \
  squashfs-tools ccache

# 最小化配置ccache
echo "配置ccache..."
ccache -M 3G 2>/dev/null || true
ccache -z 2>/dev/null || true

echo "=== 环境准备完成 ==="
echo "最终磁盘使用情况:"
df -h
