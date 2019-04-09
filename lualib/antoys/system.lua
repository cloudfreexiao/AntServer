local skynet = require "skynet"
local System = class("System")

local function firstElement(list)
    local _, value = next(list)
    return value
end

function System:initialize()
    -- Liste aller Entities, die die RequiredComponents dieses Systems haben
    self.targets = {}
    self.active = true
    self.hasGroups = nil
    for group, req in pairs(self:requires()) do
        local requirementIsGroup = type(req) == "table"
        if self.hasGroups ~= nil then
            assert(self.hasGroups == requirementIsGroup, "System " .. self.class.name .. " has mixed requirements in requires()")
        else
            self.hasGroups = requirementIsGroup
        end

        if requirementIsGroup then
            self.targets[group] = {}
        end
    end
end

function System:requires() return {} end

function System:onAddEntity(entity, group) end

function System:onRemoveEntity(entity, group) end

function System:addEntity(entity, category)
    -- If there are multiple requirement lists, the added entities will
    -- be added to their respective list.
    if category then
        self.targets[category][entity.id] = entity
    else
        -- Otherwise they'll be added to the normal self.targets list
        self.targets[entity.id] = entity
    end

    self:onAddEntity(entity, category)
end

function System:removeEntity(entity, group)
    if group and self.targets[group][entity.id] then
        self.targets[group][entity.id] = nil
        self:onRemoveEntity(entity, group)
        return
    end

    local firstGroup, _ = next(self.targets)
    if firstGroup then
        if self.hasGroups then
            -- Removing entities from their respective category target list.
            for group, _ in pairs(self.targets) do
                if self.targets[group][entity.id] then
                    self.targets[group][entity.id] = nil
                    self:onRemoveEntity(entity, group)
                end
            end
        else
            if self.targets[entity.id] then
                self.targets[entity.id] = nil
                self:onRemoveEntity(entity)
            end
        end
    end
end

function System:componentRemoved(entity, component)
    if self.hasGroups then
        -- Removing entities from their respective category target list.
        for group, requirements in pairs(self:requires()) do
            for _, req in pairs(requirements) do
                if req == component then
                    self:removeEntity(entity, group)
                    -- stop checking requirements for this group
                    break
                end
            end
        end
    else
        self:removeEntity(entity)
    end
end

function System:pickRequiredComponents(entity)
    local components = {}
    local requirements = self:requires()

    if type(firstElement(requirements)) == "string" then
        for _, componentName in pairs(requirements) do
            table.insert(components, entity:get(componentName))
        end
    elseif type(firstElement(requirements)) == "table" then
        skynet.error("System: :pickRequiredComponents() is not supported for systems with multiple component constellations")
        return nil
    end
    return table.unpack(components)
end

return System