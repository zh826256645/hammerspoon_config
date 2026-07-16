-- Clash 配置
local homeDir = os.getenv("HOME")
local wifiConfig = require("config").wifi
local companyWifi = wifiConfig and wifiConfig.company
local homeWifi = wifiConfig and wifiConfig.home
local configError = nil

if type(companyWifi) ~= "table" or type(companyWifi.ssid) ~= "string" or companyWifi.ssid == ""
    or type(companyWifi.configName) ~= "string" or companyWifi.configName == "" then
    configError = "缺少 config.wifi.company 配置"
elseif type(homeWifi) ~= "table" or type(homeWifi.ssid) ~= "string" or homeWifi.ssid == ""
    or type(homeWifi.configName) ~= "string" or homeWifi.configName == ""
    or type(homeWifi.volume) ~= "number" then
    configError = "缺少 config.wifi.home 配置"
end

if configError ~= nil then
    print("Wi-Fi 自动切换已停用: " .. configError)
end

local clashApiUrl = "http://127.0.0.1:9090/configs"
local sparkleProfileStatePath = homeDir .. "/Library/Application Support/sparkle/profile.yaml"
local sparkleProfileDisplayNames = {}
local homeWifiVolume = homeWifi and homeWifi.volume
local configSwitchCooldownSeconds = 10
local lastConfigActionName = nil
local lastConfigActionAt = 0
local profileSourceOverrides = {}
if configError == nil then
    sparkleProfileDisplayNames[companyWifi.configName] = companyWifi.displayName
    sparkleProfileDisplayNames[homeWifi.configName] = homeWifi.displayName
    profileSourceOverrides[companyWifi.configName] = companyWifi.sourcePath
    profileSourceOverrides[homeWifi.configName] = homeWifi.sourcePath
end
local runtimeConfigDirCandidates = {
    homeDir .. "/Library/Application Support/sparkle/work",
    homeDir .. "/.config/mihomo",
    homeDir .. "/.config/clash.meta",
    homeDir .. "/.config/clash",
}
local sourceConfigDirCandidates = {
    homeDir .. "/.config/clash",
    homeDir .. "/.config/clash.meta",
    homeDir .. "/.config/mihomo",
    homeDir .. "/Library/Application Support/sparkle/work",
}

local function pathExists(path, expectedMode)
    local attributes = hs.fs.attributes(path)
    return attributes ~= nil and (expectedMode == nil or attributes.mode == expectedMode)
end

local function findRuntimeConfigDir()
    for _, dir in ipairs(runtimeConfigDirCandidates) do
        if pathExists(dir, "directory") then
            return dir
        end
    end

    return nil
end

local function findSourceConfigPath(configName)
    local overridePath = profileSourceOverrides[configName]
    if overridePath ~= nil and pathExists(overridePath, "file") then
        return overridePath, overridePath:match("([^/]+)$")
    end

    local fileNames = {
        configName .. ".yaml",
        configName .. ".yml",
    }

    for _, dir in ipairs(sourceConfigDirCandidates) do
        if pathExists(dir, "directory") then
            for _, fileName in ipairs(fileNames) do
                local configPath = dir .. "/" .. fileName
                if pathExists(configPath, "file") then
                    return configPath, fileName
                end
            end
        end
    end

    return nil, nil
end

local function readFile(path)
    local file = io.open(path, "rb")
    if file == nil then
        return nil
    end

    local content = file:read("*a")
    file:close()
    return content
end

local function writeFile(path, content)
    local file = io.open(path, "wb")
    if file == nil then
        return false
    end

    file:write(content)
    file:close()
    return true
end

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
        return nil
    end

    if outputDevice:muted() then
        print("跳过静音: 系统声音已静音")
        return nil
    end

    local volume = outputDevice:volume()
    if volume ~= nil and volume <= 0 then
        print("跳过静音: 系统音量已为 0")
        return nil
    end

    outputDevice:setMuted(true)
    print("检测到公司 Wi-Fi，已将系统声音静音")
    return "顺手把声音也关掉了"
end

