-- hammerspoon 入口文件‘

local configLoaded, configError = pcall(require, "config")
assert(configLoaded, "无法加载 config.lua，请复制 config.example.lua 并填写本机配置: " .. tostring(configError))

require "modules/utils/stringUtils"
require "modules/utils/utils"
require "modules/shortcuts/hotkey"
require "modules/computer_mode/computer_mode"
require "modules/window/windows"
require "modules/weather/weather"
require "modules/bluetooth/blueutils"
require "modules/application/application"
require "modules/monitor/monitor"
require "modules/pasteboard/pasteboard"
require "modules/pasteboard/history"
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
if WeatherComponent ~= nil then
    WeatherComponent:start()
end

-- 注册电脑模式
ComputerMode = RegisterComputerMode()

-- 绑定软件快捷键
BindApplicationShortcut(ComputerMode)

-- 注册监控
Monitor = RegisterMonitor()
Monitor:start()

-- 注册剪贴板监控
PasteboardWatcher = RegisterPasteboardWatcher()
PasteboardWatcher:start()

-- 注册剪贴板历史
ClipboardHistory = RegisterClipboardHistory()
ClipboardHistory:start()

-- 注册 wifi 监控
WifiWatcher = RegisterWifiWatcher()
if WifiWatcher ~= nil then
    WifiWatcher:start()
end

-- 注册帮助快捷键
HelpMenu = RegisterHelpMenu()

-- 注册输入法提示
RemindCurrentInputMethod()
