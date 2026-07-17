-- 管理电脑工作/娱乐模式

local WorkMode = "work"
local EntertainmentMode = "entertainment"
local ModeSettingKey = "computerMode"
local MorningCheckedDateKey = "computerModeMorningCheckedDate"
local EveningCheckedDateKey = "computerModeEveningCheckedDate"
local HotCornerSnapshotSettingKey = "computerModeHotCornerSnapshot"
local HotCornerKeys = {
    "wvous-tl-corner",
    "wvous-tr-corner",
    "wvous-bl-corner",
    "wvous-br-corner",
}

local function readHotCorner(key)
    local output, success = hs.execute("/usr/bin/defaults read com.apple.dock " .. key)
    return success and tonumber(output) or false
end

local function writeHotCorner(key, value)
    if value ~= false and type(value) ~= "number" then
        print("忽略无效的触发角设置: " .. key)
        return false
    end

    local command = value == false
        and "/usr/bin/defaults delete com.apple.dock " .. key
        or string.format("/usr/bin/defaults write com.apple.dock %s -int %d", key, value)
    local output, success = hs.execute(command)
    success = success or (value == false and readHotCorner(key) == false)
    if not success then
        print("更新触发角失败 (" .. key .. "): " .. tostring(output))
    end
    return success
end

local function hotCornerValueForMode(mode, savedSettings, key)
    return mode == EntertainmentMode and 0 or savedSettings[key]
end

assert(hotCornerValueForMode(EntertainmentMode, {}, "corner") == 0
    and hotCornerValueForMode(WorkMode, { corner = 5 }, "corner") == 5)

local function updateHotCornersForMode(mode)
    local savedSettings = hs.settings.get(HotCornerSnapshotSettingKey)

    if mode == EntertainmentMode and savedSettings == nil then
        savedSettings = {}
        for _, key in ipairs(HotCornerKeys) do
            savedSettings[key] = readHotCorner(key)
        end
        hs.settings.set(HotCornerSnapshotSettingKey, savedSettings)
    elseif mode == WorkMode and savedSettings == nil then
        return
    end

    local success = true
    for _, key in ipairs(HotCornerKeys) do
        success = writeHotCorner(key, hotCornerValueForMode(mode, savedSettings, key)) and success
    end

    if success and mode == WorkMode then
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
