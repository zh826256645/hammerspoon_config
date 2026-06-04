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

local lastSSID = nil
local pendingCheckTimer = nil

local function checkAndSwitch(ssid)
    print("Wi-Fi SSID 变更: " .. (ssid or "nil"))
    if (ssid ~= nil and ssid ~= lastSSID) then
        lastSSID = ssid
        if (ssid == "TelkingNet_PC") then
            print("检测到公司网络，切换 Clash 至 soclash")
            SwitchClashConfig("soclash")
        elseif (ssid == "zhhh_5G") then
            print("检测到家里网络，切换 Clash 至 PaofuCloud")
            SwitchClashConfig("PaofuCloud")
        end
    end
end

local function ssidChangedCallback()      -- 回调
    local ssid = hs.wifi.currentNetwork() -- 获取当前 WiFi ssid

    -- 取消上一次的延迟检查
    if (pendingCheckTimer ~= nil) then
        pendingCheckTimer:stop()
        pendingCheckTimer = nil
    end

    if (ssid == nil) then
        -- 断网过渡阶段，等 2 秒后重新检查
        print("Wi-Fi 断开，2 秒后重试")
        pendingCheckTimer = hs.timer.doAfter(2, function()
            pendingCheckTimer = nil
            checkAndSwitch(hs.wifi.currentNetwork())
        end)
    else
        checkAndSwitch(ssid)
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