-- 公共工具模块

-- 将时间字符串转换为 Table
function FormatTimeToDateTable(formatTime, format)
    local supportMark = {
		Y = {
			name = "year",
			num = 4
		},
		m = {
			name = "month",
			num = 2
		},
		d = {
			name = "day",
			num = 2
		},
		H = {
			name = "hour",
			num = 2
		},
		M = {
			name = "minute",
			num = 2
		},
		S = {
			name = "second",
			num = 2
		}
	}
    local dateTable = {
		year = 0,
		month = 0,
		day = 0,
		hour = 0,
		minute = 0,
		second = 0
	}
    while(true)
    do
        local index = string.find(format, "%%")
        if index then
            local mark = supportMark[string.sub(format, index + 1, index + 1)]
            dateTable[mark['name']] = string.sub(formatTime, index, index + mark['num'] - 1)
            format = string.sub(format, index + 2)
            formatTime = string.sub(formatTime, index + mark['num'])
        else
            break
        end
    end
    return dateTable
end

-- 打印 table
function PrintTable(table)
	local printTable_cache = {}

	local function sub_printTable(t, indent)
		if (printTable_cache[tostring(t)]) then
			print(indent .. "*" .. tostring(t))
		else
			printTable_cache[tostring(t)] = true
			if (type(t) == "table") then
				for pos,val in pairs(t) do
					if (type(val) == "table") then
						print(indent .. "[" .. pos .. "] => " .. tostring( t ).. " {")
						sub_printTable(val, indent .. string.rep(" ", string.len(pos) + 8 ))
						print(indent .. string.rep(" ", string.len(pos)+6 ) .. "}")
					elseif (type(val) == "string" ) then
						print(indent .. "[" .. pos .. '] => "' .. val .. '"')
					else
						print(indent .. "[" .. pos .. "] => " .. tostring(val))
					end
				end
			else
				print(indent..tostring(t))
			end
		end
	end

	if (type(table) == "table") then
		print(tostring(table) .. " {")
		sub_printTable(table, "  ")
		print("}")
	else
		sub_printTable(table, "  ")
	end
end

-- 休眠
function Sleep(n)
	os.execute("sleep " .. n)
 end