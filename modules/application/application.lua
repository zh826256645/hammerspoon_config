-- 处理应用

local applicationShortcuts = require("config").applications

TheWeChatBundleID = "com.tencent.xinWeChat"
TheWeWorkBundleID = "com.tencent.WeWorkMac"
TheScrollReverserID = "com.pilotmoon.scroll-reverser"
TheYinLiuBundleID = "cn.aqzscn.streamMusic"

local workModeHotkeys = {}
local validModifiers = { cmd = true, ctrl = true, alt = true, shift = true }

if type(applicationShortcuts) ~= "table" then
    print("应用快捷键已停用: 缺少 config.applications 配置")
    applicationShortcuts = {}
end

local function isValidApplicationShortcut(shortcut)
    if type(shortcut) ~= "table"
        or type(shortcut.name) ~= "string" or shortcut.name == ""
        or type(shortcut.bundleId) ~= "string" or shortcut.bundleId == ""
        or type(shortcut.modifiers) ~= "table"
        or type(shortcut.key) ~= "string" or shortcut.key == ""
        or (shortcut.workModeOnly ~= nil and type(shortcut.workModeOnly) ~= "boolean") then
        return false
    end

    for _, modifier in ipairs(shortcut.modifiers) do
        if not validModifiers[modifier] then
            return false
        end
    end

    return true
end

assert(isValidApplicationShortcut({
    name = "App",
    bundleId = "com.example.app",
    modifiers = { "cmd" },
    key = "A",
}) and not isValidApplicationShortcut({}))

local function SetWorkModeHotkeysEnabled(enabled)
    for _, hotkey in ipairs(workModeHotkeys) do
        if enabled then
            hotkey:enable()
        else
            hotkey:disable()
        end
    end
end

-- 关闭程序
function CloseApplication(bundleID, appName)
    local application = hs.application.applicationsForBundleID(bundleID)
    application = application[1]

    if application ~= nil and application:isRunning() then
        local name = appName or string.split(bundleID, '.')[3]
        print("关闭 " .. name .. " 程序")
        application:kill()
    end
end

-- 开启程序
function OpenApplication(bundleID)
    local application = hs.application.applicationsForBundleID(bundleID)
    application = application[1]
    if application == nil or not application:isRunning() then
        local name = string.split(bundleID, '.')[3]
        print("开启 " .. name .. " 程序")
        hs.application.open(bundleID)
    end
end

-- 绑定程序
function BindApplicationShortcut(computerMode)
    local validShortcuts = {}

    for index, shortcut in ipairs(applicationShortcuts) do
        if not isValidApplicationShortcut(shortcut) then
            print("忽略无效的应用快捷键配置: " .. tostring(index))
        else
            table.insert(validShortcuts, shortcut)
            local hotkey = hs.hotkey.bind(shortcut.modifiers, shortcut.key, function()
                hs.application.open(shortcut.bundleId)
                hs.timer.doAfter(0.3, function()
                    hs.alert.show(shortcut.name, 0.8)
                end)
            end)

            if shortcut.workModeOnly then
                table.insert(workModeHotkeys, hotkey)
            end
        end
    end

    computerMode:onChange(function()
        SetWorkModeHotkeysEnabled(computerMode:isWorkMode())
    end)

    return validShortcuts
end
