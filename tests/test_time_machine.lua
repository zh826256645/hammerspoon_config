-- Run with dofile(hs.configdir .. "/tests/test_time_machine.lua") in Hammerspoon.
-- The module runs in a sandbox; no real processes, timers or notifications are created.
local tasks, notices, timers, watchers = {}, {}, {}, {}
local config = { timeMachine = { destinationId = "destination", volumeUUID = "volume" } }
local function stoppable(callback)
    return { callback = callback, start = function(self) return self end,
        stop = function(self) self.stopped = true end }
end
local fakeHS = {
    configdir = "/test",
    json = { encode = function(value) return value end, decode = function(value) return value end },
    notify = { new = function(value)
        return { send = function() notices[#notices + 1] = value end }
    end },
    timer = { doEvery = function(_, callback)
        local timer = stoppable(callback)
        timers[#timers + 1] = timer
        return timer
    end },
    task = { new = function(path, callback, args)
        local task = { path = path, callback = callback, args = args,
            start = function(self) return self end,
            terminate = function(self) self.terminated = true end }
        tasks[#tasks + 1] = task
        return task
    end },
    caffeinate = { watcher = { systemDidWake = 1, screensDidWake = 2, screensDidUnlock = 3,
        new = function(callback)
            local watcher = stoppable(callback)
            watchers[#watchers + 1] = watcher
            return watcher
        end } },
}
local environment = setmetatable({ hs = fakeHS, require = function() return config end,
    print = function() end }, { __index = _G })
local module = assert(loadfile(hs.configdir .. "/modules/time_machine/time_machine.lua", "t", environment))()
local controller = assert(module.register())
controller:start()
assert(#tasks == 1 and #timers == 1 and #watchers == 1)
controller:check()
watchers[1].callback(fakeHS.caffeinate.watcher.systemDidWake)
assert(#tasks == 1, "overlapping background checks must be suppressed")
tasks[1].callback(0, { state = { attempt = 10, snapshot = 20 } }, "")
assert(controller.state.snapshot == 20 and #notices == 0)
watchers[1].callback(fakeHS.caffeinate.watcher.screensDidWake)
assert(#tasks == 2, "wake must trigger a check")
tasks[2].callback(1, "", "permission denied")
controller:check()
tasks[3].callback(1, "", "permission denied")
assert(#notices == 1, "repeated read failures must not spam notifications")
controller:check()
tasks[4].callback(0, { state = { attempt = 30, snapshot = 40 }, event = "ejected",
    message = "can unplug" }, "")
assert(#notices == 2 and notices[2].informativeText == "can unplug")
controller:check()
local stale = tasks[5]
controller:stop()
assert(stale.terminated and timers[1].stopped and watchers[1].stopped)
controller:start()
local current = tasks[6]
stale.callback(0, { state = { attempt = 1 }, event = "ejected", message = "stale" }, "")
assert(controller.task == current and #notices == 2,
    "a callback from before stop/restart must not change state or notify")
current.callback(0, { state = { attempt = 50, snapshot = 60 } }, "")
assert(controller.state.attempt == 50)
controller:stop()
config.timeMachine.enabled = false
assert(module.register() == nil)
config.timeMachine = nil
assert(module.register() == nil)
print("Time Machine Lua lifecycle tests passed (mocked; no disk operations)")
