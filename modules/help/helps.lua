-- 快捷键说明

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
        menu = {
            { title = "Finder                              ⌘E" },
            { title = "Alacritty                           ⌃⌥T" },
            { title = "Edge                                 ⌃⌘G" },
            { title = "VS Code（工作模式）             ⌃⌘V" },
            { title = "Codex（工作模式）                ⌃⌘Z" },
            { title = "Launchpad                         ⌃⌘L" },
            { title = "Notion                              ⌃⌘N" },
            { title = "Reeder                              ⌃⌘R" },
            { title = "Podcasts                           ⌃⌘P" },
        },
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

function RegisterHelpMenu()
    local helpMenu = assert(hs.menubar.new(false), "创建帮助菜单失败")
    helpMenu:setMenu(menuData)

    local helpHotkey = hs.hotkey.bind(CmdCtrlAltHyper, "/", function()
        helpMenu:popupMenu(hs.mouse.absolutePosition())
    end)

    return { menu = helpMenu, hotkey = helpHotkey }
end
