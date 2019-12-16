-- 处理应用

theWeChatBundleID = "com.tencent.xinWeChat"
theQQBundleID = "com.tencent.qq"

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