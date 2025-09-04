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

# Check required tools and files
echo "Checking required tools and files..."
if [ ! -f "$TOOLS_DIR/AmlImg" ]; then
    echo "Error: AmlImg tool not found"
    exit 1
fi

if [ ! -f "$TOOLS_DIR/uboot.img" ]; then
    echo "Error: uboot.img file not found"
    exit 1
fi

# Enhanced check for compiled image file with better error handling
echo "Searching for compiled image file..."
IMG_PATH=""
MAX_SEARCH_ATTEMPTS=3
SEARCH_ATTEMPT=0

while [ $SEARCH_ATTEMPT -lt $MAX_SEARCH_ATTEMPTS ]; do
    IMG_PATH=$(find openwrt/bin/targets -name "*.img.gz" -type f | head -n 1)
    if [ -n "$IMG_PATH" ]; then
        echo "Found image file: $IMG_PATH"
        break
    else
        SEARCH_ATTEMPT=$((SEARCH_ATTEMPT + 1))
        echo "Image file not found, attempt $SEARCH_ATTEMPT/$MAX_SEARCH_ATTEMPTS"
        if [ $SEARCH_ATTEMPT -eq $MAX_SEARCH_ATTEMPTS ]; then
            echo "Error: Compiled .img.gz file not found after $MAX_SEARCH_ATTEMPTS attempts"
            echo "Available files in bin/targets:"
            find openwrt/bin/targets -type f | head -20 || echo "No files found"
            exit 1
        fi
        sleep 5
    fi
done

echo "Found image file: $IMG_PATH"

# Enhanced unzip with error handling
echo "Unzipping image file..."
if ! gzip -dk "$IMG_PATH"; then
    echo "Error: Failed to unzip image file"
    echo "File information:"
    ls -lh "$IMG_PATH" 2>/dev/null || echo "File not found"
    exit 1
fi

IMG_FILE="${IMG_PATH%.gz}"

# Check unzipped file
if [ ! -f "$IMG_FILE" ]; then
    echo "Error: Unzipped image file does not exist"
    exit 1
fi

echo "Unzipped image file: $IMG_FILE"
echo "File size: $(ls -lh "$IMG_FILE" | awk '{print $5}')"

# Prepare working directory with better error handling
BURN_DIR="$WORK_DIR/burn_temp"
echo "Cleaning up previous temporary files..."
rm -rf "$BURN_DIR" 2>/dev/null || true
mkdir -p "$BURN_DIR"

echo "=== Generating Line Flash Firmware ==="

# Enhanced unpack uboot.img with error handling
echo "Unpacking uboot.img..."
if ! "$TOOLS_DIR/AmlImg" unpack "$TOOLS_DIR/uboot.img" "$BURN_DIR/"; then
    echo "Error: Failed to unpack uboot.img"
    echo "Tool information:"
    ls -lh "$TOOLS_DIR/AmlImg" 2>/dev/null || echo "Tool not found"
    exit 1
fi

# Set loop device with better error handling
echo "Setting loop device..."
MAX_RETRIES=5
RETRY_COUNT=0

# Enhanced cleanup function for loop devices
cleanup_loops() {
    echo "Cleaning up loop devices..."
    # First try to unmount any mounted partitions
    for mount_point in "$WORK_DIR/boot_mnt" "$WORK_DIR/root_mnt"; do
        if mountpoint -q "$mount_point" 2>/dev/null; then
            echo "Unmounting $mount_point..."
            sudo umount "$mount_point" 2>/dev/null || {
                echo "Warning: Failed to unmount $mount_point"
                sudo umount -f "$mount_point" 2>/dev/null || true
            }
        fi
    done
    
    # Reset all loop devices
    echo "Resetting loop devices..."
    sudo losetup --reset 2>/dev/null || true
    
    # Wait a moment for devices to be released
    sleep 2
    
    # Forcefully delete any remaining loop devices
    for loop_dev in $(losetup -a 2>/dev/null | grep -o '/dev/loop[0-9]*'); do
        echo "Detaching $loop_dev..."
        sudo losetup -d "$loop_dev" 2>/dev/null || true
    done
}

# Clean up any existing loop devices before starting
cleanup_loops

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    LOOP_DEV=""
    # Try to find an available loop device
    LOOP_DEV=$(sudo losetup --find --show --partscan "$IMG_FILE" 2>/dev/null) || LOOP_DEV=""
    if [ -n "$LOOP_DEV" ] && [ -b "$LOOP_DEV" ]; then
        echo "Successfully set loop device: $LOOP_DEV"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "Failed to set loop device, retrying... ($RETRY_COUNT/$MAX_RETRIES)"
        if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
            echo "Error: Unable to set loop device after $MAX_RETRIES attempts"
            # Output diagnostic information
            echo "Disk space:"
            df -h
            echo "Image file information:"
            ls -la "$IMG_FILE" 2>/dev/null || echo "Image file not found"
            echo "Loop devices status:"
            losetup -a 2>/dev/null || echo "Cannot get loop device status"
            echo "Available loop devices:"
            ls -la /dev/loop* 2>/dev/null || echo "No loop devices found"
            exit 1
        fi
        sleep 3
        # Clean up before retrying
        cleanup_loops
    fi
