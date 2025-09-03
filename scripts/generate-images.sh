#!/bin/bash
#
# Image generation script
# Generate both line flash and card flash firmware formats
#

set -e

echo "=== Starting Image Generation ==="

# Define variables
SCRIPT_DIR=$(dirname "$0")
WORK_DIR=$(pwd)
TOOLS_DIR="$WORK_DIR/tools"
BUILD_DATE=$(date +"%Y%m%d%H%M")

# Check required tools
if [ ! -f "$TOOLS_DIR/AmlImg" ]; then
    echo "Error: AmlImg tool not found"
    exit 1
fi

if [ ! -f "$TOOLS_DIR/uboot.img" ]; then
    echo "Error: uboot.img file not found"
    exit 1
fi

# Find compiled image file
IMG_PATH=$(find openwrt/bin/targets -name "*.img.gz" -type f | head -n 1)
if [ -z "$IMG_PATH" ]; then
    echo "Error: Compiled .img.gz file not found"
    find openwrt/bin/targets -name "*.img*" -type f
    exit 1
fi

echo "Found image file: $IMG_PATH"

# Unzip image file
echo "Unzipping image file..."
gzip -dk "$IMG_PATH"
IMG_FILE="${IMG_PATH%.gz}"

# Check unzipped file
if [ ! -f "$IMG_FILE" ]; then
    echo "Error: Unzipped image file does not exist"
    exit 1
fi

echo "Unzipped image file: $IMG_FILE"
echo "File size: $(ls -lh "$IMG_FILE" | awk '{print $5}')"

# Prepare working directory
BURN_DIR="$WORK_DIR/burn_temp"
rm -rf "$BURN_DIR"
mkdir -p "$BURN_DIR"

echo "=== Generating Line Flash Firmware ==="

# Unpack uboot.img
echo "Unpacking uboot.img..."
"$TOOLS_DIR/AmlImg" unpack "$TOOLS_DIR/uboot.img" "$BURN_DIR/"

# Set loop device with better error handling
echo "Setting loop device..."
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    LOOP_DEV=$(sudo losetup --find --show --partscan "$IMG_FILE" 2>/dev/null) || LOOP_DEV=""
    if [ -n "$LOOP_DEV" ] && [ -b "$LOOP_DEV" ]; then
        echo "Successfully set loop device: $LOOP_DEV"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "Failed to set loop device, retrying... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 2
        sudo losetup --reset 2>/dev/null || true
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ] || [ -z "$LOOP_DEV" ] || [ ! -b "$LOOP_DEV" ]; then
    echo "Error: Unable to set loop device after $MAX_RETRIES attempts"
    exit 1
fi

echo "Using loop device: $LOOP_DEV"

# Cleanup function
cleanup() {
    echo "Cleaning up resources..."
    sudo umount "$WORK_DIR/boot_mnt" 2>/dev/null || true
    sudo umount "$WORK_DIR/root_mnt" 2>/dev/null || true
    sudo losetup -d "$LOOP_DEV" 2>/dev/null || true
    rm -rf "$WORK_DIR/boot_mnt" "$WORK_DIR/root_mnt"
    rm -f "$WORK_DIR/boot_temp.img"
}

# Set cleanup on exit
trap cleanup EXIT

# Wait for partition devices to appear with better handling
echo "Waiting for partition devices to appear..."
sleep 3

# Check partitions with better error handling
PARTITION_CHECK_COUNT=0
MAX_PARTITION_CHECKS=5

while [ $PARTITION_CHECK_COUNT -lt $MAX_PARTITION_CHECKS ]; do
    if [ -e "${LOOP_DEV}p1" ] && [ -e "${LOOP_DEV}p2" ]; then
        echo "Partition devices found"
        break
    else
        PARTITION_CHECK_COUNT=$((PARTITION_CHECK_COUNT + 1))
        echo "Waiting for partitions to appear... ($PARTITION_CHECK_COUNT/$MAX_PARTITION_CHECKS)"
        sudo partprobe "$LOOP_DEV" 2>/dev/null || true
        sleep 2
    fi
done

if [ ! -e "${LOOP_DEV}p1" ] || [ ! -e "${LOOP_DEV}p2" ]; then
    echo "Error: Partition devices do not exist after $MAX_PARTITION_CHECKS attempts"
    sudo fdisk -l "$LOOP_DEV" 2>/dev/null || true
    exit 1
fi

