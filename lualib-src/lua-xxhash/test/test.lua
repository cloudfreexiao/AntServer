local xxhash = require('xxhash');

local max = 100;--0x1fffff;
local seed = 0x5bd1e995;
local key,idx;

for i = 0, 10, 1 do
    key = 'test' .. i;
    idx = xxhash.xxh32( key, seed );
    print( key, '->', idx, '->', idx % max );
end

local xh = xxhash.init( seed );
print( xh );

key = 'test10';
xh:update( key );
idx = xh:digest();
print( key, '->', idx, '->', idx % max );


