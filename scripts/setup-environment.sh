#!/bin/bash
#
# 环境准备脚本 (极简版)
# 仅安装最必要的依赖包
#

set -e

echo "=== 开始环境准备 ==="

# 显示初始状态
echo "初始磁盘状态:"
df -h

# 快速清理 (减少清理时间)
echo "快速清理不必要文件..."
sudo rm -rf /usr/share/dotnet /usr/local/lib/android 2>/dev/null || true
sudo apt-get -qq purge -y azure-cli dotnet* 2>/dev/null || true
sudo apt-get -qq autoremove -y 2>/dev/null || true

# 更新软件源
echo "更新软件源..."
sudo apt-get -qq update

# 安装最核心的依赖 (最小化安装)
echo "安装核心编译依赖..."
sudo apt-get -qq install -y \
  build-essential git curl wget \
  python3 python3-setuptools \
  gawk gettext libncurses5-dev \
  zlib1g-dev libssl-dev \
  img2simg squashfs-tools

# 设置较小的ccache
echo "配置ccache..."
ccache -M 5G 2>/dev/null || true
ccache -z 2>/dev/null || true

echo "=== 环境准备完成 ==="
echo "最终磁盘使用情况:"
df -h
