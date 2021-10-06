-- 处理剪贴板

local function pasteboardCallback(value)
    if (type(value) == "string") then
        value = string.strip(value)
        hs.pasteboard.setContents(value)
    end
end

function RegisterPasteboardWatcher()
    local pasteboardWatcher = hs.pasteboard.watcher.new(pasteboardCallback)
    return pasteboardWatcher
end