done

echo "Using loop device: $LOOP_DEV"

# Enhanced cleanup function with better error handling
cleanup() {
    echo "Cleaning up resources..."
    sync 2>/dev/null || true
    sleep 2
    
    # More robust unmounting
    if mountpoint -q "$WORK_DIR/boot_mnt" 2>/dev/null; then
        echo "Unmounting boot_mnt..."
        sudo umount "$WORK_DIR/boot_mnt" 2>/dev/null || {
            echo "Warning: Failed to unmount boot_mnt"
            sudo umount -f "$WORK_DIR/boot_mnt" 2>/dev/null || true
        }
    fi
    
    if mountpoint -q "$WORK_DIR/root_mnt" 2>/dev/null; then
        echo "Unmounting root_mnt..."
        sudo umount "$WORK_DIR/root_mnt" 2>/dev/null || {
            echo "Warning: Failed to unmount root_mnt"
            sudo umount -f "$WORK_DIR/root_mnt" 2>/dev/null || true
        }
    fi
    
    # Detach loop device with retries
    if [ -n "$LOOP_DEV" ] && [ -b "$LOOP_DEV" ]; then
        echo "Detaching loop device..."
        sudo losetup -d "$LOOP_DEV" 2>/dev/null || {
            echo "Warning: Failed to detach loop device, trying again..."
            sleep 2
            sudo losetup -d "$LOOP_DEV" 2>/dev/null || {
                echo "Warning: Failed to detach loop device after retry"
            }
        }
    fi
    
    # Clean up directories
    rm -rf "$WORK_DIR/boot_mnt" "$WORK_DIR/root_mnt" 2>/dev/null || true
    rm -f "$WORK_DIR/boot_temp.img" 2>/dev/null || true
}

# Set cleanup on exit
trap cleanup EXIT

# Wait for partition devices to appear with better handling
echo "Waiting for partition devices to appear..."
sleep 5

# Check partitions with better error handling
PARTITION_CHECK_COUNT=0
MAX_PARTITION_CHECKS=10

while [ $PARTITION_CHECK_COUNT -lt $MAX_PARTITION_CHECKS ]; do
    if [ -e "${LOOP_DEV}p1" ] && [ -e "${LOOP_DEV}p2" ]; then
        echo "Partition devices found"
        break
    else
        PARTITION_CHECK_COUNT=$((PARTITION_CHECK_COUNT + 1))
        echo "Waiting for partitions to appear... ($PARTITION_CHECK_COUNT/$MAX_PARTITION_CHECKS)"
        sudo partprobe "$LOOP_DEV" 2>/dev/null || true
        sleep 3
    fi
done

if [ ! -e "${LOOP_DEV}p1" ] || [ ! -e "${LOOP_DEV}p2" ]; then
    echo "Error: Partition devices do not exist after $MAX_PARTITION_CHECKS attempts"
    echo "Available block devices:"
    lsblk 2>/dev/null || echo "Cannot list block devices"
    echo "FDISK output:"
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

# Create mount points with error handling
echo "Creating mount points..."
mkdir -p "$WORK_DIR/boot_mnt" "$WORK_DIR/root_mnt" || {
    echo "Error: Failed to create mount points"
    exit 1
}

# Mount filesystems with better error handling
echo "Mounting filesystems..."
if ! sudo mount "$WORK_DIR/boot_temp.img" "$WORK_DIR/boot_mnt" 2>/dev/null; then
    echo "Error: Failed to mount boot image"
    echo "Mount information:"
    mount | grep "$WORK_DIR/boot_temp.img" || echo "Not mounted"
    exit 1
fi

if ! sudo mount "${LOOP_DEV}p2" "$WORK_DIR/root_mnt" 2>/dev/null; then
    echo "Error: Failed to mount rootfs partition"
    echo "Mount information:"
    mount | grep "${LOOP_DEV}p2" || echo "Not mounted"
    exit 1
fi

