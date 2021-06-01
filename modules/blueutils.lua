-- 处理蓝牙

-- 蓝牙耳机地址
local MyJblBlueDeviceID = 'F8-DF-15-99-71-35'
local MySonyBlueDeviceID = '38-18-4C-95-C9-2E'
local MyKeychronT2DeviceID = 'DC-2C-26-E7-5A-7D'

-- 连接对应地址的设备
function connectBluetooth(DeviceID)
    local cmd = "/usr/local/bin/blueutil --connect "..(DeviceID)
    hs.osascript.applescript(string.format('do shell script "%s"', cmd))
end

-- 断开对应地址的设备
function disconnectBluetooth(DeviceID)
    local cmd = "/usr/local/bin/blueutil --disconnect "..(DeviceID)
    hs.osascript.applescript(string.format('do shell script "%s"', cmd))
end

function isConnectedBluetooth(DeviceID)
    local cmd = "/usr/local/bin/blueutil --is-connected "..(DeviceID)
    local succeeded, result = hs.osascript.applescript(string.format('do shell script "%s"', cmd))
    return tonumber(result)
end

-- 开关蓝牙
function bluetoothSwitch(state)
    -- state: 0(off), 1(on)
    if state == 1 then
        print("开启蓝牙")
		hs.notify.new({title="蓝牙", informativeText="开启蓝牙"}):send()
    elseif state == 0 then
        print("关闭蓝牙")
    end

    -- 判断蓝牙状态
    local cmd = "/usr/local/bin/blueutil --power"
    local succeeded, result = hs.osascript.applescript(string.format('do shell script "%s"', cmd))

    if tonumber(result) ~= state then
        local cmdSetState = "/usr/local/bin/blueutil --power "..(state)
        result = hs.osascript.applescript(string.format('do shell script "%s"', cmdSetState))
    end
end

function closeMyBluetooth()
    local jblState = isConnectedBluetooth(MyJblBlueDeviceID)
    if jblState == 1 then
        disconnectBluetooth(MyJblBlueDeviceID)
        print("断开 JBL 蓝牙耳机")
    end

    local sonyState = isConnectedBluetooth(MySonyBlueDeviceID)
    if sonyState == 1 then
        disconnectBluetooth(MySonyBlueDeviceID)
        print("断开 Sony 蓝牙耳机")
    end

    local keychronT2State = isConnectedBluetooth(MyKeychronT2DeviceID)
    if keychronT2State == 1 then
        disconnectBluetooth(MyKeychronT2DeviceID)
        print("断开 Keychron T2 蓝牙键盘")
    end
end

function bluetoothSwitchAfter(sec, state)
    print(sec.." 秒后如果屏幕依然上锁或者睡眠，将切换蓝牙")

    hs.timer.doAfter(sec, function()
        if (nowStatus == hs.caffeinate.watcher.screensDidSleep or nowStatus == hs.caffeinate.watcher.screensDidLock) then
            bluetoothSwitch(state)
        else
            print("取消切换蓝牙")
        end
    end)
end
