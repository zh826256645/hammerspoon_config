local homeDir = os.getenv("HOME")

return {
    applications = {
        { name = "Finder", bundleId = "com.apple.finder", modifiers = { "cmd" }, key = "E" },
        { name = "Alacritty", bundleId = "org.alacritty", modifiers = { "ctrl", "alt" }, key = "T" },
        { name = "Edge", bundleId = "com.microsoft.edgemac", modifiers = { "cmd", "ctrl" }, key = "G" },
        { name = "VS Code", bundleId = "com.microsoft.VSCode", modifiers = { "cmd", "ctrl" }, key = "V", workModeOnly = true },
        { name = "Podcasts", bundleId = "com.apple.podcasts", modifiers = { "cmd", "ctrl" }, key = "P" },
        { name = "音流", bundleId = "cn.aqzscn.streamMusic", modifiers = { "cmd", "ctrl" }, key = "M" },
        { name = "Codex", bundleId = "com.openai.codex", modifiers = { "cmd", "ctrl" }, key = "Z", workModeOnly = true },
    },
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
        },
        home = {
            ssid = "HOME-SSID",
            volume = 50,
        },
    },
}
