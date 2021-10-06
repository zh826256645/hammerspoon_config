-- 窗口控制

local application = require "hs.application"
local hotkey = require "hs.hotkey"
local window = require "hs.window"
local layout = require "hs.layout"
local grid = require "hs.grid"
local hints = require "hs.hints"
local screen = require "hs.screen"
local alert = require "hs.alert"
local fnutils = require "hs.fnutils"
local geometry = require "hs.geometry"
local mouse = require "hs.mouse"

-- default 0.2
window.animationDuration = 0

-- 绑定窗口吸附
function BindWindowSnap()
    local settings = {
        {'leftSnap', CmdCtrlAltHyper, 'Left', layout.left50},
        {'rightSnap', CmdCtrlAltHyper, 'Right', layout.right50},
        {'topSnap', CmdCtrlAltHyper, 'Up', '[0,0,100,50]'},
        {'downSnap', CmdCtrlAltHyper, 'Down', '[0,50,100,100]'},
        {'upperleftSnap', ShiftCtrlAltHyper, 'Left', '[0,0,50,50]'},
        {'lowerRightSnap', ShiftCtrlAltHyper, 'Right', '[50,50,100,100]'},
        {'upperRightSnap', ShiftCtrlAltHyper, 'Up', '[50,0,100,50]'},
        {'lowerLeftSnap', ShiftCtrlAltHyper, 'Down', '[0,50,50,100]'},
    }
    for _, value in ipairs(settings) do
        hotkey.bind(value[1], value[2], function()
            if window.focusedWindow() then
                window.focusedWindow():moveToUnit(value[3])
            else
                alert.show("No active window")
            end
        end)
    end
end

-- 记住窗口原来的大小
-- 让窗口可以从最大的大小还原回原来的位置
local frameCache = {}
local function toggleMaximize()
    local win = window.focusedWindow()
    if frameCache[win:id()] then
        win:setFrame(frameCache[win:id()])
        frameCache[win:id()] = nil
    else
        frameCache[win:id()] = win:frame()
        win:maximize()
    end
end

-- 绑定窗口位置
function BindWindowLocation()
    -- 独占一个屏幕
    hotkey.bind(CmdCtrlAltHyper, 'F', function()
        window.focusedWindow():toggleFullScreen()
    end)

    -- 移至屏幕中心
    hotkey.bind(CmdCtrlAltHyper, 'C', function()
        window.focusedWindow():centerOnScreen()
    end)

    -- 最大的窗口大小
    hotkey.bind(CmdCtrlAltHyper, 'M', function()
        toggleMaximize()
    end)
end

-- 绑定窗口拓展功能
function BndWindowExpand()

    -- 显示切换到每个屏幕窗口的快捷键
    hotkey.bind(ShiftAltHyper, '/', function()
        hints.windowHints()
        -- Display current application window
        -- hints.windowHints(hs.window.focusedWindow():application():allWindows())
    end)

    -- 选择需要切换的窗口
    hotkey.bind(ShiftAltHyper, "H", function()
        window.switcher.nextWindow()
    end)
end

-- 讲窗口移动到指定屏幕
local moveto = function(win, n)
    local screens = screen.allScreens()
    if n > #screens then
        alert.show("Only " .. #screens .. " monitors ")
    else
        local toWin = screen.allScreens()[n]:name()
        alert.show("Move " .. win:application():name() .. " to " .. toWin)

        layout.apply({{nil, win:title(), toWin, layout.maximized, nil, nil}})

    end
end

-- 绑定窗口切换屏幕
function BindWindowMoveScreen()
    -- 移动窗口到前一个屏幕
    hotkey.bind(ShiftAltHyper, "Left", function()
        window.focusedWindow():moveOneScreenWest()
    end)

    -- 移动窗口到后一个屏幕
    hotkey.bind(ShiftAltHyper, "Right", function()
        window.focusedWindow():moveOneScreenEast()
    end)

    -- 将窗口移动到指定编号的窗口
    for number=1,3 do
        hotkey.bind(hyperShift, tostring(number), function()
            local win = window.focusedWindow()
            moveto(win, number)
        end)
    end
end

-- 判断是否在当前屏幕
local function isInScreen(switchScreen, win)
    return win:screen() == switchScreen
end

-- 移动窗口焦点
local function focusScreen(switchScreen)
    --Get windows within screen, ordered from front to back.
    --If no windows exist, bring focus to desktop. Otherwise, set focus on
    --front-most application window.
    local windows = fnutils.filter(
        window.orderedWindows(),
        fnutils.partial(isInScreen, switchScreen))
    local windowToFocus = #windows > 0 and windows[1] or window.desktop()
    windowToFocus:focus()

    -- 移动光标到屏幕中心
    local pt = geometry.rectMidPoint(switchScreen:fullFrame())
    mouse.setAbsolutePosition(pt)
end

-- 绑定窗口焦点切换
function BindWindowFocusSwitch()
    -- 移动鼠标焦点到上一个屏幕中的窗口
    hotkey.bind(CtrlAltHyper, "Left", function ()
        focusScreen(window.focusedWindow():screen():previous())
    end)

    -- 移动鼠标焦点到下一个屏幕中的窗口
    hotkey.bind(CtrlAltHyper, "Right", function ()
        focusScreen(window.focusedWindow():screen():next())
    end)

    -- 移动鼠标第 n 个屏幕
    hotkey.bind(CmdHyper, '`', function()
        local currentScreen = mouse.getCurrentScreen()
        local nextScreen = currentScreen:next()
        local rect = nextScreen:fullFrame()
        local center = geometry.rectMidPoint(rect)
        mouse.setAbsolutePosition(center)
    end)
end
