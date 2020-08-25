-- 处理应用

theWeChatBundleID = "com.tencent.xinWeChat"
theQQBundleID = "com.tencent.qq"
theFinderID = "com.apple.finder"
theIterm2ID = "com.googlecode.iterm2"
theQQID = 'com.tencent.mqq'

nowStatus = nil

function closeApplication(bundleID)
    local application = hs.application.applicationsForBundleID(bundleID)
    local application = application[1]

    if application ~= nil and application:isRunning() then
        local name = string.split(bundleID, '.')[3]
        print("关闭 "..name.." 程序")
        application:kill()
    end
end


function getApplicationInfo(bundleID)
    print(hs.application.infoForBundleID(bundleID))
end

-- 绑定访达快捷键
hs.hotkey.bind(hyperCmd, "E", function()
    hs.application.open(theFinderID)
  end)

-- 绑定 Iterm2 快捷键
hs.hotkey.bind(hyperCtrl, "T", function()
    hs.application.open(theIterm2ID)
    end)

-- 绑定体验版 QQ 快捷键
hs.hotkey.bind(hyperCtrlCmd, "Z", function()
    hs.application.open(theQQID)
    end)
