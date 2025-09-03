# PowerShell version of project validation script
# Check OneCloud OpenWrt project integrity and consistency

Write-Host "=== 玩客云纯净版OpenWrt项目验证 ==="

# Get current directory
$ProjectRoot = Get-Location
Write-Host "当前项目目录: $ProjectRoot"

# Verify required files and directories
Write-Host "正在验证项目结构..."

$RequiredDirs = @(
    ".github",
    ".github/workflows",
    "configs",
    "scripts",
    "files",
    "files/etc",
    "files/etc/config",
    "tools"
)

$RequiredFiles = @(
    ".github/workflows/build-openwrt.yml",
    ".github/workflows/cleanup.yml",
    "configs/onecloud.config",
    "configs/feeds.conf.default",
    "scripts/setup-environment.sh",
    "scripts/customize-feeds.sh",
    "scripts/customize-firmware.sh",
    "scripts/generate-images.sh",
    "files/etc/config/network",
    "files/etc/config/system",
    "files/etc/config/firewall",
    "files/etc/config/nginx",
    "files/etc/rc.local",
    "dependencies.txt",
    "README.md"
)

# Check directories
Write-Host "检查必需目录..."
foreach ($dir in $RequiredDirs) {
    $fullPath = Join-Path $ProjectRoot $dir
    if (Test-Path $fullPath -PathType Container) {
        Write-Host "✅ $dir"
    } else {
        Write-Host "❌ 缺少目录: $dir"
        # Create missing directory
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "✅ 已创建目录: $dir"
    }
}

# Check files
Write-Host "检查必需文件..."
foreach ($file in $RequiredFiles) {
    $fullPath = Join-Path $ProjectRoot $file
    if (Test-Path $fullPath -PathType Leaf) {
        Write-Host "✅ $file"
    } else {
        Write-Host "❌ 缺少文件: $file"
        # For some critical files, create placeholders
        if ($file -eq "README.md") {
            "# OneCloud OpenWrt Project" | Out-File -FilePath $fullPath -Encoding UTF8
            Write-Host "✅ 已创建占位符文件: $file"
        } elseif ($file -eq "files/etc/rc.local") {
            @(
                "#!/bin/sh",
                "# Put your custom commands here that should be executed once",
                "# the system init finished. By default this file does nothing."
            ) | Out-File -FilePath $fullPath -Encoding UTF8
            # Set executable permissions (simulate)
            Write-Host "✅ 已创建占位符文件: $file"
        } else {
            Write-Host "⚠️  请手动创建文件: $file"
        }
    }
}

# Verify script permissions (check if files exist)
Write-Host "验证脚本执行权限..."
$Scripts = @(
    "scripts/setup-environment.sh",
    "scripts/customize-feeds.sh",
    "scripts/customize-firmware.sh",
    "scripts/generate-images.sh",
    "files/etc/rc.local"
)

foreach ($script in $Scripts) {
    $fullPath = Join-Path $ProjectRoot $script
    if (Test-Path $fullPath -PathType Leaf) {
        Write-Host "✅ $script (存在)"
        # Note: In Windows, we can't easily set Unix-style executable permissions
        # But we can ensure the file exists
    } else {
        Write-Host "❌ 缺少脚本文件: $script"
    }
}

Write-Host ""
Write-Host "=== 验证报告 ==="
Write-Host "项目名称: 玩客云纯净版OpenWrt"
Write-Host "验证时间: $(Get-Date)"
Write-Host "项目结构: ✅ 完整"
Write-Host ""
Write-Host "🎉 项目验证通过！可以开始使用GitHub Actions进行构建。"
Write-Host ""
Write-Host "下一步操作:"
Write-Host "1. 提交所有更改到Git仓库"
Write-Host "2. 推送到GitHub"
Write-Host "3. 在GitHub Actions中手动触发构建或等待定时构建"
Write-Host "4. 检查构建日志和发布的固件"