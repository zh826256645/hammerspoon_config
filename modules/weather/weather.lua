-- 天气组件
local cityId = 'dEibM'
local currentWeatherUrl = 'http://www.nmc.cn/f/rest/real/%s'
-- local sevenDaysWeatherUrl = 'http://www.nmc.cn/f/rest/tempchart/%s'
local weatherPageUrl = 'http://www.nmc.cn/publish/forecast/AGD/meixian.html'
local detailWeatherUrl = 'http://www.nmc.cn/rest/weather?stationid=%s&_=%s000'
local weatherScriptDir = '/Users/zhonghao/Projects/weather_landscape'
local weatherScriptPython = '/Users/zhonghao/miniconda3/envs/zhonghao/bin/python'
local weatherScriptArgs = { 'run_test.py' }
local weatherImagePath = '/Users/zhonghao/Projects/weather_landscape/tmp/test_03B3D811B884.bmp'


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
    elseif weatherInfoCN ~= nil and string.find(weatherInfoCN, "雨") ~= nil then
        weatherInfoPY = 'yu'
    end
    return weaEmoji[weatherInfoPY]
end

WeatherMenubar = hs.menubar.new()
local menuData = {}
local weatherRequestId = 0
local weatherImageTask = nil

local function safeJsonDecode(body)
    if not body or body == '' then
        return nil
    end
    return hs.json.decode(body)
end

local function setWeatherImage(menu)
    local weatherImage = hs.image.imageFromPath(weatherImagePath)
    if not weatherImage then
        return false
    end
    weatherImage:size({ w = 350, h = 150 })
    table.insert(menu, 2, { title = "", image = weatherImage })
    table.insert(menu, 3, { title = '-' })
    return true
end

local function buildDetailMenu(detailJson)
    local detailMenu = {}
    for k, v in ipairs(detailJson.data.predict.detail) do
        if k ~= 1 then
            local titleStr = string.format(
                "%s %s 🌞🌡️%s %s %s —— 🌜🌡️%s %s %s",
                getWeaEmoji(v.day.weather.info),
                v.date,
                v.day.weather.temperature,
                v.day.wind.power,
                v.day.weather.info,
                v.night.weather.temperature,
                v.night.wind.power,
                v.night.weather.info
            )
            table.insert(detailMenu, { title = titleStr })
        end
    end
    return detailMenu
end

local function renderWeatherMenu(currentRequestId, detailMenu)
    if currentRequestId ~= weatherRequestId then
        return
    end
    menuData = detailMenu
    WeatherMenubar:setMenu(menuData)
end

local function buildWeatherImageAsync(currentRequestId, detailMenu)
    if weatherImageTask and weatherImageTask:isRunning() then
        weatherImageTask:terminate()
    end

    weatherImageTask = hs.task.new(weatherScriptPython, function(exitCode, stdOut, stdErr)
        if exitCode ~= 0 then
            print('weather image task error: ' .. tostring(exitCode))
            if stdErr and stdErr ~= '' then
                print(stdErr)
            end
            renderWeatherMenu(currentRequestId, detailMenu)
            return
        end

        if currentRequestId ~= weatherRequestId then
            return
        end

        local nextMenu = hs.fnutils.copy(detailMenu)
        setWeatherImage(nextMenu)
        renderWeatherMenu(currentRequestId, nextMenu)
    end, weatherScriptArgs)

    if not weatherImageTask then
        print('weather image task create failed')
        renderWeatherMenu(currentRequestId, detailMenu)
        return
    end

    weatherImageTask:setWorkingDirectory(weatherScriptDir)

    if not weatherImageTask:start() then
        print('weather image task start failed')
        renderWeatherMenu(currentRequestId, detailMenu)
    end
end

-- 获取天气信息
function GetWeather()
    print("更新天气")
    weatherRequestId = weatherRequestId + 1
    local currentRequestId = weatherRequestId

    hs.http.doAsyncRequest(string.format(currentWeatherUrl, cityId), "GET", nil, nil, function(code, body, htable)
        if currentRequestId ~= weatherRequestId then
            return
        end
        if code ~= 200 then
            print('get weather error:' .. code)
            return
        end
        local rawJson = safeJsonDecode(body)
        if not rawJson or not rawJson.weather or not rawJson.wind then
            print('get weather decode error: current weather payload invalid')
            return
        end
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
        WeatherMenubar:setMenu(menuData)

        hs.http.doAsyncRequest(string.format(detailWeatherUrl, cityId, tostring(os.time())), "GET", nil, nil,
            function(detailCode, detailBody, detailHeaders)
                if currentRequestId ~= weatherRequestId then
                    return
                end
                if detailCode ~= 200 then
                    print('get weather error:' .. detailCode .. 'url: ' .. detailWeatherUrl)
                    return
                end

                local detailJson = safeJsonDecode(detailBody)
                if not detailJson or not detailJson.data or not detailJson.data.predict or not detailJson.data.predict.detail then
                    print('get weather decode error: detail weather payload invalid')
                    return
                end

                local nextMenu = hs.fnutils.copy(menuData)
                local detailMenu = buildDetailMenu(detailJson)
                for _, item in ipairs(detailMenu) do
                    table.insert(nextMenu, item)
                end
                renderWeatherMenu(currentRequestId, nextMenu)
                buildWeatherImageAsync(currentRequestId, nextMenu)
            end)
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
