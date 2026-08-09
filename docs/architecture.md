# DJOneHub 公开源码架构

## 目标

为兼容硬件模块提供本机 SIM 管理、短信、网络、GNSS、来电状态和通话控制能力。服务仅监听本机回环地址。

## 模块边界

- `cmd/djonehub-macos`：Go 本地服务、USB/AT、短信、网络、GNSS、通话状态与网页控制台。
- `macos/DJOneHubNotifier`：SwiftUI macOS App，负责通知、拨号、短信、通讯录和设置界面。
- `cmd/djonehub-macos/audio_darwin.go`：macOS CoreAudio 设备识别、音频路由与录音代码。
- `cmd/djonehub-macos/module_voice_public.go`：公开版的明确占位适配层；不携带模块侧语音运行时，并将通话音频能力报告为不可用。

## 公开范围约束

本仓库不包含任何模块侧语音内核二进制或其派生产物。因此可构建的公开版可以完成通话状态和控制，但不宣称可把 Mac 作为双向通话终端。

完整边界、已排除的文件和重新启用音频所需条件见 [OPEN_SOURCE_SCOPE.md](../OPEN_SOURCE_SCOPE.md)。