local function RestoreHomeWifiAudio()
    local outputDevice = getBuiltInOutputDevice("恢复音量")
    if outputDevice == nil then
        return nil
    end

    if not outputDevice:muted() then
        print("跳过恢复音量: 系统声音当前不是静音")
        return nil
    end

    outputDevice:setMuted(false)
    outputDevice:setVolume(homeWifiVolume)
    print("检测到家里 Wi-Fi，已将系统声音打开并设置到 " .. homeWifiVolume .. "%")
    return "到家了，顺手把声音开到 " .. homeWifiVolume .. "%"
end

local function shouldSkipDuplicateConfigAction(configName)
    local now = hs.timer.secondsSinceEpoch()

    if lastConfigActionName == configName and (now - lastConfigActionAt) < configSwitchCooldownSeconds then
        return true
    end

    lastConfigActionName = configName
    lastConfigActionAt = now
    return false
end

local function prepareRuntimeConfig(configName)
    local runtimeConfigDir = findRuntimeConfigDir()
    if runtimeConfigDir == nil then
        return nil, "未找到可用的 mihomo 运行目录"
    end

    local sourceConfigPath, fileName = findSourceConfigPath(configName)
    if sourceConfigPath == nil then
        return nil, "未找到配置文件 " .. configName
    end

    local targetConfigPath = runtimeConfigDir .. "/" .. fileName
    if sourceConfigPath == targetConfigPath then
        return targetConfigPath, nil
    end

    local content = readFile(sourceConfigPath)
    if content == nil then
        return nil, "读取配置文件失败: " .. sourceConfigPath
    end

    if not writeFile(targetConfigPath, content) then
        return nil, "写入运行目录失败: " .. targetConfigPath
    end

    return targetConfigPath, nil
end

-- 切换 Clash 配置
local function SwitchClashConfig(configName, extraMessage)
    if shouldSkipDuplicateConfigAction(configName) then
        print("跳过重复的 Clash 配置切换: " .. configName)
        return
    end

    if pathExists(sparkleProfileStatePath, "file") then
        local displayName = sparkleProfileDisplayNames[configName] or configName
        local message = "请在 Sparkle 中切换到 " .. displayName
        if extraMessage ~= nil then
            message = extraMessage .. "，" .. message
        end
        print("Clash 配置切换提醒: " .. message)
        hs.notify.new({ title = "Sparkle", informativeText = message }):send()
        return
    end

    local configPath, errorMessage = prepareRuntimeConfig(configName)
    if configPath == nil then
        print("Clash 配置切换失败: " .. errorMessage)
        hs.notify.new({ title = "Clash", informativeText = errorMessage }):send()
        return
    end

    local headers = { ["Content-Type"] = "application/json" }
    local payload = hs.json.encode({ path = configPath })
    hs.http.doAsyncRequest(clashApiUrl, "PUT", payload, headers, function(code, body, headers)
        if code == 204 then
            print("Clash 配置已切换: " .. configName)
            local message = "配置已切换至 " .. configName
            if extraMessage ~= nil then
                message = extraMessage .. "，" .. message
            end
            hs.notify.new({ title = "Clash", informativeText = message }):send()
        else
            local detail = body and body ~= "" and (" - " .. body) or ""
            print("Clash 配置切换失败: " .. (code or "无响应") .. detail)
        end
    end)
end

local function ssidChangedCallback()      -- 回调
    local ssid = hs.wifi.currentNetwork() -- 获取当前 WiFi ssid
    if (ssid ~= nil) then
        if (ssid == companyWifi.ssid) then
            local extraMessage = MuteSystemAudio()
            SwitchClashConfig(companyWifi.configName, extraMessage)
        elseif (ssid == homeWifi.ssid) then
            local extraMessage = RestoreHomeWifiAudio()
            SwitchClashConfig(homeWifi.configName, extraMessage)
        end
    end
end

-- 注册 Wi-Fi 监控
function RegisterWifiWatcher()
    if configError ~= nil then
        hs.notify.new({ title = "Wi-Fi", informativeText = configError }):send()
        return nil
    end

    local wifiWatcher = hs.wifi.watcher.new(ssidChangedCallback)
    return wifiWatcher
end

-- 开关 Wi-Fi
function WifiSwitch(state)
    if state == 1 then
        print("开启 Wi-Fi")
        hs.notify.new({ title = "Wi-Fi", informativeText = "开启 Wi-Fi" }):send()
        hs.wifi.setPower(true)
    elseif state == 0 then
        print('关闭 Wi-Fi')
        hs.wifi.setPower(false)
    end
end
