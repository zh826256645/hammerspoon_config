-- 处理蓝牙

local bluetoothConfig = require("config").bluetooth
local blueutilPath = bluetoothConfig and bluetoothConfig.blueutilPath
local bluetoothDevices = bluetoothConfig and bluetoothConfig.devices or {}
local configError = nil

if type(blueutilPath) ~= "string" or blueutilPath == "" or type(bluetoothConfig and bluetoothConfig.devices) ~= "table" then
    configError = "缺少 config.bluetooth 配置"
elseif hs.fs.attributes(blueutilPath, "mode") ~= "file" then
    configError = "未找到 blueutil: " .. blueutilPath
else
    for _, device in ipairs(bluetoothDevices) do
        if type(device.name) ~= "string" or device.name == "" or type(device.id) ~= "string" or device.id == "" then
            configError = "蓝牙设备缺少 name 或 id"
            break
        end
    end
end

if configError ~= nil then
    print("蓝牙控制已停用: " .. configError)
end

-- 断开对应地址的设备
local function disconnectBluetooth(DeviceID)
    local cmd = blueutilPath .. " --disconnect " .. DeviceID
    hs.osascript.applescript(string.format('do shell script "%s"', cmd))
end

-- 判断设备是否连接
local function isConnectedBluetooth(DeviceID)
    local cmd = blueutilPath .. " --is-connected " .. DeviceID
    local _, result = hs.osascript.applescript(string.format('do shell script "%s"', cmd))
    return tonumber(result)
end

-- 开关蓝牙
function BluetoothSwitch(state)
    if configError ~= nil then
        return
    end

    -- state: 0(off), 1(on)
    if state == 1 then
        print("开启蓝牙")
		hs.notify.new({title="蓝牙", informativeText="开启蓝牙"}):send()
    elseif state == 0 then
        print("关闭蓝牙")
    end

    -- 判断蓝牙状态
    local cmd = blueutilPath .. " --power"
    local succeeded, result = hs.osascript.applescript(string.format('do shell script "%s"', cmd))

    if tonumber(result) ~= state then
        local cmdSetState = blueutilPath .. " --power " .. state
        result = hs.osascript.applescript(string.format('do shell script "%s"', cmdSetState))
    end
end

--关闭我的设置
function CloseMyBluetooth()
    if configError ~= nil then
        return
    end

    for _, device in ipairs(bluetoothDevices) do
        if isConnectedBluetooth(device.id) == 1 then
            disconnectBluetooth(device.id)
            print("断开 " .. device.name)
        end
    end
end
