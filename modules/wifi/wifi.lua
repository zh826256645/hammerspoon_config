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

local function ssidChangedCallback()      -- 回调
    local ssid = hs.wifi.currentNetwork() -- 获取当前 WiFi ssid
    if (ssid ~= nil) then
        if (ssid == "TelkingNet_PC") then
            SwitchClashConfig("soclash")
        elseif (ssid == "zhhh_5G") then
            SwitchClashConfig("PaofuCloud")
        end
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