# My hammerspoon cofing

**Based on [hammerspoon-config](https://github.com/wangshub/hammerspoon-config)**

## Modules

[application](./modules/application/application.lua): 控制应用程序
- 关闭应用程序
- 绑定 Finder 快捷键到 ⌘ + e
- 绑定 Iterm2 快捷键到 ⌃ + ⌥ + t
- 绑定 QQ 快捷键到 ⌃ + ⌘ + z
- 绑定 Chrome 快捷键到 ⌃ + ⌘ + g
- 绑定 VS Code 快捷键到 ⌃ + ⌘ + v
- 绑定 Notion 快捷键到 ⌃ + ⌘ + n
- 绑定 Netease 快捷键到 ⌃ + ⌘ + w
- 绑定 Reeder 快捷键到 ⌃ + ⌘ + r

[blueutils](./modules/bluetooth/blueutils.lua): 控制蓝牙
- 链接/关闭蓝牙
- 屏幕休眠后断开蓝牙连接以及微信
- 屏幕唤醒后打开蓝牙

[helps](./modules/help/helps.lua): 帮助菜单

[history](./modules/pasteboard/history.lua): 粘贴板历史记录

[pasteboard](./modules/pasteboard/pasteboard.lua): 粘贴板数据处理
- 去除复制的字符串左右两边的空格

[monitor](./modules/monitor/monitor.lua): 监控系统的状态，在不同的状态下进行不同的处理
- 屏幕关闭后，关闭微信应用
- 屏幕关闭后，断开蓝牙设置连接
- 解锁后打开微信

[weather](./modules/weather/weather.lua): 天气组件
- 使用了 [中国气象台](http://www.nmc.cn) 和 [天气 API](https://www.tianqiapi.com) 的接口获取天气
- 使用时，需要手动修改 CityID 和链接中的城市拼音

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
- 最大化 ^ + ⌥ + ⌘ + M
- 全屏幕 ^ + ⌥ + ⌘ + F
- 屏幕居中 ^ + ⌥ + ⌘ + C

[hotkey](./modules/shortcuts/hotkey.lua): 定义快捷键

[utils](./modules/utils.lua): 工具函数

## Use

如果存在 `~/.hammerspoon/` 文件夹，先进行备份、移除

```shell script
mv ~/.hammerspoon/ ~/.hammerspoon_back_up/
```

拉取项目到 `~/.hammerspoon/` 下

```shell script
git clone https://github.com/zh826256645/hammerspoon_config.git ~/.hammerspoon/

```

让 hammerspoon `Reload Config` 进行配置文件重载

如果不需要某些功能，直接在 [init.lua](init.lua) 中进行注释
