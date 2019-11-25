## lua-objects ##

Advanced object oriented module for Lua (OOP)

This single-file module started its life as [dmc-objects](https://github.com/dmccuskey/dmc-objects) and was used to create mobile apps built with the Corona SDK. It was later refactored into two files `lua_objects.lua` & `dmc_objects.lua` so that pure-Lua environments could benefit, too (eg, [lua-corovel](https://github.com/dmccuskey/lua-corovel)).

This power-duo have been used to create relatively complex Lua mobile apps (~60k LOC), clients for websockets and the WAMP-protocol, and countless others.


### Features ###

* **_new!_** customizable methods and names for constructor/destructor
* **_new!_** multiple inheritance (all way to top level)
* **_new!_** handles ambiguities of inherited attributes
* **_new!_** advanced support for mixins
* getters and setters
* correctly handles missing methods on super classes
* optimization (copy methods from super classes)
* **_new!_** unit tested


### Examples ###

#### A Simple Custom Class ####

Here's a quick example showing how to create a custom class.

```lua
--== Import module

local Objects = require 'dmc_lua.lua_objects'


--== Create a class

local AccountClass = newClass()
 

--== Class Properties

AccountClass.DEFAULT_PATH = '/path/dir/'
AccountClass.DEFAULT_AMOUNT = 100.45


--== Class constructor/destructor

-- called from obj:new()
function AccountClass:__new__( params )
	params = params or {}
	self._secure = params.secure or true 
	self._amount = params.amount or self.DEFAULT_AMOUNT 
end

-- called from obj:destroy()
function AccountClass:__destroy__()
	self._secure = nil 
	self._amount = nil 
end


--== Class getters/setters

function AccountClass.__setters:secure( value )
	assert( type(value)=='boolean', "property 'secure' must be boolean" )
	self._secure = value
end
function AccountClass.__getters:secure()
	return self._secure
end


--== Class methods

function AccountClass:deposit( amount )
	self._amount = self._amount + amount
	self:dispatchEvent( AccountClass.AMOUNT_CHANGED_EVENT, { amount=self._amount } )
end
function AccountClass:withdraw( amount )
	self._amount = self._amount - amount
end

```


#### Create Class Instance ####

And here's how to work with that class.

```lua

-- Create instance

local account = AccountClass:new{ secure=true, amount=94.32 }

-- Call methods

account:deposit( 32.12 )
account:withdraw( 50.00 )


-- optimize method lookup

obj:optimize()
obj:deoptimize()


-- Check class/object types 

assert( AccountClass.is_class == true ), "AccountClass is a class" )
assert( AccountClass.is_instance == false ), "AccountClass is not an instance" )

assert( obj.is_class == false, "an object instance is not a class" ) 
assert( obj.is_instance == true, "an objects is an instance of a class" )
assert( obj:isa( AccountClass ) == true, "this obj is an instance of AccountClass" )


-- Destroy instance

account:destroy()
account = nil 

```

#### More, Advanced Examples ####

The project [dmc-objects](https://github.com/dmccuskey/dmc-objects) contains two `lua-objects` sub-classes made for mobile development (`ObjectBase` & `ComponentBase`). These sub-classes show how to get more out of `lua_objects`, such as:

* custom initialization and teardown
* custom constructor/destructor names
* custom Event mixin (add/removeListener/dispatchEvent) [lua-events-mixin](https://github.com/dmccuskey/lua-events-mixin)



### Custom Constructor/Destructor ###

You can even customize the names used for construction and destruction.

```lua
-- use 'create' instead of 'new'
-- eg,  MyClass:create{ secure=true, amount=94.32 }
--
registerCtorName( 'create' )

-- use 'removeSelf' instead of 'destroy'
-- eg,  obj:removeSelf()
--
registerDtorName( 'removeSelf' )

```