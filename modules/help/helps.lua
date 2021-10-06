-- 快捷键说明文档

local function windowHelps(menuData)
    local subWindowMenuData = {}
    table.insert(menuData, { title="窗口快捷键", menu=subWindowMenuData})
    table.insert(subWindowMenuData, { title="左吸附              ^⌥⌘←"})
    table.insert(subWindowMenuData, { title="右吸附              ^⌥⌘→"})
    table.insert(subWindowMenuData, { title="上吸附              ^⌥⌘↑"})
    table.insert(subWindowMenuData, { title="下吸附              ^⌥⌘↓"})
    table.insert(subWindowMenuData, { title="-" })
    table.insert(subWindowMenuData, { title="左上角              ^⌥⇧←"})
    table.insert(subWindowMenuData, { title="右下角              ^⌥⇧→"})
    table.insert(subWindowMenuData, { title="右上角              ^⌥⇧↑"})
    table.insert(subWindowMenuData, { title="左下角              ^⌥⇧↓"})
    table.insert(subWindowMenuData, { title="-" })
    table.insert(subWindowMenuData, { title="到上个屏幕       ⌥⇧←"})
    table.insert(subWindowMenuData, { title="到下个屏幕       ⌥⇧→"})
    table.insert(subWindowMenuData, { title="-" })
    table.insert(subWindowMenuData, { titlge="最大化              ^⌥⌘M"})
    table.insert(subWindowMenuData, { title="全屏幕              ^⌥⌘F"})
    table.insert(subWindowMenuData, { title="屏幕居中          ^⌥⌘C"})

    local subProgramMenuData = {}
    table.insert(menuData, { title="-" })
    table.insert(menuData, { title="程序快捷键", menu=subProgramMenuData})
    table.insert(subProgramMenuData, { title="iTerm              ⌃⌥T"})
    table.insert(subProgramMenuData, { title="Finder              ⌘E"})
    table.insert(subProgramMenuData, { title="Chrome          ⌃⌘G"})
    table.insert(subProgramMenuData, { title="VSCode          ⌃⌘V"})
    table.insert(subProgramMenuData, { title="Launchpad     ⌃⌘L"})
    table.insert(subProgramMenuData, { title="Notion            ⌃⌘N"})
    table.insert(subProgramMenuData, { title="Reeder           ⌃⌘R"})
    table.insert(subProgramMenuData, { title="Netease         ⌃⌘W"})
end

function updateHelpMenu(menuBar, menuData)
    menuBar:setMenu(menuData)
end

-- 注册帮助界面
function RegisterHelpMenu()
    local helpMenubar = hs.menubar.new()
    local menuData = {}

    helpMenubar:setTooltip("helps")
    helpMenubar:setTitle("🔖")

    updateHelpMenu(helpMenubar, menuData)
    windowHelps(menuData)
end