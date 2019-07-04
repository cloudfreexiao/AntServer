local fixmath = require("fixmath")
local a=fixmath.tofix("222")
local b = 1
local b = a/10
print(a, a+a, a+fixmath.tofix(49), a+1,b)
print(fixmath.maxvalue, fixmath.minvalue, fixmath.tofix(32769), a:sqrt(),a:tonumber())

local function testmath(name, ...)
	local fix = fixmath[name](...)
	print(name, fix, math[name] and math[name](...))
end

testmath("abs", -1)
testmath("floor", 1.1)
testmath("ceil",1.1)
testmath("min",1,2)
testmath("max",1,2)
testmath("sin",1)
testmath("cos",1)
testmath("tan",1)
testmath("asin",1.0)
testmath("acos",1.0)
testmath("asin",0)
testmath("acos",0.0)
testmath("atan",1)
testmath("atan2",1,2)
testmath("deg",1)
testmath("rad",90)
testmath("sqrt",2)
testmath("exp",1)
testmath("log",61)
testmath("log",3,4)


