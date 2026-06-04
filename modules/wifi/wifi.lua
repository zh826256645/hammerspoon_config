-- Clash 配置
local clashConfigDir = os.getenv("HOME") .. "/.config/clash"
local clashApiUrl = "http://127.0.0.1:9090/configs"

-- 切换 Clash 配置
local function SwitchClashConfig(configName)
    local configPath = clashConfigDir .. "/" .. configName .. ".yaml"
    hs.http.doAsyncRequest(clashApiUrl, "PUT", '{"path":"' .. configPath .. '"}', nil, function(code, body, headers)
        if code == 204 then
            print("Clash 配置已切换: " .. configName)
            hs.notify.new({ title = "Clash", informativeText = "配置已切换至 " .. configName }):send()
        else
            print("Clash 配置切换失败: " .. (code or "无响应"))
        end
    end)
end

-- 通过 airport 命令获取当前 SSID（备选方案）
local function getSSIDViaShell()
    local handle = io.popen("/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I 2>/dev/null | awk '/ SSID:/ {print $2}'")
    if handle then
        local result = handle:read("*a")
        handle:close()
        result = result:gsub("%s+$", "")
        if result ~= "" then
            return result
        end
    end
    return nil
end

local lastSSID = nil
local pendingCheckTimer = nil
local retryCount = 0
local maxRetries = 4
local retryDelay = 3

local function trySwitch(ssid)
    if (ssid ~= nil and ssid ~= lastSSID) then
        lastSSID = ssid
        retryCount = 0
        if (ssid == "TelkingNet_PC") then
            print("检测到公司网络，切换 Clash 至 soclash")
            SwitchClashConfig("soclash")
        elseif (ssid == "zhhh_5G") then
            print("检测到家里网络，切换 Clash 至 PaofuCloud")
            SwitchClashConfig("PaofuCloud")
        else
            print("未匹配的 SSID: " .. ssid)
        end
    end
end

local function getCurrentSSID(interface)
    -- 先尝试 Hammerspoon API
    local ssid = hs.wifi.currentNetwork(interface)
    if (ssid ~= nil) then
        return ssid
    end
    -- 备选：airport 命令
    return getSSIDViaShell()
end

local function scheduleRetry(interface)
    if (retryCount >= maxRetries) then
        print("Wi-Fi 重试耗尽，放弃检查")
        retryCount = 0
        return
    end
    retryCount = retryCount + 1
    print(string.format("Wi-Fi 尚未连接，%d 秒后第 %d/%d 次重试", retryDelay, retryCount, maxRetries))
    pendingCheckTimer = hs.timer.doAfter(retryDelay, function()
        pendingCheckTimer = nil
        local ssid = getCurrentSSID(interface)
        print("Wi-Fi SSID 变更: " .. (ssid or "nil"))
        if (ssid ~= nil) then
            trySwitch(ssid)
        else
            scheduleRetry(interface)
        end
    end)
end

local function ssidChangedCallback(_, message, interface)
    print("Wi-Fi 事件: " .. message .. " (接口: " .. (interface or "nil") .. ")")

    -- 取消上一次的延迟检查和重试
    if (pendingCheckTimer ~= nil) then
        pendingCheckTimer:stop()
        pendingCheckTimer = nil
    end

    local ssid = getCurrentSSID(interface)
    print("Wi-Fi SSID 变更: " .. (ssid or "nil"))

    if (ssid == nil) then
        retryCount = 0
        scheduleRetry(interface)
    else
        trySwitch(ssid)
    end
end

-- 注册 Wi-Fi 监控
function RegisterWifiWatcher()
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