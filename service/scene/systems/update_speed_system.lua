local entitas = require("entitas.index")
local aoi = require("scene.aoi_wrapper")

local reactive_system = entitas.reactive_system
local matcher = entitas.matcher
local group_event = entitas.group_event

local components = require("scene.components.index")



local class = require("class")

local function unused() end

local M = class("UpdateSpeedSystem", reactive_system)

function M:initialize(context)
    M.super.initialize(self, context.ecs_context)
    self.context = context
    self.idx = context.uid_index--用来根据id查询玩家entity
    self.cfg = context.conf
end

local trigger = {
    {
        matcher({components.speed_component, components.mover_component}),
        group_event.ADDED | group_event.UPDATE
    }
}

function M:get_trigger()
    unused(self)
    return trigger
end

local all_comps = {components.speed_component, components.mover_component}

function M:filter(entity)
    unused(self)
    return entity:has_all(all_comps)
end

function M:execute(entites)
    entites:foreach(function(entity)
        local eid = entity:get(components.scene_cell_component).id
        local speedid = self.context.make_prefab(entity, components.speed_component)
        local near = aoi.get_aoi(eid) --TODO:
        if not near then
            return
        end

        for id, _ in pairs(near) do
            local ne = self.idx:get_entity(id)
            if ne and ne:has(components.mover_component) then
                self.context.send_prefab(id, speedid)
            end
        end
    end)
end

return M