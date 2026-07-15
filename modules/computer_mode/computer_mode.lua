-- 管理电脑工作/娱乐模式

local WorkMode = "work"
local EntertainmentMode = "entertainment"
local ModeSettingKey = "computerMode"

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

    hs.hotkey.bind(CmdCtrlAltHyper, 'W', function()
        controller:toggle()
    end)

    return controller
end
