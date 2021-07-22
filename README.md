# My hammerspoon cofing

**Based on [hammerspoon-config](https://github.com/wangshub/hammerspoon-config)**

## Modules

[application](./modules/application.lua): controlling application program.

- 关闭应用程序
- 绑定 Finder 快捷键到 ⌘ + e
- 绑定 Iterm2 快捷键到 ⌃ + ⌥ + t
- 绑定体验版 QQ 快捷键到 ⌃ + ⌘ + z
- 绑定 Chrome 快捷键到 ⌃ + ⌘ + g
- 绑定 VS Code 快捷键到 ⌃ + ⌘ + v

[blueutils](./modules/blueutils.lua): controlling bluetooth device.

- 链接/关闭蓝牙
- 屏幕休眠后断开蓝牙连接以及微信
- 屏幕唤醒后打开蓝牙

[helps](./modules/helps.lua): Tips in mac menubar.

[history](./modules/history.lua): Clipboard history.

[monitor](./modules/monitor.lua): Processing in various states.

- 屏幕关闭后，关闭微信应用
- 屏幕关闭后，断开蓝牙设置连接

[weather](./modules/weather.lua): Weather state in mac menubar.

- 使用了 [中国气象台](http://www.nmc.cn) 和 [天气 API](https://www.tianqiapi.com) 的接口获取天气
- 使用时，需要手动修改 CityID 和链接中的城市拼音

[windows](./modules/windows.lua): Hotkeys for window management.

[hotkey](./modules/hotkey.lua): Custom hotkey.

[pasteboard](./modules/pasteboard.lua): Removes Spaces at the beginning and end of clipboard characters.

[utils](./modules/utils.lua): Tool function.

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
