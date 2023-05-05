-- 提示当前输入法啊

NowSourceID = nil
ShowUUID = nil
function RemindCurrentInputMethod()
    hs.keycodes.inputSourceChanged(function()
        local currentSourceID = hs.keycodes.currentSourceID()

        if (currentSourceID ~= NowSourceID) then
            -- 关闭重复提示
            hs.alert.closeSpecific(ShowUUID)

            NowSourceID = currentSourceID
            -- 提示当前输入法，注意这里增加了变量
            if (currentSourceID == "com.apple.keylayout.ABC") then
                ShowUUID = hs.alert.show("ABC", 0.8)
            elseif (currentSourceID == "com.apple.inputmethod.SCIM.ITABC") then
                ShowUUID = hs.alert.show("中文", 0.8)
            elseif (currentSourceID == "im.rime.inputmethod.Squirrel.Hans") then
                ShowUUID = hs.alert.show("鼠须管", 0.8)
            end
        end
    end)
end
