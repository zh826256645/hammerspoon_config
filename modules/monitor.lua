-- 监控设备状态

--  多少秒后关闭程序
function closenAfter(sec, bundleID)
  local name = string.split(bundleID, '.')[3]

  print(sec.." 秒后如果屏幕依然上锁或者睡眠，将关闭 "..name.." 与断开蓝牙耳机")
  
  hs.timer.doAfter(sec, function()
      if (nowStatus == hs.caffeinate.watcher.screensDidSleep or nowStatus == hs.caffeinate.watcher.screensDidLock) then
          closeApplication(bundleID)
          closeMyBluetooth()
          bluetoothSwitch(0)
      else
          print("取消关闭 "..name.." 与 蓝牙")
      end
  end
  )
end


function caffeinateCallback(eventType)
    nowStatus = eventType

    if (eventType == hs.caffeinate.watcher.screensDidSleep) then
      print("睡眠")
      closenAfter(15, theWeChatBundleID)
    elseif (eventType == hs.caffeinate.watcher.screensDidWake) then
      print("唤醒")
    elseif (eventType == hs.caffeinate.watcher.screensDidLock) then
      print("锁屏")
      -- blueUtils:disconnectBluetooth(MyBlueDeviceID) --
      -- bluetoothSwitchAfter(10, 0)
    elseif (eventType == hs.caffeinate.watcher.screensDidUnlock) then
      print("解锁")
      -- blueUtils:connectBluetooth(MyBlueDeviceID) --
    --   bluetoothSwitch(1)
      getWeather()
    end
end

caffeinateWatcher = hs.caffeinate.watcher.new(caffeinateCallback)
caffeinateWatcher:start()
