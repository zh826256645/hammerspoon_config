# My hammerspoon config

**Based on [hammerspoon-config](https://github.com/wangshub/hammerspoon-config)**

## Modules

[application](./modules/application/application.lua): 控制应用程序
- 绑定 Finder 快捷键到 ⌘ + E
- 绑定 Alacritty 快捷键到 ⌃ + ⌥ + T
- 绑定 Chrome（Edge）快捷键到 ⌃ + ⌘ + G
- 工作模式下绑定 VS Code 快捷键到 ⌃ + ⌘ + V
- 绑定 Launchpad 快捷键到 ⌃ + ⌘ + L
- 绑定 Notion 快捷键到 ⌃ + ⌘ + N
- 绑定 Reeder 快捷键到 ⌃ + ⌘ + R
- 绑定 Podcasts 快捷键到 ⌃ + ⌘ + P
- 工作模式下绑定 Codex 快捷键到 ⌃ + ⌘ + Z

[computer_mode](./modules/computer_mode/computer_mode.lua): 管理电脑工作/娱乐模式
- 使用 ⌃ + ⌥ + ⌘ + W 切换模式
- 模式状态会在 Hammerspoon 重载后保留
- 周一至周六 08:30–09:30 检查一次并切换到工作模式，18:10 后检查一次并切换到娱乐模式
- 娱乐模式下关闭 macOS 触发角，切回工作模式时恢复原设置
- 其他模块可通过 `onChange` 响应模式变化

[blueutils](./modules/bluetooth/blueutils.lua): 控制蓝牙
- 断开 `config.lua` 中配置的蓝牙设备
- 开关蓝牙
- 屏幕休眠后断开蓝牙设备

[helps](./modules/help/helps.lua): 快捷键帮助
- 使用 ⌃ + ⌥ + ⌘ + / 显示帮助菜单

[history](./modules/pasteboard/history.lua): 粘贴板历史记录
- ⌘ + ⇧ + V 弹出粘贴板历史菜单
- 默认保存最近 100 条文本记录，Option 选择可直接输入

[pasteboard](./modules/pasteboard/pasteboard.lua): 粘贴板数据处理
- 去除复制的字符串左右两边的空格

[monitor](./modules/monitor/monitor.lua): 监控系统状态，在不同状态下进行不同处理
- 屏幕休眠 15 秒后：关闭音流并断开蓝牙设备；娱乐模式下同时关闭微信、企业微信、蓝牙与 Wi-Fi
- 屏幕唤醒 5 秒后：预打开蓝牙与 Wi-Fi
- 解锁后：立即打开蓝牙与 Wi-Fi，打开 ScrollReverser

[weather](./modules/weather/weather.lua): 天气组件
- 使用 [中国气象台](http://www.nmc.cn) 接口获取实时天气和详细预报
- 通过 Python 脚本处理 OpenWeatherMap 预报数据，生成天气景观图
- 天气图片生成依赖 [weather_landscape](https://github.com/lds133/weather_landscape) 项目
- 异常天气提醒（雷暴、雾、霾、沙尘等）
- 城市、本地 Python 和图片路径从 `config.lua` 读取

[windows](./modules/windows/windows.lua): 绑定窗口控制的快捷键
- 左吸附 ^ + ⌥ + ⌘ + ←
- 右吸附 ^ + ⌥ + ⌘ + →
- 上吸附 ^ + ⌥ + ⌘ + ↑
- 下吸附 ^ + ⌥ + ⌘ + ↓
- 左上角吸附 ^ + ⌥ + ⇧ + ←
- 右下角吸附 ^ + ⌥ + ⇧ + →
- 右上角吸附 ^ + ⌥ + ⇧ + ↑
- 左下角吸附 ^ + ⌥ + ⇧ + ↓
- 到上个屏幕 ⌥ + ⇧ + ←
- 到下个屏幕 ⌥ + ⇧ + →
- 移动窗口到屏幕 1/2/3 ⌥ + ⇧ + 1/2/3
- 最大化 ^ + ⌥ + ⌘ + M
- 全屏幕 ^ + ⌥ + ⌘ + F
- 屏幕居中 ^ + ⌥ + ⌘ + C
- 切换应用窗口 ⌥ + ⇧ + H
- 窗口提示（hints）⌥ + ⇧ + /
- 窗口焦点到上个屏幕 ⌃ + ⌥ + ←
- 窗口焦点到下个屏幕 ⌃ + ⌥ + →
- 移动光标到下个屏幕 ⌘ + `

[wifi](./modules/wifi/wifi.lua): Wi-Fi 配置自动切换
- 根据 `config.lua` 中的公司/家庭 SSID 自动切换代理配置与系统音量
- 开关 Wi-Fi

[input_method](./modules/input_method/input_method.lua): 输入法提示
- 切换输入法时显示当前输入法名称（ABC / 中文 / 鼠须管 / 微信输入法）

[hotkey](./modules/shortcuts/hotkey.lua): 定义快捷键组合

[utils](./modules/utils/utils.lua): 工具函数（日期格式化、打印 Table、Sleep）
[stringUtils](./modules/utils/stringUtils.lua): 字符串工具（split、strip、lstrip、rstrip）

## Use

如果存在 `~/.hammerspoon/` 文件夹，先进行备份、移除

```shell script
mv ~/.hammerspoon/ ~/.hammerspoon_back_up/
```

拉取项目到 `~/.hammerspoon/` 下

```shell script
git clone https://github.com/zh826256645/hammerspoon_config.git ~/.hammerspoon/

```

复制配置模板并填写本机值：

```shell script
cp ~/.hammerspoon/config.example.lua ~/.hammerspoon/config.lua
```

`config.lua` 已加入 `.gitignore`，用于保存 Wi-Fi、蓝牙设备和天气脚本等本机配置，不会提交到公开仓库。

外部依赖：

- Hammerspoon
- `blueutil`（蓝牙控制）
- Sparkle 或支持 `PUT /configs` 的 Mihomo/Clash（代理配置切换）
- Python 与 `weather_landscape`（天气景观图，可选）

让 hammerspoon `Reload Config` 进行配置文件重载

如果不需要某些功能，直接在 [init.lua](init.lua) 中进行注释

## Governance

项目整理与后续改动规则见 [Hammerspoon 配置治理方案](./GOVERNANCE.md)。
