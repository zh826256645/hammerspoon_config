
local frequency = 0.8 
local hist_size = 100 
local label_length = 70 
local honor_clearcontent = false
local pasteOnSelect = false

local jumpcut = hs.menubar.new()
jumpcut:setTooltip("Clipboard history")
local pasteboard = require("hs.pasteboard")
local settings = require("hs.settings")
local last_change = pasteboard.changeCount()

local clipboard_history = settings.get("so.victor.hs.jumpcut") or {}

function subStringUTF8(str, startIndex, endIndex)
    if startIndex < 0 then
        startIndex = subStringGetTotalIndex(str) + startIndex + 1
    end

    if endIndex ~= nil and endIndex < 0 then
        endIndex = subStringGetTotalIndex(str) + endIndex + 1
    end

    if endIndex == nil then 
        return string.sub(str, subStringGetTrueIndex(str, startIndex))
    else
        return string.sub(str, subStringGetTrueIndex(str, startIndex), subStringGetTrueIndex(str, endIndex + 1) - 1)
    end
end

function subStringGetTrueIndex(str, index)
    local curIndex = 0
    local i = 1
    local lastCount = 1
    repeat 
        lastCount = subStringGetByteCount(str, i)
        i = i + lastCount
        curIndex = curIndex + 1
    until(curIndex >= index)
    return i - lastCount
end

--返回当前字符实际占用的字符数
function subStringGetByteCount(str, index)
    local curByte = string.byte(str, index)
    local byteCount = 1
    if curByte == nil then
        byteCount = 0
    elseif curByte > 0 and curByte <= 127 then
        byteCount = 1
    elseif curByte>=192 and curByte<=223 then
        byteCount = 2
    elseif curByte>=224 and curByte<=239 then
        byteCount = 3
    elseif curByte>=240 and curByte<=247 then
        byteCount = 4
    end
    return byteCount
end

function setTitle()
   if (#clipboard_history == 0) then
      jumpcut:setTitle("✂")
   else
      jumpcut:setTitle("✂")
   end
end

function putOnPaste(string,key)
   if (pasteOnSelect) then
      hs.eventtap.keyStrokes(string)
      pasteboard.setContents(string)
      last_change = pasteboard.changeCount()
   else
      if (key.alt == true) then
         hs.eventtap.keyStrokes(string)
      else
         pasteboard.setContents(string)
         last_change = pasteboard.changeCount()
      end
   end
end

function clearAll()
   pasteboard.clearContents()
   clipboard_history = {}
   settings.set("so.victor.hs.jumpcut",clipboard_history)
   now = pasteboard.changeCount()
   setTitle()
end

function clearLastItem()
   table.remove(clipboard_history,#clipboard_history)
   settings.set("so.victor.hs.jumpcut",clipboard_history)
   now = pasteboard.changeCount()
   setTitle()
end

function pasteboardToClipboard(item)
   while (#clipboard_history >= hist_size) do
      table.remove(clipboard_history,1)
   end
   table.insert(clipboard_history, item)
   settings.set("so.victor.hs.jumpcut",clipboard_history)
   setTitle()
end

populateMenu = function(key)
   setTitle()
   menuData = {}
   if (#clipboard_history == 0) then
      table.insert(menuData, {title="None", disabled = true})
   else
      for k,v in pairs(clipboard_history) do
         if (string.len(v) > label_length) then
            table.insert(menuData,1, {title=subStringUTF8(v,0,label_length).."…", fn = function() putOnPaste(v,key) end }) -- Truncate long strings
         else
            table.insert(menuData,1, {title=v, fn = function() putOnPaste(v,key) end })
         end
      end
   end
   table.insert(menuData, {title="-"})
   table.insert(menuData, {title="Clear All", fn = function() clearAll() end })
   if (key.alt == true or pasteOnSelect) then
      table.insert(menuData, {title="Direct Paste Mode ✍", disabled=true})
   end
   return menuData
end

function storeCopy()
   now = pasteboard.changeCount()
   if (now > last_change) then
      current_clipboard = pasteboard.getContents()
      if (current_clipboard == nil and honor_clearcontent) then
         clearLastItem()
      else
         pasteboardToClipboard(current_clipboard)
      end
      last_change = now
   end
end

historyTimer = hs.timer.new(frequency, storeCopy)
historyTimer:start()

setTitle()
jumpcut:setMenu(populateMenu)

hs.hotkey.bind({"cmd", "shift"}, "v", function() jumpcut:popupMenu(hs.mouse.getAbsolutePosition()) end)
