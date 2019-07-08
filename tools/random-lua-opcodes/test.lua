local function f() 
    print("hello lua")
end

f()

local t = {}

for i=1, 10 do
    table.insert(t, i)
end

setmetatable(t, { __index = { join = function(t, s)  
    return table.concat(t, s)
end} })

print(t:join(","))
print(1+1)

