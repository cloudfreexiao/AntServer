local lfs = require "lfs"
local skynet = require "skynet"
local codecache = require "skynet.codecache"
local class = require "class"


--取文件后缀
local function get_file_ext(str)
    return str:match("^.+(%..+)$")
end

local function open_dir(path, ext, callback)
    local dir = path
    local attr = assert(lfs.attributes(dir))
    if attr.mode == 'directory' then
        for f in lfs.dir(dir) do
            if f ~= '.' and f ~= '..' then
                local f_ext = get_file_ext(f)
                if not ext or f_ext == ext then
                    pcall(callback,f)
                end
            end
        end
    end
end

--目录下文件列表
local function dir_list( path, ext )
    local file_list = {}
    open_dir(path, ext, function(file_name)
        table.insert(file_list, file_name)
    end)
    return file_list
end

----file
--取文件名(带后缀)
local function get_file_name(str)
    return str:match("^.+/(.+)$")
end



local Object = class("Object")

function Object:initialize()
	self._objects = {}
	self._files_time = {}	--文件最后一次改动的时间
	self._file_postfix = ".lua" --后缀
end

function Object:add(object)
	--一个类可能对应很多个对象
	local class_name = object.getName()
	-- print("____class_name__",class_name)
	self._objects[class_name] = self._objects[class_name] or {}
	table.insert(self._objects[class_name],object)
end

function Object:get(class_name)
	return self._objects[class_name]
end

function Object:_addFile(path)
	local fileList = dir_list(path)	--目录下列表
	-- print("___fileList__",fileList)
	for _, v in pairs(fileList) do
		if get_file_ext(v) == self._file_postfix and v~="skynet_object.lua" then
			-- print("___11111__________",v,lfs.attributes(path..v,"change"),path)
			self._files_time[path..v] = lfs.attributes(path..v,"change")
		end
		-- if isFolderExist(path..v) then
		local mode = lfs.attributes(path..v,"mode")
		if mode == "directory" then --是文件夹
			-- print("___________path..v___",path..v)
			self:_addFile(path..v.."/")
		end
	end
end

--替换已加载的模块
function Object:replaceModule(moduleName,tbPath)
	local name = moduleName
	local hasModule = false
	if not package.loaded[moduleName] then
		skynet.error("-----------没有此模块-----------",moduleName)
		for i=#tbPath-1, 1 , -1 do --加上前缀路径看有没有此模块被加载
			name = tbPath[i].."."..name
			if package.loaded[name] then
				print("",name)
				hasModule = true
				moduleName = name
				break
			end
		end
		if not hasModule then
			return
		end
	end
	codecache.clear()
	package.loaded[moduleName] = nil --
	-- package.preload[moduleName] = nil
	local old_module = require(moduleName)
	local objects = self:get(old_module.getName())
	-- print("##################",old_module.__cname,new_module,old_module)
	if objects and next(objects) then
        for k,v in pairs(old_module) do
            old_module[k] = v
            for _,object in pairs(objects) do
                object[k] = v
            end
        end
        for _,object in pairs(objects) do
            if object.register and type(object.register)=="function" then --重新注册回调函数
                object:register()
            end
        end
	end
	package.loaded[moduleName] = old_module
	-- package.preload[moduleName] = old_module
end

--folder 服务所在文件夹
function Object:hotfix()
	--[[
		1 起动一个定时器，检查文件是否发生变动
		2.检查是否存在对象，进行类方法更新
		4
	--]]

	local serverPath = skynet.getenv("pro_path").."/" --进程所在目录
	local fileName
	local moduleName
	self:_addFile(serverPath)

	--检查文件是否改变动
	local function loop()
		while true do
			skynet.sleep(5 * 100)
			local fileChangeTime
			for k,v in pairs(self._files_time) do
				fileChangeTime = lfs.attributes(k,"change") or 0
				if fileChangeTime > v then	--时间发生变动
					fileName = get_file_name(k)
					-- print("_________fileName_change___",k,fileName)
					local tb = string.split(k,"/")
					fileName = string.gsub(fileName, self._file_postfix,"")
					self._files_time[k] = fileChangeTime
					moduleName = fileName
					self:replaceModule(moduleName,tb)--在模块中已存在的进行热
				end
			end
		end
    end

	skynet.fork(loop)
end

return Object