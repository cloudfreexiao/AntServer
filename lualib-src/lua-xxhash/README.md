lua-xxhash
=========

xxHash binding

---

## Installation

```sh
luarocks install xxhash --from=http://mah0x211.github.io/rocks/
```

## Functional Interface

- `val:int = xxhash.xxh32( data:string, seed:uint )`

### Usage

```lua
local xxhash = require('xxhash');
local res = xxhash.xxh32( 'abc', 0x5bd1e995 );
print(res); -- 3185488385
```

## OO Interface

- `xh:table = xxhash.init( seed:uint )`
- `xh:update( data:string )`
- `res:uint = xh:digest()`
- `xh:reset( [seed:uint] )`

### Usage

```lua
local xxhash = require('xxhash');
local xh = xxhash.init( 0x5bd1e995 );
local res;

print( xh ); -- 'xxhash: 0x7f95c8d003a8'

xh:update('abc');
res = xh:digest();
print( res ); -- 3185488385

xh:reset();

xh:update('a');
xh:update('bc');
res = xh:digest();
print( res ); -- 3185488385
```

