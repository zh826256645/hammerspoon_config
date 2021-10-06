-- 字符串工具

-- 给 string 模块添加 split 函数，用于切割字符串
string.split = function(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end

-- 给 string 模块添加去除字符串两边的空格
string.strip = function(input)
    return (string.gsub(input, "^%s*(.-)%s*$", "%1"))
end

-- 给 string 模块添加去除字符串做左边的空格
string.lstrip = function (input)
    return (string.gsub(input, "^%s*(.-)", "%1"))
end

-- 给 string 模块添加去除字符串右边的空格
string.rstrip = function (input)
    return (string.gsub(input, "(.-)%s*$", "%1"))
end