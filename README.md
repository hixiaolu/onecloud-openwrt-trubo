# 玩客云纯净版OpenWrt自动编译

🚀 **基于OpenWrt官方最新内核的纯净固件，仅包含核心功能和必要组件**

## ✨ 固件特性

### 🎯 纯净性
- ✅ 使用OpenWrt官方最新内核
- ✅ 仅包含核心功能组件

### 💻 核心功能
- 🌐 NAT网络地址转换
- 🔥 防火墙与安全规则
- 📶 DHCP服务器
- 🌍 DNS解析服务
- 🔌 PPPoE宽带拨号支持
- 🌐 IPv6完整支持

### 🔧 管理工具
- 🌐 LuCI Web管理界面
- 🎨 Argon美化主题
- 🔒 SSH远程管理
- 🔋 Nginx高性能Web服务器
- 📊 系统监控与日志

### ⚡ 性能优化
- 🚀 BBR TCP拥塞控制
- 🔋 CPU频率管理（玩客云专用）
- 💾 内存与网络参数优化
- 📦 Docker容器支持

## 💻 设备信息

- **支持设备**: 玩客云 (Thunder OneCloud)
- **架构**: ARM Cortex-A5 + VFPv4
- **内核**: 最新OpenWrt官方Linux内核
- **默认IP**: `192.168.8.88`
- **默认用户**: `root`
- **默认密码**: `password`

## 🚀 安装指南

### 方式一：线刷固件 (.burn.img.xz)

**推荐使用，更加稳定**

1. 下载并解压 `.burn.img.xz` 文件
2. 下载并安装 [Amlogic USB Burning Tool](https://androidmtk.com/download-amlogic-usb-burning-tool)
3. 连接玩客云到电脑（USB线）
4. 让设备进入烧录模式
5. 在Burning Tool中选择解压后的 `.burn.img` 文件
6. 点击开始烧录

### 方式二：卡刷固件 (.img.xz)

**适用于高级用户**

1. 下载并解压 `.img.xz` 文件
2. 使用 `dd` 命令或 [Etcher](https://www.balena.io/etcher/) 将镜像写入TF卡
   ```bash
   # Linux/macOS
   sudo dd if=openwrt-onecloud-xxx.img of=/dev/sdX bs=4M status=progress
   
   # Windows (PowerShell)
   dd if=openwrt-onecloud-xxx.img of=\\.\PhysicalDriveX bs=4M --progress
   ```
3. 将TF卡插入玩客云并启动

### 🚨 重要提示

- ⚙️ **首次启动**: 约5分钟，请耐心等待
- 🔴 **红灯闪烁**: 表示系统正在启动
- 🔵 **蓝灯常亮**: 表示系统启动完成
- 🔒 **安全提示**: 首次登录后请立即修改默认密码

## 📈 自动构建

本项目使用GitHub Actions实现自动构建：

- 📅 **定时构建**: 每周日凌晨2点自动构建
- ⚡ **手动触发**: 支持手动触发构建
- 🎯 **多内核支持**: 支持选择不同的OpenWrt内核版本
- 💾 **自动发布**: 构建完成后自动发布到Releases

## 🛠️ 项目结构

```
onecloud-openwrt-pure/
├── .github/
│   └── workflows/
│       ├── build-openwrt.yml      # 主构建工作流
│       └── cleanup.yml            # 清理工作流
├── configs/
│   ├── onecloud.config          # 玩客云设备配置
│   └── feeds.conf.default       # Feed源配置
├── scripts/
│   ├── customize-feeds.sh       # Feed定制脚本
│   ├── customize-firmware.sh    # 固件定制脚本
│   ├── generate-images.sh       # 镜像生成脚本
│   └── setup-environment.sh     # 环境准备脚本
├── files/
│   └── etc/
│       ├── config/                  # 系统配置文件
│       └── rc.local                # 启动脚本
├── tools/
│   ├── AmlImg                   # Amlogic镜像工具
│   └── uboot.img                # U-Boot镜像
├── dependencies.txt             # 构建依赖列表
└── README.md                    # 项目说明
```




## 🔗 相关链接

- [📚 OpenWrt官方文档](https://openwrt.org/docs/start)
- [🐙 玩客云刷机教程](https://www.right.com.cn/forum/thread-981406-1-1.html)
- [🔧 Amlogic USB Burning Tool](https://androidmtk.com/download-amlogic-usb-burning-tool)
- [💻 Etcher 镜像写入工具](https://www.balena.io/etcher/)


## 🙏 致谢

感谢以下开源项目和作者：

- **OpenWrt 官方项目**: [🌐 OpenWrt](https://github.com/openwrt/openwrt)
- **GitHub Actions 模板**: [🚀 P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt)
- **玩客云 U-Boot**: [🔧 hzyitc/u-boot-onecloud](https://github.com/hzyitc/u-boot-onecloud)
- **Amlogic 镜像工具**: [📎 hzyitc/AmlImg](https://github.com/hzyitc/AmlImg)
- **Argon 主题**: [🎨 jerrykuku/luci-theme-argon](https://github.com/jerrykuku/luci-theme-argon)
- **打包脚本参考**: [📦 shiyu1314/openwrt-onecloud](https://github.com/shiyu1314/openwrt-onecloud)
- **线刷包打包工具**: [hzyitc/AmlImg](https://github.com/hzyitc/AmlImg)

特别鸣谢：
- **xydche/onecloud-openwr**：[xydche/onecloud-openwrt] https://github.com/xydche/onecloud-openwrt
  (ps:特别感谢xydche,使用了公开库，让我这种小白也能定制化云编译，感激涕零xydche，因为我试了好几个wky的云编译的工作流都使用了私库，拉到自己账号也没法跑了，所以再次感谢xydche这类使用公开库的老师傅！)

以及所有为OpenWrt生态系统做出贡献的开发者们！

