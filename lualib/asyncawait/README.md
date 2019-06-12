# lua-async-await

### import
1 get sources

2 copy /build/asynclib.lua to your project

3 require it

### library structure

- async -> function

```lua
local asyncFunc_0 = async(function()
	return 1
end)
local asyncFunc_1 = async(function(i)
	local v = await(asyncFunc_0())
	assert(v==1, 'v should be 2!')
	return await(asyncFunc_0())*i
end)
asyncFunc_1(2):await(function(ret)
	assert(ret==2, 'ret should be 2!')
end, function(err)
	assert(err==nil, 'unexcepted error!')
end)
```

- try   -> function

```lua
local asyncFunc_0 = async(function()
	error('test err')
end)
local asyncFunc_1 = async(function()
	try{
		function()
			local r = await(asyncFunc_0())
			error('unexcepted error!')
		end,
		catch = function(err)
			assert(err=='test err','err should be "test err"')
		end
	}
	return 'done!'
end)
asyncFunc_1(2):await(function(ret)
	assert(ret=='done!', 'ret should be "done!"!')
end, function(err)
	assert(err==nil, 'unexcepted error!')
end)
```

- Task  -> class

- Awaiter -> class
