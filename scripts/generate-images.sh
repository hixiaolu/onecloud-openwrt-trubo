
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

# Set loop device
echo "Setting loop device..."
LOOP_DEV=$(sudo losetup --find --show --partscan "$IMG_FILE")
if [ -z "$LOOP_DEV" ]; then
    echo "Error: Unable to set loop device"
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

# Wait for partition devices to appear
echo "Waiting for partition devices to appear..."
sleep 2

# Check partitions
if [ ! -e "${LOOP_DEV}p1" ] || [ ! -e "${LOOP_DEV}p2" ]; then
    echo "Error: Partition devices do not exist"
    sudo partprobe "$LOOP_DEV" || true
    sleep 2
    if [ ! -e "${LOOP_DEV}p1" ] || [ ! -e "${LOOP_DEV}p2" ]; then
        echo "Error: Still unable to access partitions"
        sudo fdisk -l "$LOOP_DEV"
        exit 1
    fi
fi

# Create temporary boot image
echo "Creating temporary boot image..."
dd if=/dev/zero of="$WORK_DIR/boot_temp.img" bs=1M count=600 status=progress
mkfs.ext4 -F "$WORK_DIR/boot_temp.img"

# Create mount points
mkdir -p "$WORK_DIR/boot_mnt" "$WORK_DIR/root_mnt"

# Mount filesystems
echo "Mounting filesystems..."
sudo mount "$WORK_DIR/boot_temp.img" "$WORK_DIR/boot_mnt"
sudo mount "${LOOP_DEV}p2" "$WORK_DIR/root_mnt"

# Copy files
echo "Copying rootfs contents to boot image..."
sudo cp -rp "$WORK_DIR/root_mnt"/* "$WORK_DIR/boot_mnt/"
sudo sync

# Unmount filesystems
sudo umount "$WORK_DIR/boot_mnt"
sudo umount "$WORK_DIR/root_mnt"

# Generate sparse images
echo "Generating sparse images..."
sudo img2simg "${LOOP_DEV}p1" "$BURN_DIR/boot.simg"
sudo img2simg "$WORK_DIR/boot_temp.img" "$BURN_DIR/rootfs.simg"

# Generate command file
cat > "$BURN_DIR/commands.txt" << EOF
PARTITION:boot:sparse:boot.simg
PARTITION:rootfs:sparse:rootfs.simg
EOF

# Pack burn image
BURN_IMG_NAME="openwrt-onecloud-${BUILD_DATE}.burn.img"
echo "Generating line flash image: $BURN_IMG_NAME"
"$TOOLS_DIR/AmlImg" pack "$BURN_IMG_NAME" "$BURN_DIR/"

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
xz -9 --threads=0 "$BURN_IMG_NAME"
xz -9 --threads=0 "$CARD_IMG_NAME"

# Clean up temporary files
rm -rf "$BURN_DIR"
rm -f "$WORK_DIR/boot_temp.img"

echo "=== Image Generation Completed ==="
echo "Generated files:"
ls -la *.xz *.sha256