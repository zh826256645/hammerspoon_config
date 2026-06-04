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

-- 获取当前 SSID：优先 Hammerspoon API，失败则用 airport 命令
local function getCurrentSSID()
    local ssid = hs.wifi.currentNetwork()
    if (ssid ~= nil) then
        return ssid
    end
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
local pollInterval = 5

local function checkWiFi()
    local ssid = getCurrentSSID()
    if (ssid ~= lastSSID) then
        lastSSID = ssid
        print("Wi-Fi SSID 变更: " .. (ssid or "断开"))
        if (ssid == "TelkingNet_PC") then
            print("检测到公司网络，切换 Clash 至 soclash")
            SwitchClashConfig("soclash")
        elseif (ssid == "zhhh_5G") then
            print("检测到家里网络，切换 Clash 至 PaofuCloud")
            SwitchClashConfig("PaofuCloud")
        end
    end
end

-- 注册 Wi-Fi 监控（轮询方式）
function RegisterWifiWatcher()
    checkWiFi()
    hs.timer.doEvery(pollInterval, checkWiFi)
    return true
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