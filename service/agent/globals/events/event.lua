Event = {}

local events = {}


-- accepts any amount and type of arguments after the event name
-- NOTE: triggered events have no guaranteed order in which callback objects are called
function Event.Trigger(eventname, ...)
	local eventlist = events[eventname] or {}
	
	for obj, callback in pairs(eventlist) do
		if type(obj) == "function" then
			obj(eventname, ...)
		elseif obj[eventname] then
			obj[eventname](obj, eventname, ...)
		elseif obj.OnEvent then
			obj:OnEvent(eventname, ...)
		end
	end
end


-- can register multiple events at the same time
-- any arguments after the object are treated as event names to be registered
function Event.Register(obj, ...)
	if not obj then
		return error("Event.Register error: nil callback object", 2)
	end
	
	local eventnames = type(...) == "table" and ... or {...}
	
	if #eventnames == 0 then
		return error("Event.Register error: nil event name", 2)
	end
	
	for i, eventname in ipairs(eventnames) do
		if type(eventname) == "string" then
			local eventlist = events[eventname]
			
			if not eventlist then
				eventlist = {}
				setmetatable(eventlist, {__mode="k"}) -- weak keys so garbage collector can clean up properly
			end
			
			if type(obj) ~= "function" and type(obj) ~= "table" then
				return error("Event.Register error: callback object is not a table or function", 2)
			end
			
			eventlist[obj] = true
			events[eventname] = eventlist
		end
	end
	
	return obj
end


-- can unregister multiple events at the same time
-- any arguments after the object are treated as event names to be unregistered
function Event.Unregister(obj, ...)
	if not obj then
		return error("Event.Unregister error: nil callback object", 2)
	end
	
	local eventnames = type(...) == "table" and ... or {...}
	
	if #eventnames == 0 then
		return error("Event.Unregister error: nil event name", 2)
	end
	
	for i, eventname in ipairs(eventnames) do
		local eventlist = events[eventname]
		if eventlist and eventlist[obj] then
			eventlist[obj] = nil
		end
	end
end


-- returns array of event names registered to an object
function Event.LookUp(obj)
	if type(obj) ~= "table" and type(obj) ~= "function" then
		return error("Event.LookUp error: callback object is not a table or function", 2)
	end
	
	local registeredevents = {}
	
	for eventname, eventlist in pairs(events) do
		for _obj, callback in pairs(eventlist) do
			if obj == _obj then
				table.insert(registeredevents, eventname)
				break
			end
		end
	end
	
	return registeredevents	
end
