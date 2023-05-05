-- 处理应用

TheWeChatBundleID = "com.tencent.xinWeChat"
TheQQBundleID = "com.tencent.qq"
TheFinderID = "com.apple.finder"
TheIterm2ID = "com.googlecode.iterm2"
TheAlacrittyID = "io.alacritty"
TheWarpID = "dev.warp.Warp-Stable"
TheQQID = 'com.tencent.mqq'
TheChromeID = "com.google.Chrome"
TheVSCodeID = "com.microsoft.VSCode"
TheLaunchpadID = "com.apple.launchpad.launcher"
TheNotionID = "notion.id"
TheScrollReverserID = "com.pilotmoon.scroll-reverser"
TheReederID = "com.reederapp.macOS"
TheNeteaseID = "com.netease.163music"
TheQQMusicID = "com.tencent.QQMusicMac"

-- 关闭程序
function CloseApplication(bundleID)
    local application = hs.application.applicationsForBundleID(bundleID)
    application = application[1]

    if application ~= nil and application:isRunning() then
        local name = string.split(bundleID, '.')[3]
        print("关闭 " .. name .. " 程序")
        application:kill()
    end
end

-- 开启程序
function OpenApplication(bundleID)
    local application = hs.application.applicationsForBundleID(bundleID)
    application = application[1]
    if application == nil or not application:isRunning() then
        local name = string.split(bundleID, '.')[3]
        print("开启 " .. name .. " 程序")
        hs.application.open(bundleID)
    end
end

-- 获取程序信息
-- local function getApplicationInfo(bundleID)
--     print(hs.application.infoForBundleID(bundleID))
-- end

-- 绑定程序
function BindApplicationShortcut()
    local settings = {
        { 'Finder',    CmdHyper,     'E', TheFinderID },
        -- {'Iterm2', CtrlAltHyper, 'T', TheIterm2ID},
        { 'Alacritty', CtrlAltHyper, 'T', TheAlacrittyID },
        -- { 'Warp',      CtrlAltHyper, 'T', TheWarpID },
        { 'Chrome',    CmdCtrlHyper, 'G', TheChromeID },
        { 'VSCode',    CmdCtrlHyper, 'V', TheVSCodeID },
        { 'Launchpad', CmdCtrlHyper, 'L', TheLaunchpadID },
        { 'Notion',    CmdCtrlHyper, 'N', TheNotionID },
        { 'Reeder',    CmdCtrlHyper, 'R', TheReederID },
        { 'Netease',   CmdCtrlHyper, 'W', TheNeteaseID },
        { 'QQMusic',   CmdCtrlHyper, 'Y', TheQQMusicID },
    }
    for _, value in ipairs(settings) do
        hs.hotkey.bind(value[2], value[3], function()
            hs.application.open(value[4])
        end)
    end
end
