-- 处理剪贴板

function pasteboardCallback(value)
    if (type(value) == "string") then
        value = string.strip(value)
        hs.pasteboard.setContents(value)
    end
end

pasteboardWatcher = hs.pasteboard.watcher.new(pasteboardCallback)
pasteboardWatcher:start()
