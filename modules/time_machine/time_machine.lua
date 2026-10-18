-- Time Machine 备份后安全弹出；所有系统命令在后台执行。
local TimeMachine = {}

function TimeMachine.register()
    local config = require("config").timeMachine
    if config == nil or config.enabled == false then
        return nil
    end
    if type(config.destinationId) ~= "string" or config.destinationId == ""
        or type(config.volumeUUID) ~= "string" or config.volumeUUID == "" then
        print("Time Machine 自动弹出已停用: 缺少 destinationId 或 volumeUUID")
        return nil
    end

    local controller = { state = {}, running = false, generation = 0 }
    local pythonPath = config.pythonPath or "/usr/bin/python3"
    local scriptPath = hs.configdir .. "/modules/time_machine/backup.py"
    local interval = math.max(10, tonumber(config.pollInterval) or 30)

    local function notify(message)
        print("Time Machine: " .. message)
        hs.notify.new({ title = "Time Machine", informativeText = message }):send()
    end

    local function readFailed(details)
        print("Time Machine 检查失败: " .. tostring(details))
        if not controller.readError then
            notify("无法检查备份状态，自动弹出暂不可用。请查看 Hammerspoon Console；硬盘未被自动弹出。")
        end
        controller.readError = true
    end

    function controller:check()
        if not self.running or self.task ~= nil then
            return
        end
        local generation = self.generation
        self.task = hs.task.new(pythonPath, function(exitCode, stdout, stderr)
            if not self.running or generation ~= self.generation then
                return
            end
            self.task = nil
            if exitCode ~= 0 then
                readFailed(stderr)
                return
            end
            local ok, response = pcall(hs.json.decode, stdout)
            if not ok or type(response) ~= "table" or type(response.state) ~= "table" then
                readFailed("后台脚本未返回有效状态")
                return
            end
            self.readError = false
            self.state = response.state
            if response.detail then
                print("Time Machine: " .. response.detail)
            end
            if response.event then
                notify(response.message)
            end
        end, {
            scriptPath,
            "--destination", config.destinationId,
            "--volume", config.volumeUUID,
            "--state", hs.json.encode(self.state),
        })
        if self.task == nil or not self.task:start() then
            self.task = nil
            readFailed("无法启动后台检查脚本，请检查 Python 路径")
        end
    end

    function controller:start()
        if self.running then
            return self
        end
        self.running = true
        self.generation = self.generation + 1
        self.state = {}
        self.timer = hs.timer.doEvery(interval, function() self:check() end)
        self.watcher = hs.caffeinate.watcher.new(function(event)
            if event == hs.caffeinate.watcher.systemDidWake
                or event == hs.caffeinate.watcher.screensDidWake
                or event == hs.caffeinate.watcher.screensDidUnlock then
                self:check()
            end
        end):start()
        self:check()
        print("Time Machine 自动弹出已启动，正在建立本次观察基线")
        return self
    end

    function controller:stop()
        self.running = false
        self.generation = self.generation + 1
        if self.timer then self.timer:stop() end
        if self.watcher then self.watcher:stop() end
        if self.task then self.task:terminate() end
        self.task = nil
        return self
    end

    return controller
end

return TimeMachine
