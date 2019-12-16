local urlApi = 'https://www.tianqiapi.com/api/?version=v1&appid=42598848&appsecret=7IDFGj4z'
local menubar = hs.menubar.new()
local menuData = {}

local weaEmoji = {
   lei = '⚡️',
   qing = '☀️',
   shachen = '😷',
   wu = '🌫',
   xue = '❄️',
   yu = '🌧',
   yujiaxue = '🌨',
   yun = '⛅️',
   zhenyu = '🌧',
   yin = '☁️',
   default = ''
}

function updateMenubar()
	 menubar:setTooltip("Weather Info")
    menubar:setMenu(menuData)
end

function getWeather()
   print("更新天气")
   
   hs.http.doAsyncRequest(urlApi, "GET", nil,nil, function(code, body, htable)
      if code ~= 200 then
         print('get weather error:'..code)
         return
      end

      rawjson = hs.json.decode(body)
      city = rawjson.city
      menuData = {}
      for k, v in pairs(rawjson.data) do
         if k == 1 then
            menubar:setTitle(weaEmoji[v.wea_img]..v.tem.." "..v.wea)
            titlestr = string.format("%s %s 🌡️%s 💧%s 💨%s 🌬 %s %s",weaEmoji[v.wea_img],v.day, v.tem, v.humidity, v.air, v.win_speed, v.wea)
            subMenu = {}
            for _k, _v in pairs(v.hours) do
               local _day = _v.day
               _day = string.split(_day, "日")[2]
               _titlestr = string.format("%s时 %s %s", _day, _v.tem, _v.wea)
               _item = { title = _titlestr }
               table.insert(subMenu, _item)
            end

            item = { title = titlestr, menu = subMenu}
            table.insert(menuData, item)
            table.insert(menuData, {title = '-'})
         else
            -- titlestr = string.format("%s %s %s %s", v.day, v.wea, v.tem, v.win_speed)
            titlestr = string.format("%s %s 🌡️%s 🌬%s %s", weaEmoji[v.wea_img],v.day, v.tem, v.win_speed, v.wea)
            item = { title = titlestr }
            table.insert(menuData, item)
         end
      end
      updateMenubar()
   end)
end

menubar:setTitle('⌛')
getWeather()
updateMenubar()
-- hs.timer.doEvery(1800, getWeather)
myTimer = hs.timer.new(600, getWeather)
myTimer:start()
