-- hammerspoon 入口文件‘

require "modules/utils/stringUtils"
require "modules/utils/utils"
require "modules/shortcuts/hotkey"
require "modules/window/windows"
require "modules/weather/weather"
require "modules/bluetooth/blueutils"
require "modules/application/application"
require "modules/monitor/monitor"
require "modules/pasteboard/pasteboard"
require "modules/wifi/wifi"
require "modules/input_method/input_method"
require "modules/help/helps"

-- 绑定窗口吸附
BindWindowSnap()
-- 绑定窗口位置
BindWindowLocation()
-- 绑定窗口拓展功能
BndWindowExpand()
-- 绑定窗口切换屏幕
BindWindowMoveScreen()
-- 绑定窗口焦点切换
BindWindowFocusSwitch()

-- 天气组件
WeatherComponent = RegisterWeatherComponent()
WeatherComponent:start()

-- 绑定软件快捷键
BindApplicationShortcut()

-- 注册监控
Monitor = RegisterMonitor()
Monitor:start()

-- 注册剪贴板监控
PasteboardWatcher = RegisterPasteboardWatcher()
PasteboardWatcher:start()

-- 注册 wifi 监控
WifiWatcher = RegisterWifiWatcher()
WifiWatcher:start()

-- 注册帮助面板
RegisterHelpMenu()

-- 注册输入法提示
RemindCurrentInputMethod()
