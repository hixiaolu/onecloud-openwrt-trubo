#!/bin/bash
#
# 环境准备脚本
# 用于安装编译依赖和优化构建环境
#

set -e

echo "=== 开始环境准备 ==="

# 释放磁盘空间
echo "正在清理磁盘空间..."
sudo rm -rf /etc/apt/sources.list.d/* /usr/share/dotnet /usr/local/lib/android /opt/ghc /opt/hostedtoolcache/CodeQL
sudo docker image prune --all --force
sudo apt-get -qq purge azure-cli ghc* zulu* hhvm llvm* firefox google* dotnet* powershell openjdk* adoptopenjdk* mysql* php* mongodb* moby* snapd* || true
sudo apt-get -qq autoremove --purge
sudo apt-get -qq autoclean

# 更新软件源
echo "正在更新软件源..."
sudo sed -i 's/azure\.//' /etc/apt/sources.list
sudo apt-get -qq update

# 安装编译依赖
echo "正在安装编译依赖..."
sudo apt-get -qq install -y \
  ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential bzip2 \
  ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib \
  g++-multilib git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libfuse-dev \
  libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev \
  libncursesw5-dev libpython3-dev libreadline-dev libssl-dev libtool lrzsz mkisofs \
  msmtp ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 python3-pyelftools \
  python3-setuptools qemu-utils rsync scons squashfs-tools subversion swig texinfo \
  uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev img2simg

# 设置ccache
echo "配置ccache..."
export PATH="/usr/lib/ccache:$PATH"
ccache -M 50G
ccache -z

echo "=== 环境准备完成 ==="
echo "磁盘使用情况:"
df -h
