-- local moon = require("moon")
-- local seri = require("seri")
-- local msgutil = require("common.msgutil")
-- local constant = require("common.constant")
-- local entitas    = require("entitas.index")
-- local Components = require("room.Components")
-- local MoveSystem = require('room.system.MoveSystem')
-- local DeadSystem = require('room.system.DeadSystem')
-- local EatSystem = require('room.system.EatSystem')
-- local UpdateDirectionSystem = require('room.system.UpdateDirectionSystem')
-- local UpdateRadiusSystem = require('room.system.UpdateRadiusSystem')
-- local UpdateSpeedSystem = require('room.system.UpdateSpeedSystem')

-- local conf = ...

-- -- local aoi = require("room.aoi")
-- -- aoi.create(conf.map.x, conf.map.y, conf.map.len, 8)


-- local PTOCLIENT = constant.PTYPE.TO_CLIENT

-- local ECSContext = entitas.Context
-- local Systems = entitas.Systems
-- local Matcher = entitas.Matcher
-- local PrimaryEntityIndex = entitas.PrimaryEntityIndex

-- local ecs_context = ECSContext.new()
-- local group = ecs_context:get_group(Matcher({Components.BaseData}))
-- local uid_index = PrimaryEntityIndex.new(Components.BaseData, group, 'id')
-- ecs_context:add_entity_index(uid_index)


-- ---@class room_context
-- local context ={
--     conf = conf,
--     ecs_context = ecs_context,
--     uid_index = uid_index,
--     fooduid = 1000000,
--     docmd = 0
-- }

-- local systems = Systems.new()
-- systems:add(UpdateDirectionSystem.new(context))
-- systems:add(MoveSystem.new(context))
-- systems:add(DeadSystem.new(context))
-- systems:add(EatSystem.new(context))
-- systems:add(UpdateRadiusSystem.new(context))
-- systems:add(UpdateSpeedSystem.new(context))

-- systems:activate_reactive_systems()
-- systems:initialize()


-- local tcomp = {id = 0,data=nil}
-- context.send_component = function(uid, entity, comp)
--     if entity:has(comp) then
--         tcomp.id = entity:get(Components.BaseData).id
--         tcomp.data = entity:get(comp)
--         moon.raw_send('toclient', context.gate,seri.packs(uid), msgutil.encode(Components.GetID(comp),tcomp))
--     end
-- end

-- context.make_prefab =function(entity, comp)
--     tcomp.id = entity:get(Components.BaseData).id
--     tcomp.data = entity:get(comp)
--     return moon.make_prefab(msgutil.encode(Components.GetID(comp),tcomp))
-- end

-- context.send_prefab =function(uid, prefabid)
--     moon.send_prefab(context.gate,prefabid,seri.packs(uid),0,PTOCLIENT)
-- end

