-- 快捷键说明

local modifierOrder = { "ctrl", "alt", "shift", "cmd" }
local modifierSymbols = { ctrl = "⌃", alt = "⌥", shift = "⇧", cmd = "⌘" }
local applicationMenu = {}

local function formatShortcut(modifiers, key)
    local enabledModifiers = {}
    local symbols = {}

    for _, modifier in ipairs(modifiers) do
        enabledModifiers[modifier] = true
    end
    for _, modifier in ipairs(modifierOrder) do
        if enabledModifiers[modifier] then
            table.insert(symbols, modifierSymbols[modifier])
        end
    end

    return table.concat(symbols) .. string.upper(key)
end

assert(formatShortcut({ "cmd", "ctrl" }, "g") == "⌃⌘G")

local menuData = {
    {
        title = "窗口快捷键",
        menu = {
            { title = "左/右/上/下吸附              ⌃⌥⌘ + 方向键" },
            { title = "四角吸附                         ⌃⌥⇧ + 方向键" },
            { title = "最大化                             ⌃⌥⌘M" },
            { title = "全屏                                ⌃⌥⌘F" },
            { title = "居中                                ⌃⌥⌘C" },
            { title = "移动到前/后屏幕                 ⌥⇧ + ←/→" },
            { title = "移动到屏幕 1/2/3                ⌥⇧ + 1/2/3" },
            { title = "切换应用窗口                      ⌥⇧H" },
            { title = "窗口提示                           ⌥⇧/" },
        },
    },
    { title = "-" },
    {
        title = "应用快捷键",
        menu = applicationMenu,
    },
    { title = "-" },
    {
        title = "其他快捷键",
        menu = {
            { title = "切换工作/娱乐模式               ⌃⌥⌘W" },
            { title = "粘贴板历史                        ⌘⇧V" },
            { title = "显示本帮助                        ⌃⌥⌘/" },
        },
    },
}

function RegisterHelpMenu(applicationShortcuts)
    for _, shortcut in ipairs(applicationShortcuts) do
        local mode = shortcut.workModeOnly and "（工作模式）" or ""
        table.insert(applicationMenu, {
            title = shortcut.name .. mode .. "    " .. formatShortcut(shortcut.modifiers, shortcut.key),
        })
    end

    local helpMenu = assert(hs.menubar.new(false), "创建帮助菜单失败")
    helpMenu:setMenu(menuData)

    local helpHotkey = hs.hotkey.bind(CmdCtrlAltHyper, "/", function()
        helpMenu:popupMenu(hs.mouse.absolutePosition())
    end)

    return { menu = helpMenu, hotkey = helpHotkey }
end
