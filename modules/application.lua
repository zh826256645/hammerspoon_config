-- 处理应用

TheWeChatBundleID = "com.tencent.xinWeChat"
TheQQBundleID = "com.tencent.qq"
TheFinderID = "com.apple.finder"
TheIterm2ID = "com.googlecode.iterm2"
TheQQID = 'com.tencent.mqq'
TheChromeID = "com.google.Chrome"
TheVSCodeID = "com.microsoft.VSCode"
TheLaunchpadID = "com.apple.launchpad.launcher"
TheNotionID = "notion.id"
TheScrollReverserID = "com.pilotmoon.scroll-reverser"
TheReederID = "com.reederapp.macOS"
TheNeteaseID = "com.netease.163music"

nowStatus = nil

function closeApplication(bundleID)
    local application = hs.application.applicationsForBundleID(bundleID)
    application = application[1]

    if application ~= nil and application:isRunning() then
        local name = string.split(bundleID, '.')[3]
        print("关闭 "..name.." 程序")
        application:kill()
    end
end

function openApplication(bundleID)
    local application = hs.application.applicationsForBundleID(bundleID)
    application = application[1]
    if application == nil or not application:isRunning() then
        local name = string.split(bundleID, '.')[3]
        print("开启 "..name.." 程序")
        hs.application.open(bundleID)
    end
end


function getApplicationInfo(bundleID)
    print(hs.application.infoForBundleID(bundleID))
end

-- 绑定访达快捷键
hs.hotkey.bind(hyperCmd, "E", function()
    hs.application.open(TheFinderID)
end)

-- 绑定 Iterm2 快捷键
hs.hotkey.bind(hyperCtrl, "T", function()
    hs.application.open(TheIterm2ID)
end)

-- -- 绑定体验版 QQ 快捷键
-- hs.hotkey.bind(hyperCtrlCmd, "Z", function()
--     hs.application.open(TheQQID)
-- end)

-- 绑定 Chrome 快捷键
hs.hotkey.bind(hyperCtrlCmd, "G", function ()
    hs.application.open(TheChromeID)
end)

-- 绑定 VS Code 快捷键
hs.hotkey.bind(hyperCtrlCmd, "V", function ()
    hs.application.open(TheVSCodeID)
end)

-- 绑定 Launchpad 快捷键
hs.hotkey.bind(hyperCtrlCmd, "L", function ()
    hs.application.open(TheLaunchpadID)
end)

-- 绑定 Notion 快捷键
hs.hotkey.bind(hyperCtrlCmd, "N", function ()
    hs.application.open(TheNotionID)
end)

-- 绑定 Reeder 快捷键
hs.hotkey.bind(hyperCtrlCmd, "R", function ()
    hs.application.open(TheReederID)
end)

-- 绑定 网易云 快捷键
hs.hotkey.bind(hyperCtrlCmd, "W", function ()
    hs.application.open(TheNeteaseID)
end)
