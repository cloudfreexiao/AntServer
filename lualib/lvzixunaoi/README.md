# aoi
Area of Interest


### API 

~~~.lua
local aoi = require "aoi"

-- create aoi object
local aoi_obj = aoi.aoi_new(map_row, map_col, grid_row, grid_col)

-- add  watcher and maker object
local marked = aoi.WATCHER_MARK | aoi.MAKER_MARK
aoi_obj:aoi_add(obj_id, marked, pos_x, pos_y)

-- remove object
aoi_obj:aoi_remove(obj_id)

-- set object, pos_x in range [0, map_col), pos_y in range [0, map_row)
aoi_obj:aoi_set(obj_id, pos_x, pos_y)

-- update aoi
local ret = aoi_obj:aoi_update()

-- ret table detail:
ret = {
    [watcher_id1] = {
        { 
            [maker_id1] = { id=1, pos_x = 11, pos_y = 22, status = "A" },   -- add 1 object
            [maker_id2] = { id=2, pos_x = 11, pos_y = 22, status = "U" },   -- update 2 object
            ...
        },
        {
          [maker_id3] = { id=3, status = "D" },   -- remove 3 object  
          ...
        }
        ...
    },
    ...
}
~~~

### benchmark
test 10K object add in same grid, cost 0.028496s. in my `Intel(R) Core(TM) i7-4578U CPU @ 3.00GHz`.

read [aoi_test.lua](https://github.com/lvzixun/aoi/blob/master/aoi_test.lua) for more detail.
