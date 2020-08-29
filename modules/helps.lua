-- 快捷键说明文档
local helpMenubar = hs.menubar.new()
local menuData = {}
local subWindowMenuData = {}
local subProgramMenuData = {}

function windowHelps()
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
    table.insert(subWindowMenuData, { title="最大化              ^⌥⌘M"})
    table.insert(subWindowMenuData, { title="全屏幕              ^⌥⌘F"})
    table.insert(subWindowMenuData, { title="屏幕居中          ^⌥⌘C"})

    table.insert(menuData, { title="-" })
    table.insert(menuData, { title="程序快捷键", menu=subProgramMenuData})
    table.insert(subProgramMenuData, { title="iTerm              ⌃⌥T"})
    table.insert(subProgramMenuData, { title="Finder              ⌘E"})

end

function updateHelpMenu()
    helpMenubar:setMenu(menuData)
end

helpMenubar:setTooltip("helps")
helpMenubar:setTitle("🔖")

windowHelps()
updateHelpMenu()
