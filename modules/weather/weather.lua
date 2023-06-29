-- 天气组件
local cityId = '591170'
local currentWeatherUrl = 'http://www.nmc.cn/f/rest/real/%s'
-- local sevenDaysWeatherUrl = 'http://www.nmc.cn/f/rest/tempchart/%s'
local weatherPageUrl = 'http://www.nmc.cn/publish/forecast/AGD/meizhou.html'
local detailWeatherUrl = 'http://www.nmc.cn/rest/weather?stationid=%s&_=%s000'

-- local urlApi = 'https://www.tianqiapi.com/api/?version=v1&appid=42598848&appsecret=7IDFGj4z'
local urlApi = 'https://v0.yiketianqi.com/api?unescape=1&version=v9&appid=54698688&appsecret=C6OgptjU'

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
    default = '⌛'
}

-- 获取天气对应的 emoji
local function getWeaEmoji(weatherInfoCN)
    local weatherInfoPY = "default"
    if weatherInfoCN == "雷" then
        weatherInfoPY = 'lei'
    elseif weatherInfoCN == "晴" then
        weatherInfoPY = 'qing'
    elseif weatherInfoCN == "沙尘" then
        weatherInfoPY = 'shachen'
    elseif weatherInfoCN == "雾" then
        weatherInfoPY = 'wu'
    elseif weatherInfoCN == "雨夹雪" then
        weatherInfoPY = 'yujiaxue'
    elseif weatherInfoCN == "多云" then
        weatherInfoPY = 'yun'
    elseif weatherInfoCN == "阵雨" then
        weatherInfoPY = 'zhenyu'
    elseif weatherInfoCN == "阴" then
        weatherInfoPY = 'yin'
    elseif string.find(weatherInfoCN, "雨") ~= nil then
        weatherInfoPY = 'yu'
    end
    return weaEmoji[weatherInfoPY]
end

WeatherMenubar = hs.menubar.new()
local menuData = {}

-- 获取天气信息
function GetWeather()
    print("更新天气")

    hs.http.doAsyncRequest(string.format(currentWeatherUrl, cityId), "GET", nil, nil, function(code, body, htable)
        if code ~= 200 then
            print('get weather error:' .. code)
            return
        end
        local rawJson = hs.json.decode(body)
        local city = rawJson.city
        local publish_time = rawJson.publish_time
        local weather = rawJson.weather
        local wind = rawJson.wind
        menuData = {}

        WeatherMenubar:setTitle(getWeaEmoji(weather.info) .. math.floor(weather.temperature) .. " " .. weather.info)

        local dateTable = FormatTimeToDateTable(publish_time, "%Y-%m-%d %H:%M")

        local tipStr = string.format("更新于 %s-%s %s:%s", dateTable.month, dateTable.day, dateTable.hour,
            dateTable.minute)
        WeatherMenubar:setTooltip(tipStr)
        local titleStr = string.format("%s %s日（今天） 🌡️%s℃ 💧%s 💨%s 🌬%s %s",
            getWeaEmoji(weather.info), dateTable.day, weather.temperature, weather.rain, weather.humidity, wind.power,
            weather.info)

        local firstLine = {
            title = titleStr,
            fn = function()
                hs.urlevent.openURL(weatherPageUrl)
            end
        }
        table.insert(menuData, firstLine)
        table.insert(menuData, { title = '-' })

        code, body, _ = hs.http.doRequest(urlApi, "GET", nil, nil)
        -- code, body, _ = hs.http.doRequest(string.format(detailWeatherUrl, cityId, tostring(os.time())), "GET", nil, nil)
        if code ~= 200 then
            print('get weather error:' .. code .. 'url: ' .. urlApi)
            return
        end

        rawJson = hs.json.decode(body)
        city = rawJson.city
        -- for k, v in pairs(rawJson.data.predict.detail) do
        for k, v in pairs(rawJson.data) do
            if k == 1 then
                local subMenu = {}
                -- for _, _v in pairs(rawJson.data.passedchart) do
                -- local _titleStr = string.format("%s 🌡️%s 💧%s 💨%s 🌬%s", _v.time, _v.temperature, _v.rain1h, _v.humidity, _v.windSpeed)
                for _k, _v in pairs(v.hours) do
                    local _titleStr = string.format("%s %s %s", _v.hours, _v.tem, _v.wea)
                    local _item = { title = _titleStr }
                    table.insert(subMenu, _item)
                end
                firstLine['menu'] = subMenu
            else
                -- titleStr = string.format("%s %s 🌞🌡️%s %s %s —— 🌜🌡️%s %s %s", getWeaEmoji(v.day.weather.info),v.date, v.day.weather.temperature, v.day.wind.power, v.day.weather.info,v.night.weather.temperature, v.night.wind.power, v.night.weather.info)
                titleStr = string.format("%s %s 🌡️%s 🌬%s %s", weaEmoji[v.wea_img], v.day, v.tem, v.win_speed,
                    v.wea)
                local item = { title = titleStr }
                table.insert(menuData, item)
            end
        end
        WeatherMenubar:setMenu(menuData)
    end)
end

-- 注册天气组件
function RegisterWeatherComponent()
    WeatherMenubar:setTitle('⌛')
    WeatherMenubar:setTooltip("Weather Info")

    GetWeather()

    local weatherTimer = hs.timer.new(600, GetWeather)
    return weatherTimer
end
