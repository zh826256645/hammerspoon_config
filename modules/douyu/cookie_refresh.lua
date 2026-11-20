-- 每天 08:00、21:30 检查斗鱼 Cookie 剩余时长；不足阈值时由 renew-if-needed.sh
-- 打开斗鱼页面触发静默续期，再走 refresh.sh 校验并同步到服务器。
local CookieRefresh = {}

local SCRIPT = "/Users/zhonghao/Projects/home-server-ops/work/douyu-refresh/renew-if-needed.sh"
local LOG = "/Users/zhonghao/Projects/home-server-ops/work/douyu-refresh/hs-cookie-refresh.log"
local ENV = {
    HOME = "/Users/zhonghao",
    PATH = "/Users/zhonghao/.local/bin:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin",
    LANG = "en_US.UTF-8",
}
local DAILY = { { hour = 8, min = 0 }, { hour = 21, min = 30 } }

local function appendLog(text)
    local file = io.open(LOG, "a")
    if file == nil then
        print("斗鱼 Cookie 续期: 无法写入日志 " .. LOG)
        return
    end
    file:write(text)
    file:close()
end

local function notify(message)
    print("斗鱼 Cookie 续期: " .. message)
    hs.notify.new({
        title = "斗鱼 Cookie 续期未成功",
        informativeText = message,
    }):send()
end

-- 本机 Hammerspoon 1.1.1 的 doAt 只接受固定间隔，因此自己算出下一次触发时刻。
local function nextTriggerTime(notBefore)
    local now = notBefore or os.time()
    local best = nil
    local base = os.date("*t", now)
    for offset = 0, 2 do
        for _, slot in ipairs(DAILY) do
            local candidate = os.time({
                year = base.year,
                month = base.month,
                day = base.day + offset,
                hour = slot.hour,
                min = slot.min,
                sec = 0,
            })
            if candidate > now and (best == nil or candidate < best) then
                best = candidate
            end
        end
    end
    return best
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
        print("斗鱼 Cookie 续期: 上一次仍在执行，跳过本次")
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
