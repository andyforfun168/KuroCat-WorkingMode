# 文件分类

为保留主页 README 中的图片链接、目录和构建命令，平台源码与公开入口保持兼容；新增的维护内容集中在以下目录。

| 目录 / 文件 | 用途 |
| --- | --- |
| `Sources/` | macOS Swift 源码 |
| `Resources/` | macOS Info.plist 与应用图标 |
| `windows/` | Windows C++ 源码、manifest、MSVC / CMake 构建入口 |
| `linux/` | Linux C++ 源码、桌面入口、图标与打包入口 |
| `assets/` | README 使用的演示 GIF 和预览图；保留原路径 |
| `scripts/` | macOS 构建实现及跨平台发布资产校验 |
| `docs/` | 下载排障、发版流程与文件分类说明 |
| `docs/releases/` | 每个 Tag 对应的 Release 正文 |
| `.github/workflows/` | 三平台构建与 Release 草稿生成 |
| `.github/ISSUE_TEMPLATE/` | 使用问题模板和下载入口 |
| `.github/release.yml` | 自动生成更新日志时的分类规则 |
| `build.sh` | 兼容 README 的 macOS 构建入口，转发至 `scripts/build-macos.sh` |
| `README.md` / `LICENSE` | 项目首页与上游 MIT License |

安装包、校验清单通过 Releases 分发；编译产物和本地缓存由 `.gitignore` 排除，不提交到源码目录。`dist/` 仅用于 CI 汇集发版产物。
