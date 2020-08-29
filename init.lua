-- Set hyper to ctrl + alt + cmd + shift
--[[
local hyper      = {'ctrl', 'cmd', 'alt', 'shift'}

-- Move Mouse to center of next Monitor
hs.hotkey.bind(hyper, '`', function()
    local screen = hs.mouse.getCurrentScreen()
    local nextScreen = screen:next()
    local rect = nextScreen:fullFrame()
    local center = hs.geometry.rectMidPoint(rect)

    hs.mouse.setAbsolutePosition(center)
end)
]]
require "modules/utils"
require "modules/hotkey"
require "modules/windows"
require "modules/weather"
require "modules/blueutils"
require "modules/application"
require "modules/monitor"
-- require "modules/history"
require "modules/wifi"
require "modules/helps"
