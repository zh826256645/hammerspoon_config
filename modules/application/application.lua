-- 处理应用

local applications = require("config").applications

local workModeHotkeys = {}
local sleepCloseApplications = {}
local entertainmentSleepCloseApplications = {}
local unlockOpenApplications = {}
local validModifiers = { cmd = true, ctrl = true, alt = true, shift = true }

if type(applications) ~= "table" then
    print("应用功能已停用: 缺少 config.applications 配置")
    applications = {}
end

local function hasShortcut(application)
    return application.modifiers ~= nil or application.key ~= nil
end

local function isValidApplication(application)
    if type(application) ~= "table"
        or type(application.name) ~= "string" or application.name == ""
        or type(application.bundleId) ~= "string" or application.bundleId == ""
        or (application.workModeOnly ~= nil and type(application.workModeOnly) ~= "boolean")
        or (application.closeOnSleep ~= nil and type(application.closeOnSleep) ~= "boolean")
        or (application.closeOnSleepInEntertainmentMode ~= nil and type(application.closeOnSleepInEntertainmentMode) ~= "boolean")
        or (application.openOnUnlock ~= nil and type(application.openOnUnlock) ~= "boolean") then
        return false
    end

    if not hasShortcut(application) then
        return application.workModeOnly ~= true
    end

    if type(application.modifiers) ~= "table" or type(application.key) ~= "string" or application.key == "" then
        return false
    end

    for _, modifier in ipairs(application.modifiers) do
        if not validModifiers[modifier] then
            return false
        end
    end

    return true
end

assert(isValidApplication({
    name = "App",
    bundleId = "com.example.app",
    modifiers = { "cmd" },
    key = "A",
    closeOnSleep = true,
}) and isValidApplication({ name = "App", bundleId = "com.example.app", openOnUnlock = true })
    and not isValidApplication({}) and not isValidApplication({
    name = "App",
    bundleId = "com.example.app",
    modifiers = { "cmd" },
    key = "A",
    closeOnSleep = "true",
}) and not isValidApplication({
    name = "App",
    bundleId = "com.example.app",
    workModeOnly = true,
}))

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

function CloseSleepApplications()
    for _, application in ipairs(sleepCloseApplications) do
        CloseApplication(application.bundleId, application.name)
    end
end

function CloseEntertainmentSleepApplications()
    for _, application in ipairs(entertainmentSleepCloseApplications) do
        CloseApplication(application.bundleId, application.name)
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

function OpenUnlockApplications()
    for _, application in ipairs(unlockOpenApplications) do
        OpenApplication(application.bundleId)
    end
end

-- 绑定程序
function BindApplicationShortcut(computerMode)
    local validShortcuts = {}

    for index, application in ipairs(applications) do
        if not isValidApplication(application) then
            print("忽略无效的应用配置: " .. tostring(index))
        else
            if application.closeOnSleep then
                table.insert(sleepCloseApplications, application)
            end
            if application.closeOnSleepInEntertainmentMode then
                table.insert(entertainmentSleepCloseApplications, application)
            end
            if application.openOnUnlock then
                table.insert(unlockOpenApplications, application)
            end
            if hasShortcut(application) then
                table.insert(validShortcuts, application)
                local hotkey = hs.hotkey.bind(application.modifiers, application.key, function()
                    hs.application.open(application.bundleId)
                    hs.timer.doAfter(0.3, function()
                        hs.alert.show(application.name, 0.8)
                    end)
                end)

                if application.workModeOnly then
                    table.insert(workModeHotkeys, hotkey)
                end
            end
        end
    end

    computerMode:onChange(function()
        SetWorkModeHotkeysEnabled(computerMode:isWorkMode())
    end)

    return validShortcuts
end
