# My hammerspoon cofing

**Based on [hammerspoon-config](https://github.com/wangshub/hammerspoon-config)**

## Modules

[application](./modules/application.lua): controlling application program.

1. 关闭应用程序
2. 绑定 Finder 快捷键到 ⌘ + e
3. 绑定 Iterm2 快捷键到 ⌃ + ⌥ + t

[blueutils](./modules/blueutils.lua): controlling bluetooth device.

1. 链接/关闭蓝牙
2. 屏幕关闭后断开蓝牙连接
3. 使用时需要修改为自己的设备 ID

[helps](./modules/helps.lua): Tips in mac menubar.

[history](./modules/history.lua): Clipboard history.

[monitor](./modules/monitor.lua): Processing in various states.

1. 屏幕关闭后，关闭微信应用
2. 屏幕关闭后，断开蓝牙设置连接

[weather](./modules/weather.lua): Weather state in mac menubar.

1. 使用了 [中国气象台](http://www.nmc.cn) 和 [天气 API](https://www.tianqiapi.com) 的接口获取天气
2. 使用时，需要手动修改 CityID 和链接中的城市拼音

[windows](./modules/windows.lua): Hotkeys for window management.

[hotkey](./modules/hotkey.lua): Custom hotkey.

[utils](./modules/utils.lua): Tool function.

## Use

如果 `~/.hammerspoon/` 文件夹，先进行备份、移除

```shell script
mv ~/.hammerspoon/ ~/.hammerspoon_back_up/
```

拉取项目到 `~/.hammerspoon/` 下

```shell script
git clone https://github.com/zh826256645/hammerspoon_config.git ~/.hammerspoon/

```

让 hammerspoon `Reload Config` 进行配置文件重载

如果不需要某些功能，直接在 `init.lua` 中进行注释
