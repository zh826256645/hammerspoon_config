local companyUid = "154631B1-2A0A-4785-8EE3-EAF8D5445C68"
local homeUid = "F48B18E2-97D1-4ABB-9488-640135C2EF17"
local defaultUid = "A647F211-7CB7-4EE6-B13F-8DE36A8135AF"

function currentScselectUid()
    local cmd = "scselect current set"
    local succeeded, result = hs.osascript.applescript(string.format('do shell script "%s"', cmd))
    if (succeeded == true) then
        result = result:gsub("^Defined sets include: %(%* == current set%)\r", "")
        result = result:gsub("/r/n", "")
        result = result:split("\r")
        for k,v in ipairs(result) do
            if v:sub(2,2) == '*' then
                v = v:gsub(" %* ", "")
                v = v:sub(0, 36)
                return v
            end
        end
    end
end

function ssidChangedCallback() -- 回调
    local ssid = hs.wifi.currentNetwork() -- 获取当前 WiFi ssid
    if (ssid ~= nil) then
        local currentUid = currentScselectUid()
        local uid = nil
        if (ssid == "DaSheng_5G") then
            if (currentUid ~= companyUid) then
                uid = companyUid
                hs.notify.new({title="位置", informativeText="位置切换到公司"}):send()
            end
        elseif (ssid == "zhhh_5G") then
            if (currentUid ~= homeUid) then
                uid = homeUid
                hs.notify.new({title="位置", informativeText="位置切换到家里"}):send()
            end
        elseif (currentUid ~= defaultUid) then
            uid = defaultUid
            hs.notify.new({title="位置", informativeText="位置切换到自动"}):send()
        end

        if (uid ~= nil) then
            os.execute("scselect " ..uid .." > /dev/null") -- 切换网络位置
        end
    end
end

wifiWatcher = hs.wifi.watcher.new(ssidChangedCallback)
wifiWatcher:start() -- 开始监控
