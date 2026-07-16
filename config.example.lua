local homeDir = os.getenv("HOME")

return {
    bluetooth = {
        blueutilPath = "/path/to/blueutil",
        devices = {
            { name = "耳机", id = "DEVICE-ID" },
            { name = "键盘", id = "DEVICE-ID" },
        },
    },
    weather = {
        cityId = "CITY-ID",
        pageUrl = "http://www.nmc.cn/publish/forecast/AREA/city.html",
        scriptDir = homeDir .. "/Projects/weather_landscape",
        pythonPath = "/path/to/python",
        scriptArgs = { "run_test.py" },
        forecastJsonPath = homeDir .. "/Projects/weather_landscape/tmp/forecast.json",
        darkImagePath = homeDir .. "/Projects/weather_landscape/tmp/landscape_dark.png",
        lightImagePath = homeDir .. "/Projects/weather_landscape/tmp/landscape_light.png",
    },
    wifi = {
        company = {
            ssid = "COMPANY-SSID",
            configName = "company-profile",
            displayName = "company-profile",
            sourcePath = homeDir .. "/path/to/company-profile.yaml",
        },
        home = {
            ssid = "HOME-SSID",
            configName = "home-profile",
            displayName = "home-profile",
            sourcePath = homeDir .. "/path/to/home-profile.yaml",
            volume = 50,
        },
    },
}
