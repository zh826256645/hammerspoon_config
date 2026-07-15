-- 处理应用

TheWeChatBundleID = "com.tencent.xinWeChat"
TheWeWorkBundleID = "com.tencent.WeWorkMac"
TheQQBundleID = "com.tencent.qq"
TheFinderID = "com.apple.finder"
TheIterm2ID = "com.googlecode.iterm2"
TheAlacrittyID = "org.alacritty"
TheWarpID = "dev.warp.Warp-Stable"
TheQQID = 'com.tencent.mqq'
TheChromeID = "com.google.Chrome"
TheEdgeID = "com.microsoft.edgemac"
TheVSCodeID = "com.microsoft.VSCode"
TheLaunchpadID = "com.apple.launchpad.launcher"
TheNotionID = "notion.id"
TheScrollReverserID = "com.pilotmoon.scroll-reverser"
TheReederID = "com.reederapp.macOS"
TheNeteaseID = "com.netease.163music"
TheQQMusicID = "com.tencent.QQMusicMac"
TheSpotifyID = "com.spotify.client"
TheYouTubeMusicID = "com.google.Chrome.app.cinhimbnkkaeohfgghhklpknlkffjgod"
ThePodcastsMusicID = "com.apple.podcasts"
TheCodexID = "com.openai.codex"
TheYinLiuBundleID = "cn.aqzscn.streamMusic"

local workModeHotkeys = {}

local function SetWorkModeHotkeysEnabled(enabled)
    for _, hotkey in ipairs(workModeHotkeys) do
        if enabled then
            hotkey:enable()
        else
            hotkey:disable()
        end
    end
end

-- 关闭程序
function CloseApplication(bundleID, appName)
    local application = hs.application.applicationsForBundleID(bundleID)
    application = application[1]

    if application ~= nil and application:isRunning() then
        local name = appName or string.split(bundleID, '.')[3]
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
function BindApplicationShortcut(computerMode)
    local settings = {
        { 'Finder',         CmdHyper,     'E', TheFinderID },
        -- {'Iterm2', CtrlAltHyper, 'T', TheIterm2ID},
        { 'Alacritty',      CtrlAltHyper, 'T', TheAlacrittyID },
        -- { 'Warp',      CtrlAltHyper, 'T', TheWarpID },
        -- { 'Chrome',         CmdCtrlHyper, 'G', TheChromeID },
        { 'Chrome',         CmdCtrlHyper, 'G', TheEdgeID },
        { 'VSCode',         CmdCtrlHyper, 'V', TheVSCodeID, true },
        { 'Launchpad',      CmdCtrlHyper, 'L', TheLaunchpadID },
        { 'Notion',         CmdCtrlHyper, 'N', TheNotionID },
        { 'Reeder',         CmdCtrlHyper, 'R', TheReederID },
        -- { 'Netease',        CmdCtrlHyper, 'W', TheNeteaseID },
        -- { 'QQMusic',        CmdCtrlHyper, 'Y', TheQQMusicID },
        -- { 'Spotify',        CmdCtrlHyper, 'S', TheSpotifyID },
        -- { 'YouTubeMusicID', CmdCtrlHyper, 'M', TheYouTubeMusicID },
        { 'PodcastsMusic', CmdCtrlHyper, 'P', ThePodcastsMusicID },
        { 'Codex', CmdCtrlHyper, 'Z', TheCodexID, true },
    }
    for _, value in ipairs(settings) do
        local hotkey = hs.hotkey.bind(value[2], value[3], function()
            hs.application.open(value[4])
            hs.timer.doAfter(0.3, function()
                hs.alert.show(value[1], 0.8)
            end)
        end)
        if value[5] then
            table.insert(workModeHotkeys, hotkey)
        end
    end
    computerMode:onChange(function()
        SetWorkModeHotkeysEnabled(computerMode:isWorkMode())
    end)
end
