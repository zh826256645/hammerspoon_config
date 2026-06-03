-- 监控设备状态

local pendingCloseTimer = nil
local pendingOpenTimer = nil
local monitorEventId = 0

local function stopTimer(timer)
    if timer ~= nil then
        timer:stop()
    end

    return nil
end

-- 多少秒后关闭程序
local function closeAfter(sec)
    -- 关闭微信
    local name = string.split(TheWeChatBundleID, '.')[3]
    local eventId = monitorEventId

    pendingCloseTimer = stopTimer(pendingCloseTimer)

    print(sec .. " 秒后如果屏幕依然未解锁，将关闭 " .. name .. " 与断开蓝牙耳机")

    pendingCloseTimer = hs.timer.doAfter(sec, function()
        pendingCloseTimer = nil

        if (eventId ~= monitorEventId) then
            print("跳过过期的关闭任务")
            return
        end

        if (nowStatus ~= hs.caffeinate.watcher.screensDidUnlock) then
            CloseApplication(TheWeChatBundleID)
            CloseMyBluetooth()

            Sleep(2)

            BluetoothSwitch(0)
            WifiSwitch(0)
        else
            print("取消关闭 " .. name .. " 与 蓝牙")
        end
    end
    )
end

-- 多少秒后开启程序
local function openAfter(sec)
    local eventId = monitorEventId

    pendingOpenTimer = stopTimer(pendingOpenTimer)

    print(sec .. " 秒后如果屏幕未休眠，将打开蓝牙")

    pendingOpenTimer = hs.timer.doAfter(sec, function()
        pendingOpenTimer = nil

        if (eventId ~= monitorEventId) then
            print("跳过过期的打开任务")
            return
        end

        if (nowStatus ~= hs.caffeinate.watcher.screensDidSleep) then
            BluetoothSwitch(1)
            WifiSwitch(1)
        else
            print("取消打开蓝牙与 Wi-Fi")
        end
    end
    )
end

-- 根据系统状态进行不同的处理
local function caffeinateCallback(eventType)
    monitorEventId = monitorEventId + 1
    nowStatus = eventType

    if (eventType == hs.caffeinate.watcher.screensDidSleep) then
        print("睡眠")
        pendingOpenTimer = stopTimer(pendingOpenTimer)
        closeAfter(15)
    elseif (eventType == hs.caffeinate.watcher.screensDidWake) then
        print("唤醒")
        openAfter(5)
    elseif (eventType == hs.caffeinate.watcher.screensDidLock) then
        print("锁屏")
        -- blueUtils:disconnectBluetooth(MyBlueDeviceID) --
        -- bluetoothSwitchAfter(10, 0)
    elseif (eventType == hs.caffeinate.watcher.screensDidUnlock) then
        print("解锁")
        pendingCloseTimer = stopTimer(pendingCloseTimer)
        -- blueUtils:connectBluetooth(MyBlueDeviceID) --
        -- bluetoothSwitch(1)
        -- GetWeather()
        OpenApplication(TheScrollReverserID)
    end
end

-- 注册监控
function RegisterMonitor()
    local monitor = hs.caffeinate.watcher.new(caffeinateCallback)
    return monitor
end
