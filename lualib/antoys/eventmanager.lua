local skynet = require "skynet"
local EventManager = class("EventManager")

function EventManager:initialize()
    self.eventListeners = {}
end

-- Adding an eventlistener to a specific event
function EventManager:addListener(eventName, listener, listenerFunction)
    -- If there's no list for this event, we create a new one
    if not self.eventListeners[eventName] then
        self.eventListeners[eventName] = {}
    end




    if not listener.class or (listener.class and not listener.class.name) then
        skynet.error('Eventmanager: The listener has to implement a listener.class.name field.')
    end

    for _, registeredListener in pairs(self.eventListeners[eventName]) do
        if registeredListener[1].class == listener.class then
            skynet.error(
                string.format("Eventmanager: EventListener for {} already exists.", eventName))
            return
        end
    end
    if type(listenerFunction) == 'function' then
        table.insert(self.eventListeners[eventName], {listener, listenerFunction})
    else
        skynet.error('Eventmanager: Third parameter has to be a function! Please check listener for ' .. eventName)
        if listener.class and listener.class.name then
            skynet.error('Eventmanager: Listener class name: ' .. listener.class.name)
        end
    end
end


return EventManager