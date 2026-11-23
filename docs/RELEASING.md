# 维护与发版

本 fork 保留上游 KuroCat 的 MIT License 与作者署名，应用功能来自上游。主页 README 的公开路径与命令需要保持兼容。

## 发布流程

1. 将修改提交到 `main`，确认 Actions 中 Windows、macOS、Linux amd64 / arm64 构建通过。
2. 在 `docs/releases/vX.Y.Z.md` 准备该版本完整的下载与更新说明。Tag 使用三段数字，例如 `v1.2.0`；不要覆盖既有版本的 Tag 或已发布二进制。
3. 在已核对的提交创建并推送 Tag：

   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

4. 工作流从该 Tag 编译四个目标，校验六个安装包 / 归档并生成 `SHA256SUMS.txt`，附带 `LICENSE.txt`，最后建立 **Draft Release**。普通分支构建和手动 Run workflow 仅产生 Actions artifacts。
5. 在 Releases 检查草稿、六个文件名、版本、系统要求和 SHA-256；macOS Universal 架构 / 签名、Linux 包架构 / 动态库依赖由 CI 检查。编译及打包通过不能替代各平台桌面运行验证。
6. 发布草稿并将稳定版本设为 Latest。检查 `/releases/latest` 和主页 Releases 链接能到达该版本，且下载文件名与 README 一致。

完整下载名单由 `scripts/verify-release.sh` 维护。缺文件、空文件、归档错误或缺少对应版本正文时，工作流停止，不生成不完整发布。自动生成的变更记录可使用 `.github/release.yml` 分类，但应保留面向使用者的安装说明。

## 构建与权限

- 本地 macOS：`./build.sh`；实现集中在 `scripts/build-macos.sh`。
- 本地 Windows / Linux：使用各自平台目录里的原有构建入口。
- 普通构建仅有 `contents: read`；只有 Tag 的 release job 有 `contents: write`。
- Linux 容器基线为 Ubuntu 22.04 / glibc 2.35；Debian 包通过 `dpkg-shlibdeps` 记录实际运行依赖，禁止只凭发行版名称宣称兼容。
- macOS / Windows 当前没有正式的发行者签名或 notarization。不要在 Release 中写成已签名认证发行版。
- 不要把本地密钥、开发者证书、私人配置或构建缓存提交到仓库。
