-- Wi-Fi 自动化
local Wifi = {}
local wifiConfig = require("config").wifi
local companyWifi = wifiConfig and wifiConfig.company
local homeWifi = wifiConfig and wifiConfig.home
local configError = nil

if type(companyWifi) ~= "table" or type(companyWifi.ssid) ~= "string" or companyWifi.ssid == "" then
    configError = "缺少 config.wifi.company 配置"
elseif type(homeWifi) ~= "table" or type(homeWifi.ssid) ~= "string" or homeWifi.ssid == ""
    or type(homeWifi.volume) ~= "number" then
    configError = "缺少 config.wifi.home 配置"
end

if configError ~= nil then
    print("Wi-Fi 自动切换已停用: " .. configError)
end

local homeWifiVolume = homeWifi and homeWifi.volume

local function getBuiltInOutputDevice(actionName)
    local outputDevice = hs.audiodevice.defaultOutputDevice()
    if outputDevice == nil then
        print(actionName .. "失败: 未找到默认输出设备")
        return nil
    end

    local transportType = outputDevice:transportType()
    if transportType ~= "Built-in" then
        print("跳过" .. actionName .. ": 当前输出设备不是系统自动扬声器 (" .. tostring(outputDevice:name()) .. ")")
        return nil
    end

    return outputDevice
end

local function MuteSystemAudio()
    local outputDevice = getBuiltInOutputDevice("静音")
    if outputDevice == nil then
        return
    end

    if outputDevice:muted() then
        print("跳过静音: 系统声音已静音")
        return
    end

    local volume = outputDevice:volume()
    if volume ~= nil and volume <= 0 then
        print("跳过静音: 系统音量已为 0")
        return
    end

    outputDevice:setMuted(true)
    print("检测到公司 Wi-Fi，已将系统声音静音")
end

local function RestoreHomeWifiAudio()
    local outputDevice = getBuiltInOutputDevice("恢复音量")
    if outputDevice == nil then
        return
    end

    if not outputDevice:muted() then
        print("跳过恢复音量: 系统声音当前不是静音")
        return
    end

    outputDevice:setMuted(false)
    outputDevice:setVolume(homeWifiVolume)
    print("检测到家里 Wi-Fi，已将系统声音打开并设置到 " .. homeWifiVolume .. "%")
end

local function ssidChangedCallback()
    local ssid = hs.wifi.currentNetwork()
    if ssid == companyWifi.ssid then
        MuteSystemAudio()
    elseif ssid == homeWifi.ssid then
        RestoreHomeWifiAudio()
    end
end

-- 注册 Wi-Fi 监控
function Wifi.registerWatcher()
    if configError ~= nil then
        hs.notify.new({ title = "Wi-Fi", informativeText = configError }):send()
        return nil
    end

    return hs.wifi.watcher.new(ssidChangedCallback)
end

-- 开关 Wi-Fi
function Wifi.switch(state)
    if state == 1 then
        print("开启 Wi-Fi")
        hs.notify.new({ title = "Wi-Fi", informativeText = "开启 Wi-Fi" }):send()
        hs.wifi.setPower(true)
    elseif state == 0 then
        print("关闭 Wi-Fi")
        hs.wifi.setPower(false)
    end
end

return Wifi
