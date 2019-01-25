local skynet = require "skynet"
local queue = require "skynet.queue"
require "skynet.manager"

local enumtype = {
	CHAR_TYPE_PLAYER = 1,
	CHAR_TYPE_MONSTER = 2,
}

local CMD = {}
local OBJ = {}
local playerview = {}
local monsterview = {}
local aoi
local update_thread
local need_update
local map_name = ...
local mapagent
local luaqueue = queue()

local AOI_RADIS = 200
local AOI_RADIS2 = AOI_RADIS * AOI_RADIS
local LEAVE_AOI_RADIS2 = AOI_RADIS2 * 4

local function DIST2(p1,p2)
	return ((p1.x - p2.x) * (p1.x  - p2.x) + (p1.y  - p2.y) * (p1.y  - p2.y) + (p1.z  - p2.z) * (p1.z  - p2.z))
end

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	pack = function(text) return text end,
	unpack = function(buf, sz) return skynet.tostring(buf,sz) end,
}

--怪物移动的时候通知玩家信息
local function updateviewmonster(monstertempid)
	if monsterview[monstertempid] == nil then return end
	local myobj = OBJ[monstertempid]
	local mypos = myobj.movement.pos
	--离开他人视野
	local leavelist = {}
	--进入他人视野
	local enterlist = {}
	--通知他人自己移动
	local movelist = {}

	local othertempid
	local otherpos
	local otheragent
	local otherobj
	for k,v in pairs(monsterview[monstertempid]) do
		othertempid = OBJ[k].tempid
		otherpos = OBJ[k].movement.pos
		otheragent = OBJ[k].agent
		otherobj = {
			tempid = othertempid,
			agent = OBJ[k].agent,
		}
		local distance = DIST2(mypos,otherpos)
		if distance <= AOI_RADIS2 then
			if not v then
				monsterview[monstertempid][k] = true
				playerview[k][monstertempid] = true
				table.insert(enterlist,OBJ[k])
			else
				table.insert(movelist,otheragent)
			end
		elseif distance > AOI_RADIS2 and distance <= LEAVE_AOI_RADIS2 then
			if v then
				monsterview[monstertempid][k] = false
				playerview[k][monstertempid] = false
				table.insert(leavelist,otherobj)
			end
		else
			if v then
				table.insert(leavelist,otherobj)
			end
			monsterview[monstertempid][k] = nil
			playerview[k][monstertempid] = nil
		end
	end

	--离开他人视野
	for _,v in pairs(leavelist) do
		skynet.send(v.agent,"lua","delaoiobj",myobj.tempid)
	end

	--重新进入视野
	for _,v in pairs(enterlist) do
		skynet.send(v.agent,"lua","addaoiobj",myobj)
	end

	--视野范围内移动
	for _,v in pairs(movelist) do
		skynet.send(v,"lua","updateaoiobj",myobj)
	end

	skynet.send(myobj.agent,"lua","updateaoilist",myobj.tempid,enterlist,leavelist)
end

--根据对象类型插入table
local function inserttotablebytype(t,v,type)
	if type ~= enumtype.CHAR_TYPE_PLAYER then
		table.insert(t.monsterlist,v)
	else
		table.insert(t.playerlist,v)
	end
end

--观看者坐标更新的时候
--根据距离情况通知他人自己的信息
local function updateviewplayer(viewertempid)
	if playerview[viewertempid] == nil then return end
	local myobj = OBJ[viewertempid]
	local mypos = myobj.movement.pos

	--离开他人视野
	local leavelist = {
		playerlist = {},
		monsterlist = {},
	}
	--进入他人视野
	local enterlist = {
		playerlist = {},
		monsterlist = {},
	}
	--通知他人自己移动
	local movelist = {
		playerlist = {},
		monsterlist = {},
	}

	local othertempid
	local otherpos
	local othertype
	local otherobj
	for k,v in pairs(playerview[viewertempid]) do
		othertempid = OBJ[k].tempid
		otherpos = OBJ[k].movement.pos
		othertype = OBJ[k].type
		otherobj = {
			tempid = othertempid,
			agent = OBJ[k].agent,
		}
		local distance = DIST2(mypos,otherpos)
		if distance <= AOI_RADIS2 then
			if not v then
				playerview[viewertempid][k] = true
				if othertype ~= enumtype.CHAR_TYPE_PLAYER then
					monsterview[k][viewertempid] = true
					table.insert(enterlist.monsterlist,OBJ[k])
				else
					playerview[k][viewertempid] = true
					table.insert(enterlist.playerlist,OBJ[k])
				end
			else
				inserttotablebytype(movelist,otherobj,othertype)
			end
		elseif distance > AOI_RADIS2 and distance <= LEAVE_AOI_RADIS2 then
			if v then
				playerview[viewertempid][k] = false
				if othertype ~= enumtype.CHAR_TYPE_PLAYER then
					monsterview[k][viewertempid] = false
					table.insert(leavelist.monsterlist,otherobj)
				else
					playerview[k][viewertempid] = false
					table.insert(leavelist.playerlist,otherobj)
				end
			end
		else
			if v then
				inserttotablebytype(leavelist,otherobj,othertype)
			end
			playerview[viewertempid][k] = nil
			if othertype ~= enumtype.CHAR_TYPE_PLAYER then
				monsterview[k][viewertempid] = nil
			else
				playerview[k][viewertempid] = nil
			end
		end
	end

	--离开他人视野
	for _,v in pairs(leavelist.playerlist) do
		skynet.send(v.agent,"lua","delaoiobj",viewertempid)
	end

	--重新进入视野
	for _,v in pairs(enterlist.playerlist) do
		skynet.send(v.agent,"lua","addaoiobj",myobj)
	end

	--视野范围内移动
	for _,v in pairs(movelist.playerlist) do
		skynet.send(v.agent,"lua","updateaoiobj",myobj)
	end

	--怪物的更新合并一起发送
	if not table.empty(leavelist.monsterlist) or
	not table.empty(enterlist.monsterlist) or
	not table.empty(movelist.monsterlist) then
		local monsterenterlist = {
			obj = myobj,
			monsterlist = enterlist.monsterlist,
		}
		local monsterleavelist = {
			tempid = viewertempid,
			monsterlist = leavelist.monsterlist,
		}
		local monstermovelist = {
			obj = myobj,
			monsterlist = movelist.monsterlist,
		}
		skynet.send(mapagent,"lua","updateaoiinfo",monsterenterlist,monsterleavelist,monstermovelist)
	end

	--通知自己
	skynet.send(myobj.agent,"lua","updateaoilist",enterlist,leavelist)
