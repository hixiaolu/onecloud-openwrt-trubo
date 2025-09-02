
#!/bin/bash
#
# 镜像生成脚本
# 用于生成线刷和卡刷双格式固件
#

set -e

echo "=== 开始生成镜像文件 ==="

# 定义变量
SCRIPT_DIR=$(dirname "$0")
WORK_DIR=$(pwd)
TOOLS_DIR="$WORK_DIR/tools"
BUILD_DATE=$(date +"%Y%m%d%H%M")

# 检查必需工具
if [ ! -f "$TOOLS_DIR/AmlImg" ]; then
    echo "错误: 找不到 AmlImg 工具"
    exit 1
fi

if [ ! -f "$TOOLS_DIR/uboot.img" ]; then
    echo "错误: 找不到 uboot.img 文件"
    exit 1
fi

# 查找编译生成的镜像文件
IMG_PATH=$(find openwrt/bin/targets -name "*.img.gz" -type f | head -n 1)
if [ -z "$IMG_PATH" ]; then
    echo "错误: 找不到编译生成的.img.gz文件"
    find openwrt/bin/targets -name "*.img*" -type f
    exit 1
fi

echo "找到镜像文件: $IMG_PATH"

# 解压镜像文件
echo "正在解压镜像文件..."
gzip -dk "$IMG_PATH"
IMG_FILE="${IMG_PATH%.gz}"

# 检查解压后的文件
if [ ! -f "$IMG_FILE" ]; then
    echo "错误: 解压后的镜像文件不存在"
    exit 1
fi

echo "解压后的镜像文件: $IMG_FILE"
echo "文件大小: $(ls -lh "$IMG_FILE" | awk '{print $5}')"

# 准备工作目录
BURN_DIR="$WORK_DIR/burn_temp"
rm -rf "$BURN_DIR"
mkdir -p "$BURN_DIR"

echo "=== 生成线刷固件 ==="

# 解包uboot.img
echo "解包uboot.img..."
"$TOOLS_DIR/AmlImg" unpack "$TOOLS_DIR/uboot.img" "$BURN_DIR/"

# 设置回环设备
echo "设置回环设备..."
LOOP_DEV=$(sudo losetup --find --show --partscan "$IMG_FILE")
if [ -z "$LOOP_DEV" ]; then
    echo "错误: 无法设置回环设备"
    exit 1
fi

echo "使用回环设备: $LOOP_DEV"

# 清理函数
cleanup() {
    echo "正在清理资源..."
    sudo umount "$WORK_DIR/boot_mnt" 2>/dev/null || true
    sudo umount "$WORK_DIR/root_mnt" 2>/dev/null || true
    sudo losetup -d "$LOOP_DEV" 2>/dev/null || true
    rm -rf "$WORK_DIR/boot_mnt" "$WORK_DIR/root_mnt"
    rm -f "$WORK_DIR/boot_temp.img"
}

# 设置退出时清理
trap cleanup EXIT

# 等待分区设备出现
echo "等待分区设备出现..."
sleep 2

# 检查分区
if [ ! -e "${LOOP_DEV}p1" ] || [ ! -e "${LOOP_DEV}p2" ]; then
    echo "错误: 分区设备不存在"
    sudo partprobe "$LOOP_DEV" || true
    sleep 2
    if [ ! -e "${LOOP_DEV}p1" ] || [ ! -e "${LOOP_DEV}p2" ]; then
        echo "错误: 仍然无法访问分区"
        sudo fdisk -l "$LOOP_DEV"
        exit 1
    fi
fi

# 创建临时boot镜像
echo "创建临时boot镜像..."
dd if=/dev/zero of="$WORK_DIR/boot_temp.img" bs=1M count=600 status=progress
mkfs.ext4 -F "$WORK_DIR/boot_temp.img"

# 创建挂载点
mkdir -p "$WORK_DIR/boot_mnt" "$WORK_DIR/root_mnt"

# 挂载文件系统
echo "挂载文件系统..."
sudo mount "$WORK_DIR/boot_temp.img" "$WORK_DIR/boot_mnt"
sudo mount "${LOOP_DEV}p2" "$WORK_DIR/root_mnt"

# 复制文件
echo "复制rootfs内容到boot镜像..."
sudo cp -rp "$WORK_DIR/root_mnt"/* "$WORK_DIR/boot_mnt/"
sudo sync

# 卸载文件系统
sudo umount "$WORK_DIR/boot_mnt"
sudo umount "$WORK_DIR/root_mnt"

# 生成稀疏镜像
echo "生成稀疏镜像..."
sudo img2simg "${LOOP_DEV}p1" "$BURN_DIR/boot.simg"
sudo img2simg "$WORK_DIR/boot_temp.img" "$BURN_DIR/rootfs.simg"

# 生成命令文件
cat > "$BURN_DIR/commands.txt" << EOF
PARTITION:boot:sparse:boot.simg
PARTITION:rootfs:sparse:rootfs.simg
EOF

# 打包burn镜像
BURN_IMG_NAME="openwrt-onecloud-${BUILD_DATE}.burn.img"
echo "正在生成线刷镜像: $BURN_IMG_NAME"
"$TOOLS_DIR/AmlImg" pack "$BURN_IMG_NAME" "$BURN_DIR/"

# 移动到固件目录
FIRMWARE_DIR=$(dirname "$IMG_FILE")
mv "$BURN_IMG_NAME" "$FIRMWARE_DIR/"

echo "=== 生成卡刷固件 ==="

# 重命名卡刷镜像
CARD_IMG_NAME="openwrt-onecloud-${BUILD_DATE}.img"
mv "$IMG_FILE" "$FIRMWARE_DIR/$CARD_IMG_NAME"

echo "=== 压缩固件文件 ==="

# 进入固件目录
cd "$FIRMWARE_DIR"

# 生成校验文件并压缩
echo "生成校验文件..."
sha256sum "$BURN_IMG_NAME" > "${BURN_IMG_NAME}.sha256"
sha256sum "$CARD_IMG_NAME" > "${CARD_IMG_NAME}.sha256"

echo "压缩固件文件..."
xz -9 --threads=0 "$BURN_IMG_NAME"
xz -9 --threads=0 "$CARD_IMG_NAME"

# 清理临时文件
rm -rf "$BURN_DIR"
rm -f "$WORK_DIR/boot_temp.img"

echo "=== 镜像生成完成 ==="
echo "生成的文件:"
ls -la *.xz *.sha256
```