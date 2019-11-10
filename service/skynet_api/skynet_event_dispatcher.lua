--[[

EventDispatcher.lua

Provides custom event broadcaster/listener mechanism to regular Lua objects.

Created by: Dave Yang / Quantumwave Interactive Inc.

http://qwmobile.com  |  http://swfoo.com/?p=632

Latest code: https://github.com/daveyang/EventDispatcher

Version: 1.3.4

--

The MIT License (MIT)

Copyright (c) 2014-2018 Dave Yang / Quantumwave Interactive Inc. @ qwmobile.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

--]]
---------------------------------------------------------------------------

--[[--
Provides custom event broadcaster / listener mechanism to regular Lua objects.

All listeners receive the following fields in the parameter event table:

<code>event.name</code> (name of the event)

<code>event.target</code> (the listener itself)

<code>event.source</code> (the dispatcher)

Latest code: https://github.com/daveyang/EventDispatcher

@module EventDispatcher
@usage
local EvtD = require "EventDispatcher"

local dispatcher = EvtD()

-- listener as table
local listener = {
    eventName = function(event, ...)
        print(event.name, event.target, event.source)
    end
}

-- listener as function
local function listener(event, ...)
    print(event.name, event.target, event.source)
end

dispatcher:addEventListener( "eventName", listener ) -- or
dispatcher:on( "eventName", listener )

dispatcher:once( "eventName", listener )

dispatcher:hasEventListener( "eventName", listener )

dispatcher:dispatchEvent( { name="eventName" } ) -- or
dispatcher:dispatchEvent( "eventName" ) -- or
dispatcher:emit( { name="eventName" } ) -- or
dispatcher:emit( "eventName" )

dispatcher:removeEventListener( "eventName", listener )

dispatcher:removeAllListeners( "eventName" ) -- or
dispatcher:removeAllListeners()

dispatcher:printListeners()
]]

local EventDispatcher = {}

-- Initializes an object (this is automatically invoked and is considered a private method)
-- @param o table object to become event dispatcher
-- @return a table
function EventDispatcher:init(o)
	o = o or {}
	o._listeners = {}
	self.__index = self
	return setmetatable(o, self)
end

---------------------------------------------------------------------------

--- Checks if the event dispatcher has registered listener for the event eventName.
-- @param eventName event name (string)
-- @param listener object (table or function)
-- @return found status (boolean); if found also returns the index of listener object.
function EventDispatcher:has_event_listener(eventName, listener)
	if eventName==nil or #eventName==0 or listener==nil then return false end

	local a = self._listeners
	if a==nil then return false end

	for i,o in next,a do
		if o~=nil and o.evt==eventName and o.obj==listener then
			return true, i
		end
	end
	return false
end

---------------------------------------------------------------------------

--- Adds a listener for the event eventName. Optional runs once flag.
-- @param eventName event name (string)
-- @param listener object (table or function)
-- @param isOnce flag to specify the listener only runs once (boolean)
-- @return success/fail status (boolean); position of listener is also returned if false; position=0 if failed.
-- @see on
-- @see once
function EventDispatcher:add_event_listener(eventName, listener, isOnce)
	if not isOnce then
		local found,pos = self:has_event_listener(eventName, listener)
		if found then return false,pos end
	end

	local a = self._listeners
	if a==nil then return false,0 end

	a[#a+1] = { evt=eventName, obj=listener, isOnce=isOnce }
	return true
end

--- 'on' is an alias of 'add_event_listener'
EventDispatcher.on = EventDispatcher.add_event_listener

---------------------------------------------------------------------------

--- Adds a one-time listener for the event eventName. Once the event is dispatched, the listener is removed.
-- @param eventName event name (string)
-- @param listener object (table or function)
-- @return success/fail status (boolean); position of listener is also returned if false; position=0 if failed.
-- @see add_event_listener
-- @see on
function EventDispatcher:once(eventName, listener)
	return self:add_event_listener(eventName, listener, true)
end

---------------------------------------------------------------------------

--- Dispatches an event, with optional extra parameters.
-- @param event the event (table, must have a 'name' key; e.g. { name="eventName" }, or as string)
-- @param ... optional extra parameters
-- @return dispatch status (boolean).
-- @see emit
function EventDispatcher:dispatch_event(event, ...)
	if event==nil then return false end

	if type(event)=="table" then
		if event.name==nil or type(event.name)~="string" or #event.name==0 then return false end
	elseif type(event)=="string" then
		if #event==0 then return false end
		event = { name=event }
	end

	local a = self._listeners
	if a==nil then return false end

	local dispatched = false
	for _,o in next,a do
		if o~=nil and o.obj~=nil and o.evt==event.name then
			event.target = o.obj
			event.source = self

			if type(o.obj)=="function" then
				o.obj(event, ...)
				if o.isOnce then self:remove_event_listener(event.name, o.obj, true) end
				dispatched = true
			elseif type(o.obj)=="table" then
				local f = o.obj[event.name]
				if f~= nil then
					f(event, ...)
					if o.isOnce then self:remove_event_listener(event.name, o.obj, true) end
					dispatched = true
				end
			end
		end
	end
	return dispatched
end

--- 'emit' is an alias of 'dispatchEvent'
EventDispatcher.emit = EventDispatcher.dispatch_event

---------------------------------------------------------------------------

--- Removes listener with the eventName event from the event dispatcher.
-- @param eventName event name (string)
-- @param listener object (table or function)
-- @return removal status (boolean).
-- @see removeAllListeners
function EventDispatcher:remove_event_listener(eventName, listener)
	local found,pos = self:has_event_listener(eventName, listener)
	if found then
		table.remove(self._listeners, pos)
	end
	return found
end

---------------------------------------------------------------------------

--- Removes all listeners with the eventName event from the event dispatcher.
--- If the optional eventName is nil, all listeners are removed from the event dispatcher.
-- @param eventName event name (string)
-- @return removal status (boolean), with the number of listeners removed.
-- @see removeEventListener
function EventDispatcher:remove_all_listeners(eventName)
	local a = self._listeners
	if a==nil then return false end

	if eventName==nil then
		local n = #self._listeners
		self._listeners = {}
		return true, n
	else
		local found = false
		local i = #a
		local n = 0

		while i>0 do
			local o = a[i]
			if o~=nil and o.evt==eventName then
				table.remove(a, i)
				found = true
				n = n + 1
			end
			i = i - 1
		end
		return found, n
	end
end

---------------------------------------------------------------------------

--- Prints the content of the _listeners array (for debugging).
-- Format: index, eventName, listener, isOnce.
function EventDispatcher:dump_listeners()
	local a = self._listeners
	if a==nil then return false end
    local skynet = require("skynet")
	for i,o in next,a do
		if o~=nil then
			skynet(i, o.evt, o.obj, o.isOnce)
		end
	end
end

---------------------------------------------------------------------------

-- Create syntactic sugar to automatically call init().
setmetatable(EventDispatcher, { __call = function(_, ...) return EventDispatcher:init(...) end })

return EventDispatcher
