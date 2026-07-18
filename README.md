# Hammerspoon Config

个人 macOS 自动化配置，基于 [hammerspoon-config](https://github.com/wangshub/hammerspoon-config) 持续调整。本文只列出 [`init.lua`](./init.lua) 当前已加载和启动的功能；实际运行还取决于本机配置与外部依赖是否有效。

## 当前功能

### 窗口与多屏控制

| 功能 | 快捷键 |
| --- | --- |
| 左 / 右 / 上 / 下半屏吸附 | `⌃⌥⌘ + 方向键` |
| 左上 / 右下 / 右上 / 左下角吸附 | `⌃⌥⇧ + 方向键` |
| 最大化或恢复原窗口尺寸 | `⌃⌥⌘ + M` |
| 切换 macOS 全屏 | `⌃⌥⌘ + F` |
| 窗口居中 | `⌃⌥⌘ + C` |
| 移动窗口到前 / 后屏幕 | `⌥⇧ + ← / →` |
| 移动窗口到屏幕 1 / 2 / 3 并最大化 | `⌥⇧ + 1 / 2 / 3` |
| 切换应用窗口 | `⌥⇧ + H` |
| 显示窗口提示（hints） | `⌥⇧ + /` |
| 聚焦前 / 后屏幕的窗口并移动光标 | `⌃⌥ + ← / →` |
| 仅将光标移动到下一个屏幕 | `⌘ + 反引号` |

全屏窗口跨屏时会先退出全屏，完成移动后恢复全屏状态。编号切屏目前支持屏幕 1～3。

### 应用快捷键

- 应用快捷键从 `config.applications` 读取，新增应用只需配置 `name`、`bundleId`、`modifiers` 和 `key` 后重载 Hammerspoon。
- `modifiers` 支持 `cmd`、`ctrl`、`alt`、`shift`；设置 `workModeOnly = true` 后只在工作模式启用。
- 快捷键帮助菜单会从同一配置自动生成，不需要同步修改代码或文档。

`config.example.lua` 当前配置的示例快捷键：

| 应用 | 快捷键 | 启用范围 |
| --- | --- | --- |
| Finder | `⌘ + E` | 始终可用 |
| Alacritty | `⌃⌥ + T` | 始终可用 |
| Edge | `⌃⌘ + G` | 始终可用 |
| VS Code | `⌃⌘ + V` | 工作模式 |
| Podcasts | `⌃⌘ + P` | 始终可用 |
| 音流 | `⌃⌘ + M` | 始终可用 |
| Codex | `⌃⌘ + Z` | 工作模式 |

- 完整配置示例见 [`config.example.lua`](./config.example.lua)。

### 工作 / 娱乐模式

- 使用 `⌃⌥⌘ + W` 手动切换，当前模式保存在 `hs.settings` 中，重载后继续保留。
- 周一至周六每分钟检查一次：08:30（含）～09:30（含）当天首次检查切换到工作模式，18:10（含）后当天首次检查切换到娱乐模式；错过上午时间窗口后当天不会自动进入工作模式，周日不自动切换。
- 当天是否已执行自动切换同样保存在 `hs.settings` 中，重载配置不会重复执行。
- 娱乐模式会保存并关闭四个 macOS 触发角，回到工作模式时恢复原设置。
- 设置了 `workModeOnly = true` 的应用快捷键只在工作模式启用。
- 屏幕休眠后的应用、蓝牙和 Wi-Fi 行为会根据当前模式区分处理。

### 休眠、唤醒与解锁

- 屏幕持续休眠 15 秒后：关闭“音流”App，并断开 `config.lua` 中配置的蓝牙设备。
- 娱乐模式下还会关闭微信、企业微信，并关闭蓝牙与 Wi-Fi；工作模式保留微信、企业微信以及蓝牙 / Wi-Fi 电源，但仍会断开配置的蓝牙设备。
- 屏幕唤醒 5 秒后，如果没有再次休眠，预先打开蓝牙与 Wi-Fi。
- 解锁后取消尚未执行的休眠 / 唤醒任务，立即打开蓝牙与 Wi-Fi，并启动 Scroll Reverser。
- 连续发生睡眠、唤醒或解锁事件时，过期的延迟任务会被跳过。

### Wi-Fi 与系统声音

- 监听公司和家庭 SSID。
- 连接公司 Wi-Fi 时，仅在默认输出设备为 Mac 内置扬声器时静音。
- 连接家庭 Wi-Fi 时，仅在默认输出设备为内置扬声器且当前静音时取消静音，并设置为 `config.wifi.home.volume`。
- Wi-Fi 配置缺失时自动停用 SSID 监听并显示通知，不影响其他模块加载。

### 蓝牙

- 通过 `blueutil` 开关蓝牙。
- 屏幕休眠时检查并断开 `config.bluetooth.devices` 中仍处于连接状态的设备。
- `blueutil` 路径或设备配置无效时停用蓝牙控制，并在 Hammerspoon Console 中说明原因。

### 天气菜单

- 启动时立即更新，之后每 10 分钟从[中国气象台](http://www.nmc.cn)获取实时天气和详细预报。
- 菜单栏显示天气、温度和更新时间；点击当天信息可打开配置的天气页面。
- 异步调用本地 Python 脚本生成天气景观图，并根据系统深色 / 浅色模式选用对应图片。
- 从预报 JSON 中检查未来 3 小时的雷暴、雨雪、雾、霾、沙尘等异常天气，并发送中文提醒；所有异常天气共用一个 3 小时冷却时间，冷却结束后仍有异常预报时可以再次提醒。
- 天气配置无效时仅停用天气组件，不阻止其他功能加载。

天气图片生成依赖 [weather_landscape](https://github.com/lds133/weather_landscape)。

### 剪贴板

- 自动去除新复制文本首尾的空白，并显示一次“复制”提示。
- 使用 `⌘⇧ + V` 打开最近 100 条文本历史；记录保存在 `hs.settings` 中，忽略空文本和连续重复内容。
- 普通选择会把内容放回剪贴板；按住 `⌥` 选择会直接输入文本，不改写当前剪贴板。
- 菜单底部可清空剪贴板及历史记录。

### 输入法与快捷键帮助

- 切换输入法时提示当前输入法名称，支持 ABC、中文、鼠须管和微信输入法。
- 使用 `⌃⌥⌘ + /` 在鼠标位置打开快捷键帮助菜单。

## 安装

### 1. 安装依赖

必需：

- [Hammerspoon](https://www.hammerspoon.org/)，并授予辅助功能权限；如需接收天气、网络和蓝牙通知，还需允许通知权限。

按启用功能选装：

- [`blueutil`](https://github.com/toy/blueutil)：蓝牙控制。
- Python 与 [weather_landscape](https://github.com/lds133/weather_landscape)：天气景观图和异常天气预报数据。
- `config.applications` 中配置的应用，以及休眠关闭或解锁启动所需的应用。

### 2. 安装配置

如果 `~/.hammerspoon/` 已存在，先备份：

```shell
mv ~/.hammerspoon ~/.hammerspoon_back_up
```

克隆仓库：

```shell
git clone https://github.com/zh826256645/hammerspoon_config.git ~/.hammerspoon
```

复制本机配置模板：

```shell
cp ~/.hammerspoon/config.example.lua ~/.hammerspoon/config.lua
```

`config.lua` 已加入 `.gitignore`，用于保存以下本机参数，不应写入密码或令牌：

| 配置 | 用途 |
| --- | --- |
| `applications` | 应用名称、Bundle ID、组合键、按键和工作模式限制 |
| `bluetooth.blueutilPath` | `blueutil` 可执行文件路径 |
| `bluetooth.devices` | 休眠时需要断开的蓝牙设备名称和 ID |
| `weather.*` | 城市、天气页面、Python、脚本目录、参数、预报 JSON 和深浅色图片路径 |
| `wifi.company` | 公司 SSID |
| `wifi.home` | 家庭 SSID 和恢复音量 |

填写完成后，在 Hammerspoon 中执行 `Reload Config`。如需停用功能，以 [`init.lua`](./init.lua) 为入口，同时移除对应模块的加载、注册和启动调用；休眠监控依赖应用、蓝牙和 Wi-Fi 控制，需要一起调整。

## 模块结构

| 模块 | 职责 |
| --- | --- |
| [`application`](./modules/application/application.lua) | 应用快捷键、打开和关闭应用 |
| [`computer_mode`](./modules/computer_mode/computer_mode.lua) | 工作 / 娱乐模式、定时切换和触发角 |
| [`window`](./modules/window/windows.lua) | 窗口吸附、尺寸、跨屏移动和屏幕焦点 |
| [`monitor`](./modules/monitor/monitor.lua) | 睡眠、唤醒、锁屏和解锁事件 |
| [`bluetooth`](./modules/bluetooth/blueutils.lua) | 蓝牙开关和设备断开 |
| [`wifi`](./modules/wifi/wifi.lua) | SSID 监听和系统声音 |
| [`weather`](./modules/weather/weather.lua) | 天气菜单、景观图和异常天气提醒 |
| [`pasteboard`](./modules/pasteboard/pasteboard.lua) | 复制文本清理 |
| [`history`](./modules/pasteboard/history.lua) | 剪贴板历史 |
| [`input_method`](./modules/input_method/input_method.lua) | 输入法切换提示 |
| [`help`](./modules/help/helps.lua) | 快捷键帮助菜单 |
| [`hotkey`](./modules/shortcuts/hotkey.lua) | 公共快捷键组合 |
| [`utils`](./modules/utils/utils.lua)、[`stringUtils`](./modules/utils/stringUtils.lua) | 公共工具函数 |

## 修改与验证

- 功能是否启用以 [`init.lua`](./init.lua) 中的加载、注册和启动调用为准。
- 修改后执行 `Reload Config`，检查 Hammerspoon Console 无新增错误，再验证受影响的快捷键或 watcher。
