-- local skynet = require "skynet"
-- local sprotoparser = require "sprotoparser"
-- local sprotoloader = require "sprotoloader"
-- require "common.util.util"

-- --某协议有语法错误时，只解析该协议文件，方便定位。不然报错中的行数很难定位,因为是所有协议文件合并成一个整体的行数：syntax error at [=text] line (210)
-- -- local test_files = {
-- -- 	"proto_200_299_task.lua", 
-- -- }
-- skynet.start(function()
-- 	--从协议目录里读取所有的lua文件,拼接其字符串生成sproto协议对象
--  	local s = io.popen("ls ./proto")
-- 	local fileNames = s:read("*all")
-- 	fileNames = Split(fileNames, "\n")
-- 	if test_files and #test_files > 0 then
-- 		fileNames = test_files
-- 	end
-- 	local proto_c2s_tb = {}
--     for k,v in pairs(fileNames or {}) do
--     	local dot_index = string.find(v, ".", 1, true)
--     	local is_lua_file = string.find(v, ".lua", -4, true)
--     	if Trim(v) ~= "" and dot_index ~= nil and is_lua_file then
-- 	    	local name_without_ex = string.sub(v, 1, dot_index-1)
-- 	        local proto_str = require("proto."..name_without_ex)
-- 	        if proto_str then
-- 	            table.insert(proto_c2s_tb, proto_str)
-- 	        end
--         end
--     end
--     local c2s_spb = sprotoparser.parse(table.concat(proto_c2s_tb))
-- 	sprotoloader.save(c2s_spb, 1)
-- 	-- don't call skynet.exit() , because sproto.core may unload and the global slot become invalid
-- end)




local skynet = require "skynet"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"

local CMD = {}
local data = {}

local function load(name)
	local filename = string.format("%s.sproto", name)
	local f = assert(io.open(filename), "Can't open " .. name)
	local t = f:read "a"
	f:close()
	return sprotoparser.parse(t)
end

function CMD.load(list)
	for i, name in ipairs(list) do
		local p = load(name)
		INFO(string.format("load proto [%s] in slot %d", name, i) )
		data[name] = i
		sprotoloader.save(p, i)
	end
end

function CMD.index(name)
	return data[name]
end

skynet.start(function()
	skynet.dispatch("lua", function (_,_, cmd, ...)
		local f = CMD[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			ERROR("Unknown command :", cmd)
			skynet.response()(false)
		end
	end)
	
end)