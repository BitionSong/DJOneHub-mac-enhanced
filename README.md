# DJOneHub

> 让大疆第一代 4G 模块成为 Mac 上长期可用的实体 SIM 终端。

DJOneHub 是一个非官方开源项目。它通过模块已有 USB 接口提供短信、4G、GPS、eSIM、来电及通话控制，不修改模块固件。

## v1.2.9：v1.2.5 — v1.2.9 更新汇总

[下载 v1.2.9](https://github.com/rogerbush007-a11y/DJOneHub-mac-enhanced/releases/tag/v1.2.9)

### 通话与首次启用

- 独立 macOS App 集中管理拨号、接听、拒接、挂断、DTMF、通话记录、录音入口、短信、通讯录与设置；来电、短信提醒不需要网页常驻。
- 新模块、原始 DJI 配置、旧 UAC 与其他工具留下的完整 USB 配置均可识别。启用前先备份，验证失败自动回滚。
- 旧 UAC `…1,1,1,1,1,0,1` 已具备 USB Audio，不再强写 ADB 位，只补 IMS / VoLTE，避免模块返回 `OK` 但配置保持原样时误报失败。
- USB 模式切换、模块重启和重新枚举期间的临时 `USBCFG ERROR` 会自动重试；重新连接后会读取实际配置，不会沿用旧“已就绪”状态。

### 语音运行时

- 首次在「设置 → 语音运行时」确认后，App 从固定上游获取指定版本并校验 SHA-256，缓存到本机；后续模块重启或重插可复用缓存。
- 下载包含 Raw → GitHub Contents API → Raw 重试链路，并使用独立等待窗口，避免上游短暂失败或通用接口超时造成初始化中断。
- 模块侧语音运行时不包含在源码、DMG、ZIP 或 Release 中。

### iPhone / iPad 模式与发布包

- 「设置 → 连接模式」可切换 iPhone / iPad 模式：仅关闭 USB Audio，保留 USB 4G、AT 与短信，避免移动设备占用系统音频输出；接回运行 DJOneHub 的 Mac 后会恢复完整音频接口。
- 修复安装包误带入旧通知 App、设置页遗留固定版本号及连接模式入口缺失的问题。
- v1.2.9 同步提供 macOS Universal（Apple Silicon + Intel）和 Windows x64（含 `DJOneHub.exe`）安装包；Windows 仍未完成真实模块验证。

| 功能 | 说明 |
| --- | --- |
| 电话 | 拨号、接听、拒接、挂断、DTMF、通话记录和录音入口。 |
| 短信 | 收发短信、验证码预览；读取后可自动清理模块存储。 |
| 通讯录 | 可同步本机通讯录，用姓名或号码拨号、发短信。 |
| 网络与 GPS | USB 4G、Wi-Fi 优先、4G 兜底、GPS/GNSS 状态与菜单栏提示。 |
| iPhone / iPad 模式 | 关闭 USB Audio、保留上网和短信；下次接回 Mac 自动恢复完整模式。 |
| 模块工具 | eUICC Profile、AT 调试、网络诊断和初始化状态。 |

## 界面预览

> 以下均为真实界面截图；号码、联系人、头像、验证码和时间已遮蔽。

### 电话

<p align="center">
  <img src="docs/images/v1.2.4/dial-pad-empty.png" alt="拨号界面" width="31%" />
  <img src="docs/images/v1.2.4/call-dialing.png" alt="正在拨号" width="31%" />
  <img src="docs/images/v1.2.4/call-active.png" alt="通话中" width="31%" />
</p>

拨号、接听、拒接、挂断、DTMF、通话记录与录音入口统一在电话页。

<p align="center">
  <img src="docs/images/v1.2.4/call-history.png" alt="通话记录" width="48%" />
  <img src="docs/images/v1.2.4/incoming-call-notification.png" alt="来电通知" width="38%" />
</p>

### 短信与通讯录

<p align="center">
  <img src="docs/images/v1.2.4/sms-compose.png" alt="短信编辑" width="45%" />
  <img src="docs/images/v1.2.4/contacts.png" alt="通讯录" width="45%" />
</p>

短信支持收发、验证码预览和自动清理；通讯录可同步本机联系人并用于检索。

<p align="center">
  <img src="docs/images/v1.2.4/sms-notification.png" alt="短信通知" width="44%" />
</p>

### 设置与版本

<p align="center">
  <img src="docs/images/v1.2.4/about.png" alt="关于页" width="42%" />
</p>

## 下载与平台状态

| 平台 | 包 | 当前状态 |
| --- | --- | --- |
| macOS 13+ | `DJOneHub-macOS-universal-v1.2.9.dmg` | Apple Silicon 实机验证；包内含 arm64 + x86_64，Intel 尚未真机验证。 |
| Windows x86-64 | `DJOneHub-Windows-amd64-v1.2.9.zip` | 内含 `DJOneHub.exe`；尚未在真实 Windows + 模块上验证。 |

Windows 目前不承诺模块功能可用；它不提供 macOS 专用的 USB AT/eSIM、USB 4G 自动策略、原生通知、MapKit 或双向通话音频。

## macOS 安装

1. 打开 DMG，运行“安装 DJOneHub.command”。
2. 日常直接打开 DJOneHub App；也可在安装目录运行 `djonehub start`。

本地服务只监听 `127.0.0.1:7575`。首次通话时，App 会请求麦克风权限。

## 通话与开源边界

源码包含 macOS App、Go 后端、Windows 控制台、MaVo MIT 音频适配代码和构建脚本。

Mac 双向通话仍需要模块侧语音运行时。该运行时**不随本仓库、Release、DMG 或 Windows ZIP 提供，也不会由 DJOneHub 镜像**。用户一次明确确认后，App 才会从固定上游来源获取指定版本，逐项校验 SHA-256 后保存到本机。上游文件、模块型号、固件、SIM 和运营商条件均可能影响双向语音可用性。

请不要把未知来源的二进制提交到 Issue、PR 或衍生 Release。完整边界见 [OPEN_SOURCE_SCOPE.md](OPEN_SOURCE_SCOPE.md)。

## 从源码构建

```sh
# macOS Universal
scripts/package-macos-universal.sh v1.2.9
scripts/build-dmg-universal.sh v1.2.9

# Windows x86-64
scripts/package-windows-amd64.sh v1.2.9
```

构建 macOS 包需要完整 Xcode、Go、`pkg-config` 与网络下载官方 libusb 源码。Windows 包在 Mac 上只能交叉编译，不能替代 Windows 真机验证。

## 使用提醒

- 使用蜂窝数据、短信、通话与 eSIM 前，请确认运营商协议、资费及当地法律要求。
- GPS 默认关闭；定位信息仅在本机读取和展示。
- 本项目不会上传 SIM、短信、联系人、录音或卡片资料。
- 与 DJI、Quectel、运营商及 eSIM 厂商不存在隶属或授权关系。

许可证与第三方声明见 [LICENSE](LICENSE)、[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) 与 [OPEN_SOURCE_SCOPE.md](OPEN_SOURCE_SCOPE.md)。
