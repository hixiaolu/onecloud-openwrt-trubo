#!/bin/bash
#
# 环境准备脚本 (绝对最小版)
# 只安装OpenWrt编译的核心必需包
#

set -e

echo "=== 开始最小化环境准备 ==="

# 显示初始状态
echo "初始磁盘状态:"
df -h

# 不进行任何清理，避免耗时
echo "跳过清理操作，直接安装依赖..."

# 更新软件源（静默）
echo "更新软件源..."
sudo apt-get -qq update

# 只安装绝对必需的包
echo "安装绝对必需的依赖..."
sudo apt-get -qq install -y \
  build-essential git wget \
  python3 gawk gettext \
  libncurses5-dev zlib1g-dev

# 最小ccache设置
echo "设置ccache..."
ccache -M 2G 2>/dev/null || echo "ccache设置可选，跳过"
ccache -z 2>/dev/null || echo "ccache清零可选，跳过"

echo "=== 最小化环境准备完成 ==="
echo "最终磁盘状态:"
df -h
