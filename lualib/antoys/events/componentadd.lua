
local CompoentAdded = class("CompoentAdded")

function ComponentAdded:initialize(entity, component)
    self.entity = entity
    self.component = component
end

return CompoentAdded