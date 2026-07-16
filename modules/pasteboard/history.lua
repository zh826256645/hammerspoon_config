-- 粘贴板历史

local frequency = 0.8
local historySize = 100
local labelLength = 70
local settingsKey = "so.victor.hs.jumpcut"
local pasteboard = require "hs.pasteboard"
local settings = require "hs.settings"

local function truncateUtf8(value, maxCharacters)
    local endByte = utf8.offset(value, maxCharacters + 1)
    if endByte == nil then
        return value
    end
    return string.sub(value, 1, endByte - 1) .. "…"
end

local function addHistoryItem(history, value)
    if type(value) ~= "string" or value == "" or history[#history] == value then
        return false
    end

    while #history >= historySize do
        table.remove(history, 1)
    end
    table.insert(history, value)
    return true
end

do
    local sample = {}
    assert(addHistoryItem(sample, "test") and not addHistoryItem(sample, "test") and #sample == 1)
end

function RegisterClipboardHistory()
    local history = {}
    for _, value in ipairs(settings.get(settingsKey) or {}) do
        if type(value) == "string" and value ~= "" then
            table.insert(history, value)
        end
    end
    local lastChange = pasteboard.changeCount()
    local historyMenu = assert(hs.menubar.new(false), "创建粘贴板历史菜单失败")

    local function save()
        settings.set(settingsKey, history)
    end

    local function selectHistoryItem(value, modifiers)
        if modifiers.alt then
            hs.eventtap.keyStrokes(value)
            return
        end

        pasteboard.setContents(value)
        lastChange = pasteboard.changeCount()
    end

    local function clearHistory()
        pasteboard.clearContents()
        history = {}
        lastChange = pasteboard.changeCount()
        save()
    end

    historyMenu:setMenu(function()
        local items = {}
        for index = #history, 1, -1 do
            local value = history[index]
            table.insert(items, {
                title = truncateUtf8(value, labelLength),
                fn = function(modifiers)
                    selectHistoryItem(value, modifiers)
                end,
            })
        end

        if #items == 0 then
            table.insert(items, { title = "暂无记录", disabled = true })
        end
        table.insert(items, { title = "-" })
        table.insert(items, { title = "清空历史", fn = clearHistory })
        return items
    end)

    local historyTimer = hs.timer.new(frequency, function()
        local currentChange = pasteboard.changeCount()
        if currentChange == lastChange then
            return
        end

        lastChange = currentChange
        if addHistoryItem(history, pasteboard.getContents()) then
            save()
        end
    end)

    local historyHotkey = hs.hotkey.bind({ "cmd", "shift" }, "v", function()
        historyMenu:popupMenu(hs.mouse.absolutePosition())
    end)

    return {
        menu = historyMenu,
        hotkey = historyHotkey,
        start = function()
            historyTimer:start()
        end,
        stop = function()
            historyTimer:stop()
        end,
    }
end
