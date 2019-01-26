#!/usr/bin/env lua53
assert(_VERSION == "Lua 5.3")

package.path  = "client/?.lua;common/?.lua;lualib/?.lua;skynet/lualib/?.lua;"
package.cpath = "client/luaclib/?.so;luaclib/?.so"