end

--aoi回调
function CMD.aoicallback(w,m)
	assert(OBJ[w],w)
	assert(OBJ[m],m)

	if playerview[OBJ[w].tempid] == nil then
		playerview[OBJ[w].tempid] = {}
	end
	playerview[OBJ[w].tempid][OBJ[m].tempid] = true

	--怪物视野内的玩家
	if OBJ[m].type ~=  enumtype.CHAR_TYPE_PLAYER then
		if monsterview[OBJ[m].tempid] == nil then
			monsterview[OBJ[m].tempid] = {}
		end
		monsterview[OBJ[m].tempid][OBJ[w].tempid] = true
	end

	--通知agent
	skynet.send(OBJ[w].agent,"lua","addaoiobj",OBJ[m])
	if OBJ[m].type ~= enumtype.CHAR_TYPE_PLAYER then
		skynet.send(OBJ[m].agent,"lua","addaoiobj",OBJ[m].tempid,OBJ[w])
	end
end

--添加到aoi
function CMD.characterenter(obj)
	assert(obj)
	assert(obj.agent)
	assert(obj.movement)
	assert(obj.movement.mode)
	assert(obj.movement.pos.x)
	assert(obj.movement.pos.y)
	assert(obj.movement.pos.z)
	--log.debug("AOI ENTER %d %s %d %d %d",obj.tempid,obj.movement.mode,obj.movement.pos.x,obj.movement.pos.y,obj.movement.pos.z)
	OBJ[obj.tempid] = obj
	if obj.type ~= enumtype.CHAR_TYPE_PLAYER then
		updateviewmonster(obj.tempid)
	else
		updateviewplayer(obj.tempid)
	end
	assert(pcall(skynet.send,aoi, "text", "update "..obj.tempid.." "..obj.movement.mode.." "..obj.movement.pos.x.." "..obj.movement.pos.y.." "..obj.movement.pos.z))
	need_update = true
end

--从aoi中移除
--TODO 怪物的离开
function CMD.characterleave(obj)
	assert(obj)
	skynet.error(obj.tempid, " leave aoi")
	assert(pcall(skynet.send, aoi, "text", "update "..obj.tempid.." d "..obj.movement.pos.x.." "..obj.movement.pos.y.." "..obj.movement.pos.z))
	OBJ[obj.tempid] = nil
	if playerview[obj.tempid] then
		local monsterleavelist = {
			tempid = obj.tempid,
			monsterlist = {},
		}
		for k,_ in pairs(playerview[obj.tempid]) do
			if playerview[k] then
				if playerview[k][obj.tempid] then
					--视野内需要通知
					skynet.send(OBJ[k].agent,"lua","delaoiobj",obj.tempid)
				end
				playerview[k][obj.tempid] = nil
			elseif monsterview[k] then
				if monsterview[k][obj.tempid] then
					--视野内需要通知
					table.insert(monsterleavelist.monsterlist,{tempid = k})
				end
				monsterview[k][obj.tempid] = nil
			end
		end

		if not table.empty(monsterleavelist.monsterlist) then
			skynet.send(mapagent,"lua","updateaoiinfo",{monsterlist = {}},monsterleavelist,{monsterlist = {}})
		end
		playerview[obj.tempid] = nil
	end
	need_update = true
end

--0.1秒更新一次
local function message_update ()
	if need_update then
		need_update = false
		assert(pcall(skynet.send,aoi, "text", "message "))
	end
	update_thread = skynet.timeout(10, message_update)
end

function CMD.open()
	aoi = assert(skynet.launch("caoi", map_name))
	assert(aoi == (skynet.self() + 1))
	mapagent = skynet.self() - 1
	message_update()
end

function CMD.close(name)
	skynet.error("close aoi(%s)...",name)
	update_thread()
end

skynet.start(function()
	skynet.dispatch("text", function (_, _, cmd)
		local t = cmd:split(" ")
		local f = CMD[t[1]]
		if f then
			luaqueue(f,tonumber(t[2]),tonumber(t[3]))
		else
			skynet.error("Unknown command : [%s]", cmd)
		end
	end)

	skynet.dispatch("lua", function (_,_, cmd, ...)
		local f = CMD[cmd]
		if f then
			skynet.ret(skynet.pack(luaqueue(f, ...)))
		else
			skynet.error("Unknown command : [%s]", cmd)
			skynet.response()(false)
		end
	end)
end)
