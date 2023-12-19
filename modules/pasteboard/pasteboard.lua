-- 处理剪贴板

LastStr = nil
local function pasteboardCallback(value)
    if (type(value) == "string") then
        value = string.strip(value)
        hs.pasteboard.setContents(value)

        if (value ~= LastStr) then
            hs.alert.show("复制", 0.8)
            LastStr = value
        end
    end
end

function RegisterPasteboardWatcher()
    local pasteboardWatcher = hs.pasteboard.watcher.new(pasteboardCallback)
    return pasteboardWatcher
end
