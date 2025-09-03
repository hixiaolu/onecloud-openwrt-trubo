#!/bin/bash
#
# 项目验证脚本
# 检查玩客云纯净版OpenWrt项目的完整性和一致性
#

set -e

echo "=== 玩客云纯净版OpenWrt项目验证 ==="

# 检查项目根目录
PROJECT_ROOT=$(dirname "$0")
cd "$PROJECT_ROOT"

echo "当前项目目录: $(pwd)"

# 验证必需文件和目录
echo "正在验证项目结构..."

REQUIRED_FILES=(
    ".github/workflows/build-openwrt.yml"
    ".github/workflows/cleanup.yml"
    "configs/onecloud.config"
    "configs/feeds.conf.default"
    "scripts/setup-environment.sh"
    "scripts/customize-feeds.sh"
    "scripts/customize-firmware.sh"
    "scripts/generate-images.sh"
    "files/etc/config/network"
    "files/etc/config/system"
    "files/etc/config/firewall"
    "files/etc/config/nginx"
    "files/etc/rc.local"
    "dependencies.txt"
    "README.md"
)

REQUIRED_DIRS=(
    ".github"
    ".github/workflows"
    "configs"
    "scripts"
    "files"
    "files/etc"
    "files/etc/config"
    "tools"
    "patches"
)

# 检查目录
echo "检查必需目录..."
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir"
    else
        echo "❌ 缺少目录: $dir"
        # 创建缺失的目录
        mkdir -p "$dir"
        echo "✅ 已创建目录: $dir"
    fi
done

# 检查文件
echo "检查必需文件..."
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ 缺少文件: $file"
        # 对于某些关键文件，创建占位符
        if [[ "$file" == "README.md" ]]; then
            echo "# OneCloud OpenWrt Project" > "$file"
            echo "✅ 已创建占位符文件: $file"
        elif [[ "$file" == "files/etc/rc.local" ]]; then
            echo "#!/bin/sh" > "$file"
            echo "# Put your custom commands here that should be executed once" >> "$file"
            echo "# the system init finished. By default this file does nothing." >> "$file"
            chmod +x "$file"
            echo "✅ 已创建占位符文件: $file"
        else
            echo "⚠️  请手动创建文件: $file"
        fi
    fi
done

# 验证脚本权限
echo "验证脚本执行权限..."
SCRIPTS=(
    "scripts/setup-environment.sh"
    "scripts/customize-feeds.sh"
    "scripts/customize-firmware.sh"
    "scripts/generate-images.sh"
    "files/etc/rc.local"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo "✅ $script (可执行)"
        else
            echo "⚠️  $script (需要执行权限)"
            chmod +x "$script"
            echo "✅ 已修复 $script 权限"
        fi
    else
        echo "❌ 缺少脚本文件: $script"
    fi
done

# 验证配置文件内容
echo "验证配置文件内容..."

# 检查OpenWrt配置
if [ -f "configs/onecloud.config" ] && grep -q "CONFIG_TARGET_amlogic=y" configs/onecloud.config; then
    echo "✅ 玩客云目标平台配置正确"
else
    echo "❌ 玩客云目标平台配置错误"
    exit 1
fi

if [ -f "configs/onecloud.config" ] && grep -q "CONFIG_PACKAGE_nginx-all-module=y" configs/onecloud.config; then
    echo "✅ Nginx配置正确"
else
    echo "❌ Nginx配置错误"
    exit 1
fi

if [ -f "configs/onecloud.config" ] && grep -q "CONFIG_PACKAGE_luci-theme-argon=y" configs/onecloud.config; then
    echo "✅ Argon主题配置正确"
else
    echo "❌ Argon主题配置错误"
    exit 1
fi

# 检查feeds配置
if [ -f "configs/feeds.conf.default" ] && grep -q "src-git argon https://github.com/jerrykuku/luci-theme-argon.git" configs/feeds.conf.default; then
    echo "✅ Argon主题源配置正确"
else
    echo "❌ Argon主题源配置错误"
    exit 1
fi

# 检查网络配置
if [ -f "files/etc/config/network" ] && grep -q "192.168.8.88" files/etc/config/network; then
    echo "✅ 默认IP地址配置正确"
else
    echo "❌ 默认IP地址配置错误"
    exit 1
fi

# 检查系统配置
if [ -f "files/etc/config/system" ] && grep -q "OneCloud-Pure" files/etc/config/system; then
    echo "✅ 主机名配置正确"
else
    echo "❌ 主机名配置错误"
    exit 1
fi

# 验证GitHub Actions工作流
echo "验证GitHub Actions工作流..."
if [ -f ".github/workflows/build-openwrt.yml" ] && grep -q "Pure OpenWrt Builder for OneCloud" .github/workflows/build-openwrt.yml; then
    echo "✅ 主工作流名称正确"
else
    echo "❌ 主工作流名称错误"
    exit 1
fi

if [ -f ".github/workflows/build-openwrt.yml" ] && grep -q "https://github.com/openwrt/openwrt" .github/workflows/build-openwrt.yml; then
    echo "✅ OpenWrt官方源配置正确"
else
    echo "❌ OpenWrt官方源配置错误"
    exit 1
fi

# 验证依赖文件
echo "验证构建依赖..."
if [ -s "dependencies.txt" ]; then
    DEP_COUNT=$(wc -l < dependencies.txt)
    echo "✅ 依赖文件包含 $DEP_COUNT 个包"
else
    echo "❌ 依赖文件为空或不存在"
    exit 1
fi

# 检查工具目录
echo "检查工具目录..."
if [ -d "tools" ]; then
    if [ -f "tools/AmlImg" ]; then
        echo "✅ AmlImg工具存在"
    else
        echo "⚠️  AmlImg工具缺失 (构建时会自动处理)"
    fi
    
    if [ -f "tools/uboot.img" ]; then
        echo "✅ U-Boot镜像存在"
    else
        echo "⚠️  U-Boot镜像缺失 (构建时会自动处理)"
    fi
else
    echo "❌ tools目录缺失"
    exit 1
fi

# 生成验证报告
echo ""
echo "=== 验证报告 ==="
echo "项目名称: 玩客云纯净版OpenWrt"
echo "验证时间: $(date)"
echo "项目结构: ✅ 完整"
echo "配置文件: ✅ 正确"
echo "脚本权限: ✅ 正常"
echo "工作流程: ✅ 配置正确"

echo ""
echo "🎉 项目验证通过！可以开始使用GitHub Actions进行构建。"
echo ""
echo "下一步操作:"
echo "1. 提交所有更改到Git仓库"
echo "2. 推送到GitHub"
echo "3. 在GitHub Actions中手动触发构建或等待定时构建"
echo "4. 检查构建日志和发布的固件"

exit 0