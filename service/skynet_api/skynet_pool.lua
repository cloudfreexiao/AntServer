-- pool.lua
-- ========
-- Helper library for creating and managing pools of objects in Lua.

-- [![Build Status](https://travis-ci.org/treamology/pool.lua.svg?branch=master)](https://travis-ci.org/treamology/pool.lua)
-- [![Coverage Status](https://coveralls.io/repos/github/treamology/pool.lua/badge.svg?branch=master)](https://coveralls.io/github/treamology/pool.lua?branch=master)
-- [![License](http://img.shields.io/badge/Licence-MIT-brightgreen.svg)](LICENSE)

-- Example
-- =======
-- ```
-- local pool = require "pool"

-- local function newObject()
-- 	local obj = {
-- 		foo = "bar",
-- 		reset = function()
-- 			print("reset!")
-- 		end
-- 	}
-- 	return obj
-- end

-- local objectPool = pool.create(newObject, 32)
-- local object = objectPool:obtain()

-- print(object.foo)

-- objectPool:free(object)
-- ```

-- Explanation
-- ===========
-- Object pools are useful for objects that are frequently being created and destroyed (for instance, bullets in a game). Using pools in a situation where creating and destroying instances are expensive can offer a performance boost. For more about object pooling, look [here](https://en.wikipedia.org/wiki/Object_pool_pattern).

-- Creating a pool
-- ---------------
-- Naturally, a pool must be created before it can be used.

-- `pool.create(newObjectFunc, numObjects)`: Creates a pool.
-- * `newObjectFunc` is a function that must return the object that is to be inserted into the pool.
-- * `numObjects` is the number of objects that will be immediately added into the pool. By default, this is 16.

-- Obtaining and freeing objects
-- -----------------------------
-- Now that a pool has been created, we can take and put back objects from and into the pool.

-- `pool:obtain()`: Obtains an object from the set of currently free objects.

-- `pool:free(object)`: Puts an object back into the pool for later use.
-- * `object` is the object to be freed
-- * If the object being freed contains a function named `reset`, it will be called when it is added back into the pool. Use this to reset any values on the object that you don't want sticking around between uses.

-- Purging objects from a pool
-- ---------------------------
-- The pool of free objects can also be cleared.

-- `pool:clear()`: Clears the free object pool.

-- Usage
-- =====
-- Copy/paste pool.lua into your source folder, then use

--     local pool = require "pool"
    
-- wherever you need it.

local pool = {}
local poolmt = {__index = pool}

function pool.create(newObject, poolSize)
	poolSize = poolSize or 16
	assert(newObject, "A function that returns new objects for the pool is required.")

	local freeObjects = {}
	for _ = 1, poolSize do
		table.insert(freeObjects, newObject())
	end

	return setmetatable({
			freeObjects = freeObjects,
			newObject = newObject
		},
		poolmt
	)
end

function pool:obtain()
	return #self.freeObjects == 0 and self.newObject() or table.remove(self.freeObjects)
end

function pool:free(obj)
	assert(obj, "An object to be freed must be passed.")

	table.insert(self.freeObjects, obj)
	if obj.reset then obj.reset() end
end

function pool:clear()
	for k in pairs(self.freeObjects) do
		self.freeObjects[k] = nil
	end
end

return pool