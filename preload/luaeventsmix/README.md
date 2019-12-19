## lua-events-mixin ##

Add event capability to your Lua objects (event dispatch/listeners)


This module can add Event capability to any of your objects. It can be used either as a mixin class or by "monkey-patching" your object. It was designed to work with [lua-objects](https://github.com/dmccuskey/lua-objects) and has also been integrated in [dmc-objects](https://github.com/dmccuskey/dmc-objects) as a mixin.


### Features ###

* addEventListener
* removeEventListener
* dipatchEvent
* custom events
* unit tests


### Examples ###

#### Mixin Class ####

The project [dmc-objects](https://github.com/dmccuskey/dmc-objects) contains the `ObjectBase` sub-class which shows how to use this module as a mixin with multiple inheritance.

Here it is in a nutshell:

```lua
-- import the events mixin module (adjust path for your project)
local EventsMixModule = require 'dmc_lua.lua_events_mix'

-- create ref to mixin (optional)
local EventsMix = EventsMixModule.EventsMix

-- do multiple inheritance !
local ObjectBase = newClass( { Class, EventsMix } )


-- Then call init method in your OO Framework construction phase

-- with dmc-objects
	self:superCall( EventsMix, '__init__', ... )

-- with other frameworks
	EventsMix.__init__( self, ... )


-- When destroying, you can call __undoInit__

-- with dmc-objects
	self:superCall( EventsMix, '__undoInit__' )

-- with other frameworks
	EventsMix.__undoInit__( self )

```


#### Monkey Patching ####


```lua
--== Import module

local EventsMixModule = require 'dmc_lua.lua_events_mix'


--== Setup aliases, cleaner code

local EventsMix = EventsMixModule.EventsMix



--== Patch an object ==--

-- create one for yourself (eg, with OOP library)

local obj = {}  -- empty or create one from your OOP library
obj = EventsMix.patch( obj ) -- returns object


-- or have patch() create one for you

local obj = EventsMix.patch()  -- returns a new object



--== Methods

-- obj.EVENT constant is automatically added to your object, it can be changed
--
obj:addEventListener( obj.EVENT, callback )
obj:removeEventListener( obj.EVENT, callback )

obj.EVENT = 'obj_event' -- EVENT can be changed
obj.EVENT_NAME = 'my_custom_event_name' -- add this
obj:dispatchEvent( obj.EVENT_NAME, data )



--== Misc Methods

-- set a function to turn on/off debug output (per object)
obj:setDebug( boolean )

-- set a function to create custom events
obj:setEventFunc( func )


```
