# 下载、安装与排障

**[下载最新版](https://github.com/andyforfun168/KuroCatAndy/releases/latest)** · [主页使用说明](../README.md) · [提交问题](https://github.com/andyforfun168/KuroCatAndy/issues)

本仓库是 [chanke17/KuroCat](https://github.com/chanke17/KuroCat) 的社区 fork，沿用 KuroCat 应用名称及 MIT License。请优先阅读具体 Release 的说明；主页中的平台兼容性描述不代表每个预编译包都能运行在所有旧系统上。

## 选择文件

| 系统 / CPU | 下载文件 | 要求 |
| --- | --- | --- |
| macOS / Apple Silicon 或 Intel | `KuroCat-macOS-universal.zip` | macOS 13+；一个包包含 arm64 / x86_64 |
| Windows / Intel 或 AMD 64 位 | `KuroCat-Windows-x64.exe` | Windows 10 / 11 x64 |
| Debian 系 Linux / Intel 或 AMD 64 位 | `KuroCat-Linux-amd64.deb` | 以 Ubuntu 22.04 为构建基线；由包管理器检查依赖 |
| Debian 系 Linux / ARM64 | `KuroCat-Linux-arm64.deb` | 同上；适用于 ARM64，不是 ARMv7 |
| 其他 Linux / Intel 或 AMD 64 位 | `KuroCat-Linux-x86_64.tar.gz` | glibc 2.35+ 及兼容的 GTK3、Cairo、X11、Xi、C++ 运行库 |
| 其他 Linux / ARM64 | `KuroCat-Linux-arm64.tar.gz` | 同上 |

`Source code (zip/tar.gz)` 是 GitHub 自动生成的源码归档，不是安装包。Windows ARM64、32 位系统、LoongArch 没有本次预编译包。Linux 可用 `uname -m` 确认架构，用 `ldd --version` 查看 glibc。

## macOS

1. 解压，把 `KuroCat.app` 拖入「应用程序」，再打开。
2. 在「系统设置 → 隐私与安全性 → 输入监控」授权 KuroCat，然后从菜单栏重启应用。
3. 开启完全鼠标穿透后，可从菜单栏小猫图标关闭，或按住 Option 再右键 / 拖动小猫。

该社区构建使用 ad-hoc 签名，未经过 Apple Developer ID 签名或 notarization。macOS 可能阻止首次启动；确认下载来源及校验值后，按系统「隐私与安全性」提供的操作处理。若没有允许打开的选项，或系统明确提示恶意软件，请停止操作并反馈错误原文。更新后若监听失效，可在「输入监控」重新授权并重启应用。

## Windows

下载 `.exe` 后双击即可运行，无需额外安装运行时。菜单位于小猫右键菜单或右下角托盘；隐藏图标可在任务栏 `^` 中找到。

完全穿透可用 `Ctrl + Alt + Shift + P` 切换；也可按住 Alt 后右键小猫，或再次运行同一个 exe 呼出菜单。该版本没有 Authenticode 发行者签名，Windows 可能显示未知发布者提示；请先核对来源与 SHA-256。应用不保证兼容所有反作弊或权限隔离的游戏环境。

## Linux / 统信 UOS / Deepin / 麒麟

优先使用 `.deb`，让系统检查并安装依赖：

```bash
sudo apt install ./KuroCat-Linux-amd64.deb
# ARM64 请将文件名换成 KuroCat-Linux-arm64.deb
kurocat
```

其他发行版解压对应 tar 包，进入解压目录执行 `./kurocat`。若缺共享库，可执行 `ldd ./kurocat` 查看 `not found` 项，再通过当前发行版的包管理器安装依赖。

**兼容性边界：**预编译文件在 Ubuntu 22.04 / glibc 2.35 环境构建；Ubuntu 20.04、Debian 11 和旧版 UOS 不保证可用，遇到 `GLIBC_*` / `GLIBCXX_* not found` 请按主页步骤在目标机器源码编译，不要替换系统 libc。UOS / Deepin / 麒麟版本众多，是否能安装以依赖检查为准。

X11 是优先使用的桌面会话。Wayland 的全局输入、窗口置顶、定位及穿透行为受 compositor 限制，尚未保证完整兼容；遇到问题请先使用 X11。主页提到的 `input` 组权限仅解决 evdev 设备读取，不能消除所有 Wayland 限制；该组允许读取原始输入设备，授权前请了解其范围。

## 核对下载完整性

从同一 Release 下载 `SHA256SUMS.txt`。只下载一个包时，比较该文件中对应行即可，不必下载所有平台：

```bash
# macOS
shasum -a 256 KuroCat-macOS-universal.zip
# Linux
sha256sum KuroCat-Linux-amd64.deb
```

Windows PowerShell：

```powershell
Get-FileHash .\KuroCat-Windows-x64.exe -Algorithm SHA256
```

SHA-256 用于确认文件与本 Release 清单一致，不等同于操作系统发行者签名。

## 更新、退出与反馈

更新前从菜单退出旧进程，再替换应用或 exe；`.deb` 可重新执行 `apt install`。应用名、bundle ID 继承上游，请避免同时运行上游版和 fork 版。若启用过开机自动启动，移除应用前先在菜单关闭该项。

问题反馈请注明 Release 版本、下载文件、系统版本、CPU 架构和复现步骤；Linux 补充发行版及 X11/Wayland。不要附带密码、私人输入内容或完整设备输入日志。
