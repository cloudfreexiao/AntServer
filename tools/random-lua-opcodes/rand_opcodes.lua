#!/usr/bin/env lua

local function readfile(name)
    local f = assert(io.open(name, "r"))
    local c = f:read("*a")
    f:close()
    return c
end

local function writefile(name, content)
    assert(content)
    local f = assert(io.open(name, "w"))
    f:write(content)
    f:close()
end

assert((...))

local source_dir = string.gsub((...), "/$", "")

local h = readfile(source_dir .. "/lopcodes.h")
local c = readfile(source_dir .. "/lopcodes.c")

local op_mapped = {}
local last_opcode 

local function mapped(list, f)
    assert(#list == #op_mapped)
    local t = {}
    for _, i in ipairs(op_mapped) do
        table.insert(t, assert(f and f(list[i]) or list[i]))
    end
    return t
end

math.randomseed(os.time())

-- replace lopcodes.h ---------------------------------------------------------
local h2 = string.gsub(h, "typedef enum {(.*)} OpCode;", function(s)
    local opcodes = {}

    for m in string.gmatch(s, "(OP_%u+),?") do
        table.insert(opcodes, m)
    end

    local t = {}

    for i=1, #opcodes do
        table.insert(t, i)
    end

    for i=1, #opcodes do
        local index = math.random (1, #t)
        table.insert(op_mapped, t[index])
        table.remove(t, index)
    end

    local new_opcodes = mapped(opcodes)

    last_opcode = new_opcodes[#new_opcodes]

    return "typedef enum {\n" .. table.concat(new_opcodes, ",\n") .. "\n} OpCode;"
end, 1)

assert(h ~= h2, "failed to replace opcode")

local h_final = string.gsub(h2, "NUM_OPCODES%c%(cast%(int, (OP_%u+)%) %+ 1%)", function(s)
    return string.format("NUM_OPCODES (cast(int, %s) + 1)", last_opcode)
end, 1)

assert(#op_mapped > 0)

-- replace lopcodes.c ---------------------------------------------------------
local c2 = string.gsub(c, "{(.*)NULL%c};", function(s)
    local opstrs = {}

    for m in string.gmatch(s, "\"(%u+)\",") do
        table.insert(opstrs, m)
    end

    return "{\n" .. table.concat(mapped(opstrs, function (s) 
        return "  \"" .. s .. "\","
    end), "\n") .. "\n  NULL\n};"
end)

assert(c ~= c2, "failed to replace opstrs")

local c_final = string.gsub(c2, "luaP_opmodes%[NUM_OPCODES%] = {(.*)}", function(s)
    local opmodes = {}

    for m in string.gmatch(s, "opmode%([^(^)]+%)") do
        table.insert(opmodes, m)
    end

    return "luaP_opmodes[NUM_OPCODES] = {\n  " .. 
        table.concat(mapped(opmodes), "\n ,") .. "\n}"
end)

assert(c2 ~= c_final, "failed to replace opmodes")

writefile(source_dir .. "/lopcodes.h", h_final)
writefile(source_dir .. "/lopcodes.c", c_final)

