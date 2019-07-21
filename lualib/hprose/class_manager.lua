--[[
/**********************************************************\
|                                                          |
|                          hprose                          |
|                                                          |
| Official WebSite: http://www.hprose.com/                 |
|                   http://www.hprose.org/                 |
|                                                          |
\**********************************************************/

/**********************************************************\
 *                                                        *
 * hprose/class_manager.lua                               *
 *                                                        *
 * hprose ClassManager for Lua                            *
 *                                                        *
 * LastModified: Apr 19, 2014                             *
 * Author: Ma Bingyao <andot@hprose.com>                  *
 *                                                        *
\**********************************************************/
--]]

local ClassManager = {}
local classCache   = {}
local aliasCache   = {}

function ClassManager.register(class, alias)
    classCache[alias] = class
    aliasCache[class] = alias
end

function ClassManager.getClassAlias(class)
    return aliasCache[class]
end

function ClassManager.getClass(alias)
    return classCache[alias]
end

return ClassManager