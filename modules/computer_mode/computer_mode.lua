-- 管理电脑工作/娱乐模式

local WorkMode = "work"
local EntertainmentMode = "entertainment"
local ModeSettingKey = "computerMode"
local MorningCheckedDateKey = "computerModeMorningCheckedDate"
local EveningCheckedDateKey = "computerModeEveningCheckedDate"
local HotCornerSnapshotSettingKey = "computerModeHotCornerSnapshot"
local DisabledHotCornerAction = 1
local DisabledHotCornerModifier = 0
local HotCorners = {
    { actionKey = "wvous-tl-corner", modifierKey = "wvous-tl-modifier" },
    { actionKey = "wvous-tr-corner", modifierKey = "wvous-tr-modifier" },
    { actionKey = "wvous-bl-corner", modifierKey = "wvous-bl-modifier" },
    { actionKey = "wvous-br-corner", modifierKey = "wvous-br-modifier" },
}

local function readDockSetting(key)
    local output, success = hs.execute("/usr/bin/defaults read com.apple.dock " .. key)
    return success and tonumber(output) or false
end

local function hotCornerSettingsForMode(mode, savedSettings)
    local settings = {}
    for index, corner in ipairs(HotCorners) do
        settings[index] = mode == EntertainmentMode
            and { action = DisabledHotCornerAction, modifier = DisabledHotCornerModifier }
            or {
                action = savedSettings[corner.actionKey] or DisabledHotCornerAction,
                modifier = savedSettings[corner.modifierKey] or DisabledHotCornerModifier,
            }
    end
    return settings
end

local disabledSettings = hotCornerSettingsForMode(EntertainmentMode, {})
local restoredSettings = hotCornerSettingsForMode(WorkMode, {
    ["wvous-tr-corner"] = 5,
    ["wvous-tr-modifier"] = 131072,
})
assert(disabledSettings[2].action == DisabledHotCornerAction
    and disabledSettings[2].modifier == DisabledHotCornerModifier
    and restoredSettings[2].action == 5
    and restoredSettings[2].modifier == 131072)

local function applyHotCornerSettings(settings)
    local calls = {}
    for index, setting in ipairs(settings) do
        if type(setting.action) ~= "number" or type(setting.modifier) ~= "number" then
            print("忽略无效的触发角设置: " .. tostring(index))
            return false
        end
        table.insert(calls, string.format(
            "$.CoreDockSetExposeCornerActionWithModifier(%d, %d, %d);",
            setting.action,
            index - 1,
            setting.modifier
        ))
    end

    local script = [=[
ObjC.import("ApplicationServices");
ObjC.bindFunction("CoreDockSetExposeCornerActionWithModifier", ["void", ["int", "int", "int"]]);
]=] .. table.concat(calls, "\n")
    local success, _, details = hs.osascript.javascript(script)
    if not success then
        print("更新触发角失败: " .. hs.inspect(details))
    end
    return success
end

local function updateHotCornersForMode(mode)
    local savedSettings = hs.settings.get(HotCornerSnapshotSettingKey)

    if mode == EntertainmentMode and savedSettings == nil then
        savedSettings = {}
        for _, corner in ipairs(HotCorners) do
            savedSettings[corner.actionKey] = readDockSetting(corner.actionKey)
            savedSettings[corner.modifierKey] = readDockSetting(corner.modifierKey)
        end
        hs.settings.set(HotCornerSnapshotSettingKey, savedSettings)
    elseif mode == WorkMode and savedSettings == nil then
        return
    end

    local snapshotUpdated = false
    for _, corner in ipairs(HotCorners) do
        if savedSettings[corner.modifierKey] == nil then
            savedSettings[corner.modifierKey] = readDockSetting(corner.modifierKey)
            snapshotUpdated = true
        end
    end
    if snapshotUpdated then
        hs.settings.set(HotCornerSnapshotSettingKey, savedSettings)
    end

    if applyHotCornerSettings(hotCornerSettingsForMode(mode, savedSettings)) and mode == WorkMode then
        hs.settings.clear(HotCornerSnapshotSettingKey)
    end
end

local function scheduledMode(now)
    local weekday = tonumber(os.date("%w", now))
    local minutes = tonumber(os.date("%H", now)) * 60 + tonumber(os.date("%M", now))

    if weekday == 0 then
        return nil
    elseif minutes >= 18 * 60 + 10 then
        return EntertainmentMode, EveningCheckedDateKey
    elseif minutes >= 8 * 60 + 30 and minutes <= 9 * 60 + 30 then
        return WorkMode, MorningCheckedDateKey
    end
end

assert(scheduledMode(os.time({ year = 2026, month = 7, day = 13, hour = 8, min = 30 })) == WorkMode
    and scheduledMode(os.time({ year = 2026, month = 7, day = 13, hour = 18, min = 10 })) == EntertainmentMode
    and scheduledMode(os.time({ year = 2026, month = 7, day = 12, hour = 18, min = 10 })) == nil)

function RegisterComputerMode()
    local listeners = {}
    local currentMode = hs.settings.get(ModeSettingKey)

    if currentMode ~= WorkMode and currentMode ~= EntertainmentMode then
        currentMode = hs.settings.get("workModeEnabled") == false and EntertainmentMode or WorkMode
        hs.settings.set(ModeSettingKey, currentMode)
    end

    local controller = {}

    function controller:getMode()
        return currentMode
    end

    function controller:isWorkMode()
        return currentMode == WorkMode
    end

    function controller:onChange(listener)
        table.insert(listeners, listener)
        listener(currentMode)
    end

    function controller:setMode(mode)
        if mode ~= WorkMode and mode ~= EntertainmentMode then
            error("不支持的电脑模式: " .. tostring(mode))
        end
        if mode == currentMode then
            return
        end

        currentMode = mode
        hs.settings.set(ModeSettingKey, currentMode)
        for _, listener in ipairs(listeners) do
            listener(currentMode)
        end
        hs.alert.show(currentMode == WorkMode and "工作模式" or "娱乐模式", 1)
    end

    function controller:toggle()
        self:setMode(self:isWorkMode() and EntertainmentMode or WorkMode)
    end

    controller:onChange(updateHotCornersForMode)

    hs.hotkey.bind(CmdCtrlAltHyper, 'W', function()
        controller:toggle()
    end)

    local function checkScheduledMode()
        local now = os.time()
        local mode, checkedDateKey = scheduledMode(now)
        local today = os.date("%Y-%m-%d", now)

        if mode ~= nil and hs.settings.get(checkedDateKey) ~= today then
            hs.settings.set(checkedDateKey, today)
            controller:setMode(mode)
        end
    end

    checkScheduledMode()
    controller.scheduleTimer = hs.timer.doEvery(60, checkScheduledMode)

    return controller
end
