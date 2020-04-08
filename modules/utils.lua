string.split = function(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end

-- 将格式化时间转换为 Table
function formatTimeToDateTable(formatTime, format)
    supportMark = {Y={name="year", num=4}, m={name="month", num=2}, d={name="day", num=2}, H={name="hour", num=2}, M={name="minute", num=2}, S={name="second", num=2}}
    dateTable = {year=0, month=0, day=0, hour=0, day=0, minute=0, second=0}
    while(true)
    do
        index = string.find(format, "%%")
        if index then
            mark = supportMark[string.sub(format, index+1, index + 1)]
            dateTable[mark['name']] = string.sub(formatTime, index, index + mark['num'] - 1)
            format = string.sub(format, index+2)
            formatTime = string.sub(formatTime, index+mark['num'])
        else 
            break
        end
    end
    return dateTable
end


-- 打印 table
function printTable(table, level)
	key = ""
	local func = function(table, level)end
	func = function(table, level)
		level = level or 1
		local indent = ""
		for i = 1, level do
			indent = indent.."  "
		end
 
		if key ~= "" then
			print(indent..key.." ".."=".." ".."{")
		else
			print(indent .. "{")
		end
 
		key = ""
		for k,v in pairs(table) do
			if type(v) == "table" then
				key = k
				func(v, level + 1)
			else
				local content = string.format("%s%s = %s", indent .. "  ",tostring(k), tostring(v))
				print(content)  
			end
		end
		print(indent .. "}")
	end
	func(table, level)
end
