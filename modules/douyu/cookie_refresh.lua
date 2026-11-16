-- 周一、周四 19:00 刷新斗鱼 Cookie；执行 home-server-ops 的 refresh.sh。
local CookieRefresh = {}

local SCRIPT = "/Users/zhonghao/Projects/home-server-ops/work/douyu-refresh/refresh.sh"
local LOG = "/Users/zhonghao/Projects/home-server-ops/work/douyu-refresh/hs-cookie-refresh.log"
local ENV = {
    HOME = "/Users/zhonghao",
    PATH = "/Users/zhonghao/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin",
    LANG = "en_US.UTF-8",
}
local WEEKDAYS = { Monday = true, Thursday = true }

local function appendLog(text)
    local file = io.open(LOG, "a")
    if file == nil then
        print("斗鱼 Cookie 刷新: 无法写入日志 " .. LOG)
        return
    end
    file:write(text)
    file:close()
end

local function notify(message)
    print("斗鱼 Cookie 刷新: " .. message)
    hs.notify.new({
        title = "斗鱼 Cookie 刷新未成功",
        informativeText = message,
    }):send()
end

-- 本机 Hammerspoon 1.1.1 的 doAt 只接受固定间隔，不支持按星期触发。
local function nextTriggerTime(notBefore)
    local now = notBefore or os.time()
    local base = os.date("*t", now)
    for offset = 0, 8 do
        local candidate = os.time({
            year = base.year,
            month = base.month,
            day = base.day + offset,
            hour = 19,
            min = 0,
            sec = 0,
        })
        if candidate > now and WEEKDAYS[os.date("%A", candidate)] then
            return candidate
        end
    end
end

local function schedule(notBefore)
    local target = nextTriggerTime(notBefore)
    CookieRefresh.nextRun = target
    CookieRefresh.timer = hs.timer.doAfter(target - os.time(), function()
        CookieRefresh.run()
        schedule(os.time() + 60)
    end)
    return CookieRefresh.timer
end

function CookieRefresh.run()
    if CookieRefresh.task ~= nil then
        print("斗鱼 Cookie 刷新: 上一次仍在执行，跳过本次")
        return false
    end

    local task = hs.task.new("/bin/bash", function(exitCode, stdout, stderr)
        CookieRefresh.task = nil
        CookieRefresh.lastExitCode = exitCode
        CookieRefresh.lastFinishedAt = os.date("%Y-%m-%dT%H:%M:%S%z")
        appendLog(string.format("[%s] exit=%d\n", CookieRefresh.lastFinishedAt, exitCode))
        if stdout ~= "" then
            appendLog(stdout)
            if stdout:sub(-1) ~= "\n" then appendLog("\n") end
        end
        if stderr ~= "" then
            appendLog("[stderr]\n" .. stderr)
            if stderr:sub(-1) ~= "\n" then appendLog("\n") end
        end
        if exitCode ~= 0 then
            notify(string.format("退出码 %d，日志 %s", exitCode, LOG))
        end
    end, { SCRIPT })

    task:setEnvironment(ENV)
    CookieRefresh.task = task
    CookieRefresh.lastStartedAt = os.date("%Y-%m-%dT%H:%M:%S%z")
    appendLog(string.format("[%s] START\n", CookieRefresh.lastStartedAt))
    if not task:start() then
        CookieRefresh.task = nil
        appendLog(string.format("[%s] FAIL 无法启动 %s\n", os.date("%Y-%m-%dT%H:%M:%S%z"), SCRIPT))
        notify("无法启动 " .. SCRIPT)
        return false
    end
    return true
end

function CookieRefresh.start()
    if CookieRefresh.timer ~= nil then
        return CookieRefresh.timer
    end
    return schedule()
end

return CookieRefresh