# Create temporary boot image with better error handling
echo "Creating temporary boot image..."
if ! dd if=/dev/zero of="$WORK_DIR/boot_temp.img" bs=1M count=600 status=none 2>/dev/null; then
    echo "Error: Failed to create temporary boot image"
    exit 1
fi

if ! mkfs.ext4 -F "$WORK_DIR/boot_temp.img" >/dev/null 2>&1; then
    echo "Error: Failed to format temporary boot image"
    exit 1
fi

# Create mount points
mkdir -p "$WORK_DIR/boot_mnt" "$WORK_DIR/root_mnt"

# Mount filesystems with better error handling
echo "Mounting filesystems..."
if ! sudo mount "$WORK_DIR/boot_temp.img" "$WORK_DIR/boot_mnt" 2>/dev/null; then
    echo "Error: Failed to mount boot image"
    exit 1
fi

if ! sudo mount "${LOOP_DEV}p2" "$WORK_DIR/root_mnt" 2>/dev/null; then
    echo "Error: Failed to mount rootfs partition"
    exit 1
fi

# Copy files with better error handling
echo "Copying rootfs contents to boot image..."
if ! sudo cp -rp "$WORK_DIR/root_mnt"/* "$WORK_DIR/boot_mnt/" 2>/dev/null; then
    echo "Warning: Some files may not have been copied successfully"
fi

if ! sudo sync; then
    echo "Warning: Sync command failed"
fi

# Unmount filesystems
sudo umount "$WORK_DIR/boot_mnt"
sudo umount "$WORK_DIR/root_mnt"

# Generate sparse images with better error handling
echo "Generating sparse images..."
if ! sudo img2simg "${LOOP_DEV}p1" "$BURN_DIR/boot.simg" 2>/dev/null; then
    echo "Error: Failed to generate boot sparse image"
    exit 1
fi

if ! sudo img2simg "$WORK_DIR/boot_temp.img" "$BURN_DIR/rootfs.simg" 2>/dev/null; then
    echo "Error: Failed to generate rootfs sparse image"
    exit 1
fi

# Generate command file
cat > "$BURN_DIR/commands.txt" << EOF
PARTITION:boot:sparse:boot.simg
PARTITION:rootfs:sparse:rootfs.simg
EOF

# Pack burn image
BURN_IMG_NAME="openwrt-onecloud-${BUILD_DATE}.burn.img"
echo "Generating line flash image: $BURN_IMG_NAME"
if ! "$TOOLS_DIR/AmlImg" pack "$BURN_IMG_NAME" "$BURN_DIR/" 2>/dev/null; then
    echo "Error: Failed to pack burn image"
    exit 1
fi

# Move to firmware directory
FIRMWARE_DIR=$(dirname "$IMG_FILE")
mv "$BURN_IMG_NAME" "$FIRMWARE_DIR/"

echo "=== Generating Card Flash Firmware ==="

# Rename card flash image
CARD_IMG_NAME="openwrt-onecloud-${BUILD_DATE}.img"
mv "$IMG_FILE" "$FIRMWARE_DIR/$CARD_IMG_NAME"

echo "=== Compressing Firmware Files ==="

# Enter firmware directory
cd "$FIRMWARE_DIR"

# Generate checksum files and compress
echo "Generating checksum files..."
sha256sum "$BURN_IMG_NAME" > "${BURN_IMG_NAME}.sha256"
sha256sum "$CARD_IMG_NAME" > "${CARD_IMG_NAME}.sha256"

echo "Compressing firmware files..."
if ! xz -9 --threads=0 "$BURN_IMG_NAME" 2>/dev/null; then
    echo "Warning: Failed to compress burn image, trying single thread"
    if ! xz -9 "$BURN_IMG_NAME" 2>/dev/null; then
        echo "Error: Failed to compress burn image"
        exit 1
    fi
fi

if ! xz -9 --threads=0 "$CARD_IMG_NAME" 2>/dev/null; then
    echo "Warning: Failed to compress card image, trying single thread"
    if ! xz -9 "$CARD_IMG_NAME" 2>/dev/null; then
        echo "Error: Failed to compress card image"
        exit 1
    fi
fi

# Clean up temporary files
rm -rf "$BURN_DIR"
rm -f "$WORK_DIR/boot_temp.img"

echo "=== Image Generation Completed ==="
echo "Generated files:"
ls -la *.xz *.sha256 2>/dev/null || echo "No files found"