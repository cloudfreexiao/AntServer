--[[
/**********************************************************\
|                                                          |
|                          hprose                          |
|                                                          |
| Official WebSite: http://www.hprose.com/                 |
|                   http://www.hprose.org/                 |
|                                                          |
\**********************************************************/

/**********************************************************\
 *                                                        *
 * hprose/common.lua                                      *
 *                                                        *
 * hprose common lib for Lua                              *
 *                                                        *
 * LastModified: Jun 14, 2015                             *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/
--]]


function string:trim()
    return self:match('^()%s*$') and '' or self:match('^%s*(.*%S)')
end

function string:split(delim, n)
    if self:find(delim) == nil or n == 1 then
        return { self }
    end
    if n == nil or n < 1 then
        n = 0
    end
    local result = {}
    local pattern = "(.-)" .. delim .. "()"
    local i = 1
    local p = 1
    for part, pos in self:gmatch(pattern) do
        result[i] = part
        i = i + 1
        p = pos
        if i == n then break end
    end
    result[i] = self:sub(p)
    return result
end

function string:ulen()
    local length = self:len()
    local len = length
    local pos = 1
    while (pos <= length) do
        local a = self:byte(pos)
        if a < 0x80 then
            pos = pos + 1
        elseif a >= 0xC0 and a < 0xE0 then
            pos = pos + 2
            len = len - 1
        elseif a >= 0xE0 and a < 0xF0 then
            pos = pos + 3
            len = len - 2
        elseif a >= 0xF0 and a < 0xF8 then
            pos = pos + 4
            len = len - 2
        else
            return -1
        end
    end
    return len
end

function string:isutf8()
    local length = self:len()
    local pos = 1
    local a, b, c, d, tune
    while (pos <= length) do
        a = self:byte(pos)
        if a < 0x80 then
            pos = pos + 1
        elseif a >= 0xC0 and a < 0xE0 then
            pos = pos + 1
            b = self:byte(pos)
            if b >= 0x80 and b < 0xC0 then
                pos = pos + 1
            else
                return false
            end
        elseif a >= 0xE0 and a < 0xF0 then
            pos = pos + 1
            b = self:byte(pos)
            if b >= 0x80 and b < 0xC0 then
                pos = pos + 1
                c = self:byte(pos)
                if c >= 0x80 and c < 0xC0 then
                    pos = pos + 1
                else
                    return false
                end
            else
                return false
            end
        elseif a >= 0xF0 and a < 0xF8 then
            pos = pos + 1
            b = self:byte(pos)
            if b >= 0x80 and b < 0xC0 then
                pos = pos + 1
                c = self:byte(pos)
                if c >= 0x80 and c < 0xC0 then
                    pos = pos + 1
                    d = self:byte(pos)
                    if d >= 0x80 and d < 0xC0 then
                        tune = (a - 0xF0) * 2 ^ 18 +
                               (b - 0x80) * 2 ^ 12 +
                               (c - 0x80) * 2 ^ 6 +
                               (d - 0x80) - 0x10000
                        if 0 <= rune and rune <= 0xFFFFF then
                            pos = pos + 1
                        else
                            return false
                        end
                    else
                        return false
                    end
                else
                    return false
                end
            else
                return false
            end
        else
            return false
        end
    end
    return true
end
