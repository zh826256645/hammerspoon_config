-- 天气组件
local weatherConfig = require("config").weather
local configError = nil

local function requiredString(key)
    local value = weatherConfig and weatherConfig[key]
    if type(value) ~= "string" or value == "" then
        configError = "缺少 config.weather." .. key
        return nil
    end
    return value
end

local cityId = requiredString("cityId")
local currentWeatherUrl = 'http://www.nmc.cn/f/rest/real/%s'
-- local sevenDaysWeatherUrl = 'http://www.nmc.cn/f/rest/tempchart/%s'
local weatherPageUrl = requiredString("pageUrl")
local detailWeatherUrl = 'http://www.nmc.cn/rest/weather?stationid=%s&_=%s000'
local weatherScriptDir = requiredString("scriptDir")
local weatherScriptPython = requiredString("pythonPath")
local weatherScriptArgs = weatherConfig and weatherConfig.scriptArgs
local forecastJsonPath = requiredString("forecastJsonPath")
local darkWeatherImagePath = requiredString("darkImagePath")
local lightWeatherImagePath = requiredString("lightImagePath")
if type(weatherScriptArgs) ~= "table" then
    configError = "缺少 config.weather.scriptArgs"
end
if configError ~= nil then
    print("天气组件已停用: " .. configError)
end
local weatherImageTargetWidth = 400
local weatherAlertCooldownSeconds = 3 * 60 * 60
local weatherAlertWindowSeconds = 3 * 60 * 60
local weatherAlertSettingsKey = "weather.lastAbnormalAlertAt"


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

local weatherDescriptionMap = {
    ["thunderstorm"] = "雷暴",
    ["light thunderstorm"] = "小雷暴",
    ["heavy thunderstorm"] = "强雷暴",
    ["drizzle"] = "毛毛雨",
    ["light intensity drizzle"] = "小毛毛雨",
    ["light rain"] = "小雨",
    ["moderate rain"] = "中雨",
    ["heavy intensity rain"] = "大雨",
    ["very heavy rain"] = "暴雨",
    ["extreme rain"] = "极端降雨",
    ["freezing rain"] = "冻雨",
    ["shower rain"] = "阵雨",
    ["heavy intensity shower rain"] = "强阵雨",
    ["ragged shower rain"] = "零散阵雨",
    ["light snow"] = "小雪",
    ["snow"] = "降雪",
    ["heavy snow"] = "大雪",
    ["sleet"] = "雨夹雪",
    ["light shower sleet"] = "小阵性雨夹雪",
    ["shower sleet"] = "阵性雨夹雪",
    ["light rain and snow"] = "小雨夹雪",
    ["rain and snow"] = "雨夹雪",
    ["light shower snow"] = "小阵雪",
    ["shower snow"] = "阵雪",
    ["heavy shower snow"] = "强阵雪",
    ["mist"] = "薄雾",
    ["smoke"] = "烟雾",
    ["haze"] = "霾",
    ["sand/dust whirls"] = "扬沙",
    ["fog"] = "雾",
    ["sand"] = "沙",
    ["dust"] = "浮尘",
    ["volcanic ash"] = "火山灰",
    ["squalls"] = "飑",
    ["tornado"] = "龙卷风",
    ["hail"] = "冰雹",
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
local settings = require "hs.settings"

local function safeJsonDecode(body)
    if not body or body == '' then
        return nil
    end
    return hs.json.decode(body)
end

local function currentWeatherImagePath()
    if hs.host.interfaceStyle() == "Dark" then
        return darkWeatherImagePath
    end
    return lightWeatherImagePath
end

local function localizeWeatherDescription(weatherItem)
    if not weatherItem then
        return "异常天气"
    end

    local description = weatherItem.description
    if description and weatherDescriptionMap[string.lower(description)] then
        return weatherDescriptionMap[string.lower(description)]
    end

    local main = weatherItem.main
    if main and weatherDescriptionMap[string.lower(main)] then
        return weatherDescriptionMap[string.lower(main)]
    end

    return description or main or "异常天气"
end

local function readJsonFile(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return safeJsonDecode(content)
end

local function isAbnormalWeather(weatherItem)
    if not weatherItem then
        return false
    end

    local weatherId = weatherItem.id or 0
    local main = weatherItem.main or ""

    if weatherId >= 200 and weatherId < 700 then
        return true
    end

    return main == "Tornado"
        or main == "Squall"
        or main == "Ash"
        or main == "Sand"
        or main == "Dust"
        or main == "Fog"
        or main == "Haze"
        or main == "Smoke"
end

local function findUpcomingAbnormalForecast(forecastJson)
    if not forecastJson or type(forecastJson.list) ~= "table" then
        return nil
    end

    local now = os.time()
    local deadline = now + weatherAlertWindowSeconds

    for _, forecast in ipairs(forecastJson.list) do
        local forecastTime = forecast.dt
        if forecastTime and forecastTime >= now and forecastTime <= deadline then
            local weatherList = forecast.weather or {}
            for _, weatherItem in ipairs(weatherList) do
                if isAbnormalWeather(weatherItem) then
                    return forecast, weatherItem
                end
            end
        end
    end

    return nil
end

local function maybeNotifyUpcomingAbnormalWeather()
    local lastAlertAt = settings.get(weatherAlertSettingsKey) or 0
    local now = os.time()
    if now - lastAlertAt < weatherAlertCooldownSeconds then
        return
    end

    local forecastJson = readJsonFile(forecastJsonPath)
    local forecast, weatherItem = findUpcomingAbnormalForecast(forecastJson)
    if not forecast or not weatherItem then
        return
    end

    local whenText = os.date("%Y-%m-%d %H:%M", forecast.dt)
    local description = localizeWeatherDescription(weatherItem)
    local popText = ""
    if forecast.pop then
        popText = string.format("，降水概率 %.0f%%", forecast.pop * 100)
    end

    hs.notify.new({
        title = "天气提醒",
        informativeText = string.format("%s 预计有%s%s，注意出行。", whenText, description, popText)
    }):send()
    settings.set(weatherAlertSettingsKey, now)
end

local function setWeatherImage(menu)
    local weatherImage = hs.image.imageFromPath(currentWeatherImagePath())
    if not weatherImage then
        return false
    end

    local imageSize = weatherImage:size()
    if imageSize and imageSize.w and imageSize.h and imageSize.w > 0 then
        local scaledHeight = math.floor(weatherImageTargetWidth * imageSize.h / imageSize.w + 0.5)
        weatherImage:size({ w = weatherImageTargetWidth, h = scaledHeight })
    else
        weatherImage:size({ w = weatherImageTargetWidth, h = 311 })
    end

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
        maybeNotifyUpcomingAbnormalWeather()
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
    if configError ~= nil then
        return
    end

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
    if configError ~= nil then
        hs.notify.new({ title = "天气", informativeText = configError }):send()
        return nil
    end

    WeatherMenubar:setTitle('⌛')
    WeatherMenubar:setTooltip("Weather Info")

    GetWeather()

    local weatherTimer = hs.timer.new(600, GetWeather)
    return weatherTimer
end
