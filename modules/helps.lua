-- 快捷键说明文档
local helpMenubar = hs.menubar.new()
local menuData = {}

function windowHelps()
    table.insert(menuData, { title="window 快捷键" })
    table.insert(menuData, { title="-" })
    table.insert(menuData, { title="左吸附              ^⌥⌘←"})
    table.insert(menuData, { title="右吸附              ^⌥⌘→"})
    table.insert(menuData, { title="上吸附              ^⌥⌘↑"})
    table.insert(menuData, { title="下吸附              ^⌥⌘↓"})
    table.insert(menuData, { title="-" })
    table.insert(menuData, { title="左上角              ^⌥⇧←"})
    table.insert(menuData, { title="右下角              ^⌥⇧→"})
    table.insert(menuData, { title="右上角              ^⌥⇧↑"})
    table.insert(menuData, { title="左下角              ^⌥⇧↓"})
    table.insert(menuData, { title="-" })
    table.insert(menuData, { title="到上个屏幕       ⌥⇧←"})
    table.insert(menuData, { title="到下个屏幕       ⌥⇧→"})
    table.insert(menuData, { title="-" })
    table.insert(menuData, { title="最大化              ^⌥⌘M"})
    table.insert(menuData, { title="全屏幕              ^⌥⌘F"})
    table.insert(menuData, { title="屏幕居中          ^⌥⌘C"})
    
end

function updateHelpMenu()
    helpMenubar:setMenu(menuData)
end

helpMenubar:setTooltip("helps")
helpMenubar:setTitle("🔖")

windowHelps()
updateHelpMenu()
