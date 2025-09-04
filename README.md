# 玩客云纯净版OpenWrt固件

![GitHub](https://img.shields.io/github/license/hixiaolu/onecloud-openwrt-trubo)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/hixiaolu/onecloud-openwrt-trubo)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/hixiaolu/onecloud-openwrt-trubo/build-openwrt.yml)

## 项目简介

这是一个为迅雷玩客云（OneCloud）设备定制的纯净版OpenWrt固件项目。该项目基于官方OpenWrt源码构建，移除了所有第三方插件和不必要的组件，只保留核心路由功能和必要的管理工具。

## 固件特性

- ✅ 基于OpenWrt官方最新源码
- ✅ 使用Nginx替代uhttpd作为Web服务器
- ✅ 采用Argon主题作为默认UI
- ✅ 保留核心路由功能（NAT、防火墙、DHCP）
- ✅ 包含LuCI Web管理界面
- ✅ CPU频率管理（玩客云专用）
- ✅ Docker容器支持
- ✅ SSH远程管理
- ✅ 基础网络工具（curl, wget, htop）

## 默认配置

- **默认IP地址**: 192.168.8.88
- **用户名**: root
- **密码**: password
- **主机名**: OneCloud-Pure

## 安装说明

### 线刷固件 (.burn.img.xz)
1. 下载并解压 .burn.img.xz 文件
2. 使用 [Amlogic USB Burning Tool](https://androidmtk.com/download-amlogic-usb-burning-tool) 烧录
3. 设备进入烧录模式后连接USB线进行烧录

### 卡刷固件 (.img.xz)
1. 下载并解压 .img.xz 文件到TF卡
2. 使用dd命令或Etcher写入TF卡
3. 将TF卡插入设备并启动

## 注意事项

- 首次启动需要约5分钟，红灯闪烁为启动中，蓝灯常亮表示启动完成
- 建议首次登录后修改默认密码
- 所有固件文件均提供SHA256校验值

## 自动构建

本项目使用GitHub Actions进行自动构建，每周三凌晨2点自动编译最新固件并发布到Releases。

## 项目结构

```
onecloud-openwrt-trubo/
├── .github/workflows/
│   ├── build-openwrt.yml      # 主构建工作流
│   ├── cleanup.yml            # 清理工作流
│   └── update-checker.yml     # 更新检查工作流
├── configs/
│   ├── onecloud.config        # 玩客云设备配置
│   └── feeds.conf.default     # Feed源配置
├── scripts/
│   ├── customize-feeds.sh     # Feed定制脚本
│   ├── customize-firmware.sh  # 固件定制脚本
│   ├── generate-images.sh     # 镜像生成脚本
│   └── setup-environment.sh   # 环境准备脚本
├── files/
│   └── etc/
│       ├── config/            # 系统配置文件
│       └── rc.local           # 启动脚本
├── tools/
│   ├── AmlImg                 # Amlogic镜像工具
│   └── uboot.img              # U-Boot镜像
├── dependencies.txt           # 构建依赖列表
└── README.md                 # 项目说明
```

## 开发指南

### 本地构建

1. 克隆本项目：
   ```bash
   git clone https://github.com/hixiaolu/onecloud-openwrt-trubo.git
   cd onecloud-openwrt-trubo
   ```

2. 运行验证脚本：
   ```bash
   ./validate-project.sh
   ```

3. 手动触发GitHub Actions构建或在本地环境中编译。

### 自定义配置

- 修改[onecloud.config](configs/onecloud.config)文件来自定义固件组件
- 修改[feeds.conf.default](configs/feeds.conf.default)文件来自定义源
- 修改[scripts/](scripts/)目录下的脚本来自定义构建过程

## 贡献

欢迎提交Issue和Pull Request来改进本项目。

## 许可证

本项目基于MIT许可证发布。