-- 监控设备状态

local pendingCloseTimer = nil
local pendingOpenTimer = nil
local monitorEventId = 0
local nowStatus = nil

local function stopTimer(timer)
    if timer ~= nil then
        timer:stop()
    end

    return nil
end

-- 多少秒后关闭程序
local function closeAfter(sec)
    local eventId = monitorEventId

    pendingCloseTimer = stopTimer(pendingCloseTimer)

    print(sec .. " 秒后如果仍未解锁，将关闭 微信、企业微信、音流，断开蓝牙设备并关闭蓝牙与 Wi-Fi")

    pendingCloseTimer = hs.timer.doAfter(sec, function()
        pendingCloseTimer = nil

        if (eventId ~= monitorEventId) then
            print("跳过过期的睡眠关闭任务")
            return
        end

        if (nowStatus ~= hs.caffeinate.watcher.screensDidUnlock) then
            CloseApplication(TheWeChatBundleID, "微信")
            CloseApplication(TheWeWorkBundleID, "企业微信")
            CloseApplication(TheYinLiuBundleID, "音流")
            CloseMyBluetooth()

            Sleep(2)

            BluetoothSwitch(0)
            WifiSwitch(0)
        else
            print("取消睡眠关闭任务")
        end
    end
    )
end

-- 多少秒后开启程序
local function openAfter(sec)
    local eventId = monitorEventId

    pendingOpenTimer = stopTimer(pendingOpenTimer)

    print(sec .. " 秒后如果未再次休眠，将预打开蓝牙与 Wi-Fi")

    pendingOpenTimer = hs.timer.doAfter(sec, function()
        pendingOpenTimer = nil

        if (eventId ~= monitorEventId) then
            print("跳过过期的唤醒预打开任务")
            return
        end

        if (nowStatus ~= hs.caffeinate.watcher.screensDidSleep) then
            BluetoothSwitch(1)
            WifiSwitch(1)
        else
            print("取消唤醒预打开任务")
        end
    end
    )
end

-- 根据系统状态进行不同的处理
local function caffeinateCallback(eventType)
    if (eventType == hs.caffeinate.watcher.screensDidSleep) then
        monitorEventId = monitorEventId + 1
        nowStatus = eventType
        print("睡眠")
        pendingOpenTimer = stopTimer(pendingOpenTimer)
        closeAfter(15)
    elseif (eventType == hs.caffeinate.watcher.screensDidWake) then
        monitorEventId = monitorEventId + 1
        nowStatus = eventType
        print("唤醒")
        openAfter(5)
    elseif (eventType == hs.caffeinate.watcher.screensDidLock) then
        monitorEventId = monitorEventId + 1
        nowStatus = eventType
        print("锁屏")
        -- blueUtils:disconnectBluetooth(MyBlueDeviceID) --
        -- bluetoothSwitchAfter(10, 0)
    elseif (eventType == hs.caffeinate.watcher.screensDidUnlock) then
        monitorEventId = monitorEventId + 1
        nowStatus = eventType
        print("解锁")
        pendingCloseTimer = stopTimer(pendingCloseTimer)
        pendingOpenTimer = stopTimer(pendingOpenTimer)
        -- blueUtils:connectBluetooth(MyBlueDeviceID) --
        -- bluetoothSwitch(1)
        -- GetWeather()
        print("解锁后立即打开蓝牙与 Wi-Fi")
        BluetoothSwitch(1)
        WifiSwitch(1)
        OpenApplication(TheScrollReverserID)
    else
        print("忽略未处理的 caffeinate 事件: " .. tostring(eventType))
    end
end

-- 注册监控
function RegisterMonitor()
    local monitor = hs.caffeinate.watcher.new(caffeinateCallback)
    return monitor
end
