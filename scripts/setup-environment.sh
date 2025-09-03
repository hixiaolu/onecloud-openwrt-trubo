#!/bin/bash
#
# 环境准备脚本 (优化版)
# 用于安装编译依赖和优化构建环境
#

set -e

echo "=== 开始环境准备 ==="

# 显示初始磁盘状态
echo "初始磁盘状态:"
df -h

# 释放磁盘空间 (优化版)
echo "正在清理磁盘空间..."
sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /opt/hostedtoolcache/CodeQL 2>/dev/null || true
sudo docker image prune --all --force 2>/dev/null || true

# 快速清理不必要的软件包
echo "快速清理不必要软件..."
sudo apt-get -qq purge -y azure-cli ghc* zulu* llvm* firefox google* dotnet* powershell openjdk* mysql* php* snapd* 2>/dev/null || true
sudo apt-get -qq autoremove --purge -y 2>/dev/null || true
sudo apt-get -qq autoclean 2>/dev/null || true

# 更新软件源 (使用更快的镜像源)
echo "正在更新软件源..."
sudo sed -i 's/azure\.//' /etc/apt/sources.list
sudo apt-get -qq update

# 分批安装依赖，避免超时
echo "正在安装编译依赖..."
echo "步骤1/3: 安装基础构建工具..."
sudo apt-get -qq install -y \
  build-essential ccache git curl wget unzip \
  python3 python3-setuptools python3-dev \
  autoconf automake libtool pkg-config cmake ninja-build

echo "步骤2/3: 安装OpenWrt编译依赖..."
sudo apt-get -qq install -y \
  gawk gettext libncurses5-dev libncursesw5-dev \
  zlib1g-dev libssl-dev bison flex rsync \
  subversion device-tree-compiler

echo "步骤3/3: 安装附加工具..."
sudo apt-get -qq install -y \
  img2simg squashfs-tools qemu-utils \
  upx-ucl p7zip-full xxd vim

# 设置ccache
echo "配置ccache..."
export PATH="/usr/lib/ccache:$PATH"
ccache -M 10G
ccache -z

# 显示清理后的磁盘状态
echo "=== 环境准备完成 ==="
echo "最终磁盘使用情况:"
df -h
echo "可用内存:"
free -h
