-- 按网络位置切换 Tailscale 的子网路由接受策略。
local TailscaleRoute = {}
local config = require("config")

local tailscaleConfig = config.tailscale or {}
local homePrefix = tailscaleConfig.homeSubnet or "192.168.31."
local probeHost = tailscaleConfig.probeHost or "192.168.31.116"
local homeSSID = config.wifi and config.wifi.home and config.wifi.home.ssid

local TS = "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
local PYTHON = "/usr/bin/python3"
local CHECK_INTERVAL = 30

local busy = false

local function run(command)
    return hs.execute(command) or ""
end

local function homeInterface()
    for iface in run("/sbin/ifconfig -l"):gmatch("%S+") do
        if iface:match("^en%d+$") or iface:match("^eth%d+$") then
            local detail = run("/sbin/ifconfig " .. iface)
            local ip = detail:match("inet (%d+%.%d+%.%d+%.%d+)")
            if ip and ip:sub(1, #homePrefix) == homePrefix then
                return iface, ip
            end
        end
    end
    return nil
end

local function isHome()
    if homeSSID and hs.wifi.currentNetwork() == homeSSID then
        return true
    end
    return homeInterface() ~= nil
end

local function acceptRoutes()
    local prefs = run(TS .. " debug prefs 2>/dev/null")
    if prefs:find('"RouteAll": true', 1, true) then
        return true
    elseif prefs:find('"RouteAll": false', 1, true) then
        return false
    end
    return nil
end

local function setAcceptRoutes(enabled)
    local output, ok = hs.execute(TS .. " set --accept-routes=" .. tostring(enabled) .. " 2>&1")
    if not ok then
        return false, output
    end
    return true
end

local probeScript = [[
import socket, struct, sys
iface, src, dst = sys.argv[1], sys.argv[2], sys.argv[3]
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_DONTROUTE, 1)
s.setsockopt(socket.IPPROTO_IP, 25, struct.pack("I", socket.if_nametoindex(iface)))
s.bind((src, 0))
s.sendto(b"arp-probe", (dst, 9))
]]

local function forceLanProbe(iface, ip)
    hs.task.new(PYTHON, function() end, { "-c", probeScript, iface, ip, probeHost }):start()
end

local function check(homeOverride)
    if busy then
        return
    end
    busy = true

    local home = homeOverride
    if home == nil then
        home = isHome()
    end
    local want = not home
    local current = acceptRoutes()

    if current ~= want then
        local ok, output = setAcceptRoutes(want)
        if ok then
            print(string.format("Tailscale accept-routes=%s (home=%s)", tostring(want), tostring(home)))
        else
            print("Tailscale 路由切换失败: " .. tostring(output))
        end
    end

    if home then
        local iface, ip = homeInterface()
        if iface and ip then
            forceLanProbe(iface, ip)
        end
    end

    busy = false
end

function TailscaleRoute.start()
    if not hs.fs.attributes(TS) then
        print("Tailscale 路由自动切换已停用: 未找到 Tailscale")
        return
    end

    TailscaleRoute.wifiWatcher = hs.wifi.watcher.new(function()
        hs.timer.doAfter(3, function()
            check()
        end)
    end)
    TailscaleRoute.wifiWatcher:start()

    TailscaleRoute.timer = hs.timer.doEvery(CHECK_INTERVAL, function()
        check()
    end)

    TailscaleRoute.wakeWatcher = hs.caffeinate.watcher.new(function(event)
        if event == "systemDidWake" then
            hs.timer.doAfter(5, function()
                check()
            end)
        end
    end)
    TailscaleRoute.wakeWatcher:start()

    hs.timer.doAfter(3, function()
        check()
    end)
end

TailscaleRoute.refresh = check

return TailscaleRoute