# Copy files with better error handling and progress indication
echo "Copying rootfs contents to boot image..."
COPY_START_TIME=$(date +%s)
if ! sudo rsync -a "$WORK_DIR/root_mnt"/ "$WORK_DIR/boot_mnt/" 2>/dev/null; then
    echo "Warning: rsync failed, trying cp command..."
    if ! sudo cp -rp "$WORK_DIR/root_mnt"/* "$WORK_DIR/boot_mnt/" 2>/dev/null; then
        echo "Error: Failed to copy files to boot image"
        exit 1
    fi
fi
COPY_END_TIME=$(date +%s)
COPY_DURATION=$((COPY_END_TIME - COPY_START_TIME))
echo "File copy completed in $COPY_DURATION seconds"

if ! sudo sync; then
    echo "Warning: Sync command failed"
fi

# Unmount filesystems
echo "Unmounting filesystems..."
sudo umount "$WORK_DIR/boot_mnt" || {
    echo "Warning: Failed to unmount boot_mnt"
}
sudo umount "$WORK_DIR/root_mnt" || {
    echo "Warning: Failed to unmount root_mnt"
}

# Generate sparse images with better error handling
echo "Generating sparse images..."
if ! sudo img2simg "${LOOP_DEV}p1" "$BURN_DIR/boot.simg" 2>/dev/null; then
    echo "Error: Failed to generate boot sparse image"
    echo "Checking source file:"
    ls -la "${LOOP_DEV}p1" 2>/dev/null || echo "Source file not found"
    exit 1
fi

if ! sudo img2simg "$WORK_DIR/boot_temp.img" "$BURN_DIR/rootfs.simg" 2>/dev/null; then
    echo "Error: Failed to generate rootfs sparse image"
    echo "Checking source file:"
    ls -la "$WORK_DIR/boot_temp.img" 2>/dev/null || echo "Source file not found"
    exit 1
fi

# Generate command file
echo "Generating command file..."
cat > "$BURN_DIR/commands.txt" << EOF
PARTITION:boot:sparse:boot.simg
PARTITION:rootfs:sparse:rootfs.simg
EOF

# Pack burn image with better error handling
BURN_IMG_NAME="openwrt-onecloud-${BUILD_DATE}.burn.img"
echo "Generating line flash image: $BURN_IMG_NAME"
if ! "$TOOLS_DIR/AmlImg" pack "$BURN_IMG_NAME" "$BURN_DIR/" 2>/dev/null; then
    echo "Error: Failed to pack burn image"
    echo "Checking working directory:"
    ls -la "$BURN_DIR/" 2>/dev/null || echo "Directory not found"
    exit 1
fi

# Move to firmware directory with error handling
FIRMWARE_DIR=$(dirname "$IMG_FILE")
if [ -f "$BURN_IMG_NAME" ]; then
    if ! mv "$BURN_IMG_NAME" "$FIRMWARE_DIR/"; then
        echo "Error: Failed to move burn image to firmware directory"
        exit 1
    fi
else
    echo "Error: Burn image file not found"
    exit 1
fi

echo "=== Generating Card Flash Firmware ==="

# Rename card flash image with error handling
CARD_IMG_NAME="openwrt-onecloud-${BUILD_DATE}.img"
if [ -f "$IMG_FILE" ]; then
    if ! mv "$IMG_FILE" "$FIRMWARE_DIR/$CARD_IMG_NAME"; then
        echo "Error: Failed to rename card flash image"
        exit 1
    fi
else
    echo "Error: Original image file not found"
    exit 1
fi

echo "=== Compressing Firmware Files ==="

# Enter firmware directory
cd "$FIRMWARE_DIR" || {
    echo "Error: Failed to enter firmware directory"
    exit 1
}

# Generate checksum files and compress with better error handling
echo "Generating checksum files..."
if ! sha256sum "$BURN_IMG_NAME" > "${BURN_IMG_NAME}.sha256" 2>/dev/null; then
    echo "Error: Failed to generate checksum for burn image"
    exit 1
fi

if ! sha256sum "$CARD_IMG_NAME" > "${CARD_IMG_NAME}.sha256" 2>/dev/null; then
    echo "Error: Failed to generate checksum for card image"
    exit 1
fi

echo "Compressing firmware files..."
# Enhanced compression with better error handling
if command -v pxz >/dev/null 2>&1; then
    COMPRESS_CMD="pxz"
elif command -v xz >/dev/null 2>&1; then
    COMPRESS_CMD="xz"
else
    echo "Error: No compression tool found"
    exit 1
fi

# Compress burn image
if ! $COMPRESS_CMD -9 --threads=0 "$BURN_IMG_NAME" 2>/dev/null; then
    echo "Warning: Failed to compress burn image with parallel compression, trying single thread"
    if ! $COMPRESS_CMD -9 "$BURN_IMG_NAME" 2>/dev/null; then
        echo "Error: Failed to compress burn image"
        exit 1
    fi
fi

# Compress card image
if ! $COMPRESS_CMD -9 --threads=0 "$CARD_IMG_NAME" 2>/dev/null; then
    echo "Warning: Failed to compress card image with parallel compression, trying single thread"
    if ! $COMPRESS_CMD -9 "$CARD_IMG_NAME" 2>/dev/null; then
        echo "Error: Failed to compress card image"
        exit 1
    fi
fi

# Clean up temporary files
echo "Cleaning up temporary files..."
rm -rf "$BURN_DIR" 2>/dev/null || true
rm -f "$WORK_DIR/boot_temp.img" 2>/dev/null || true

echo "=== Image Generation Completed ==="
echo "Generated files:"
ls -la *.xz *.sha256 2>/dev/null || echo "No files found"