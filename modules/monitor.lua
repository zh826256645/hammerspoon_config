-- 监控设备状态

-- 多少秒后关闭程序
function closenAfter(sec)
    -- 关闭微信
    local name = string.split(TheWeChatBundleID, '.')[3]

    print(sec.." 秒后如果屏幕依然未解锁，将关闭 "..name.." 与断开蓝牙耳机")

    hs.timer.doAfter(sec, function()
        if (nowStatus ~= hs.caffeinate.watcher.screensDidUnlock) then
            closeApplication(TheWeChatBundleID)
            closeMyBluetooth()
            bluetoothSwitch(0)
        else
            print("取消关闭 "..name.." 与 蓝牙")
        end
    end
    )
end


-- 多少秒后开启程序
function OpenAfter(sec)
    print(sec.." 秒后如果屏幕未休眠，将打开蓝牙")

    hs.timer.doAfter(sec, function()
        if (nowStatus ~= hs.caffeinate.watcher.screensDidSleep) then
            bluetoothSwitch(1)
        else
            print("取消打开蓝牙")
        end
    end
    )
end


function caffeinateCallback(eventType)
    nowStatus = eventType

    if (eventType == hs.caffeinate.watcher.screensDidSleep) then
        print("睡眠")
        closenAfter(15)
    elseif (eventType == hs.caffeinate.watcher.screensDidWake) then
        print("唤醒")
        OpenAfter(10)
    elseif (eventType == hs.caffeinate.watcher.screensDidLock) then
        print("锁屏")
        -- blueUtils:disconnectBluetooth(MyBlueDeviceID) --
        -- bluetoothSwitchAfter(10, 0)
    elseif (eventType == hs.caffeinate.watcher.screensDidUnlock) then
        print("解锁")
        -- blueUtils:connectBluetooth(MyBlueDeviceID) --
        -- bluetoothSwitch(1)
        getWeather()
    end
end

caffeinateWatcher = hs.caffeinate.watcher.new(caffeinateCallback)
caffeinateWatcher:start()
