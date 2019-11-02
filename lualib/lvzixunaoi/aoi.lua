local aoi_mt = {}
aoi_mt.__index = aoi_mt


local grid_mt = {}
grid_mt.__index = grid_mt


local MAKER_MARK = 1
local WATCHER_MARK = 1 << 1

local pairs = pairs
local ipairs = ipairs
local next = next

local function grid_new(aoi_obj, grid_idx)
    local obj = {
        aoi_obj = aoi_obj,
        grid_idx = grid_idx,
        watchers = false,
        objs = {},
        touchs = false,
        merge = false,
        result = {},
    }
    return setmetatable(obj, grid_mt)
end


local function grid_touch(self)
    local aoi_obj = self.aoi_obj
    local touch_grididx_map = aoi_obj.touch_grididx_map
    local grid_idx = self.grid_idx
    if not touch_grididx_map[grid_idx] then
        touch_grididx_map[grid_idx] = true
        aoi_obj.touch_grid_count = aoi_obj.touch_grid_count + 1
    end
end

local function grid_watch(self, is_remove)
    local aoi_obj = self.aoi_obj
    local watch_grididx_map = aoi_obj.watch_grididx_map
    local grid_idx = self.grid_idx
    if not watch_grididx_map[grid_idx] then
        if not is_remove then
            watch_grididx_map[grid_idx] = true
            aoi_obj.watch_grid_count = aoi_obj.watch_grid_count + 1
        else
            error(string.format("grid_watch remove is invalid grid_idx:%s", grid_idx))
        end
    elseif is_remove then
        watch_grididx_map[grid_idx] = nil
        aoi_obj.watch_grid_count = aoi_obj.watch_grid_count - 1
    end
end


local function expand_marked(marked)
    local is_watcher = (marked & 0x02) ~= 0
    local is_maker = (marked & 0x01) ~= 0
    assert(is_watcher or is_maker)
    return is_watcher, is_maker
end

function grid_mt:grid_add(id, marked, pos_x, pos_y)
    local is_watcher, is_maker = expand_marked(marked)
    if is_maker then
        local touchs = self.touchs
        if self.objs[id] then
            error(string.format("duplicate grid_add maker id:%s to objs", id))
        elseif touchs and touchs[id] then
            error(string.format("duplicate grid_add maker id:%s to touchs", id))
        end

        if not touchs then
            touchs = {}
            self.touchs = touchs
        end
        touchs[id] = {
            id = id,
            pos_x = pos_x,
            pos_y = pos_y,
            status = "A",
        }
    end

    if is_watcher then
        local watchers = self.watchers
        if not watchers then
            watchers = {}
            self.watchers = watchers
        end
        if watchers[id] then
            error(string.format("duplicate grid_add maker id:%s to watchers", id))
        end
        watchers[id] = true
        grid_watch(self)
    end
    grid_touch(self)
end



function grid_mt:grid_delete(id)
    local objs = self.objs
    local not_find = 0
    if objs[id] then
        local touchs = self.touchs or {}
        touchs[id] = "D"
        self.touchs = touchs
    else
        local touchs = self.touchs
        if touchs and touchs[id] then
            touchs[id] = nil
        else
            not_find = not_find + 1
        end
    end

    local watchers = self.watchers
    if watchers and watchers[id] then
        watchers[id] = nil
        if not next(watchers) then
            grid_watch(self, true)
        end
    else
        not_find = not_find + 1
    end

    if not_find >= 2 then
        error(string.format("invalid grid_delete obj:%s id", id))
    end
    grid_touch(self)
end


function grid_mt:grid_update(id, pos_x, pos_y)
    local objs = self.objs
    local touchs = self.touchs or {}
    self.touchs = touchs
    if objs[id] then
        local touch_obj = touchs[id]
        if touch_obj == "D" then
            error(string.format("error grid_update status:D id:%s from grid_idx:%s", id, self.grid_idx))
        elseif not touch_obj then
            touch_obj = {
                id = id,
                status = "U",
            }
            touchs[id] = touch_obj
        end
        touch_obj.pos_x = pos_x
        touch_obj.pos_y = pos_y
    else
        local touch_obj = touchs[id]
        if not touch_obj or touch_obj == "D" then
            error(string.format("error grid_update no exist id:%s from grid_idx:%s", id, self.grid_idx))
        else
            touch_obj.pos_x = pos_x
            touch_obj.pos_y = pos_y
        end
    end
    grid_touch(self)
end



local function aoi_new(map_row, map_col, grid_row, grid_col)
    assert(grid_row <= map_row and grid_col <= map_col)
    local obj = {
        map_row = map_row,
        map_col = map_col,
        grid_row = grid_row,
        grid_col = grid_col,
        max_col_count = math.ceil(map_col / grid_col),
        max_row_count = math.ceil(map_row / grid_row),
        grid_pool = {},
        objid_to_grididx = {},
        objid_to_marked = {},

        watch_grididx_map = {},
        watch_grid_count = 0,
        last_watchid_to_grididx = {},

        -- need clear after update
        touch_grididx_map = {},
        touch_grid_count = 0,
        touch_grid_result = {},
    }
    return setmetatable(obj, aoi_mt)
end

local function get_gridobj_by_idx(self, grid_idx)
    return self.grid_pool[grid_idx]
end


local function get_gridobj_by_pos(self, pos_x, pos_y)
    local map_row = self.map_row
    local map_col = self.map_col
    if pos_y < 0 or pos_y >= map_row or pos_x < 0 or pos_x >= map_col then
        return nil
    end

    local grid_row = self.grid_row
    local grid_col = self.grid_col
    local max_col_count = self.max_col_count
    local grid_idx = (pos_y//grid_row)*max_col_count +  pos_x//grid_col + 1
    local grid_obj = self.grid_pool[grid_idx]
    if not grid_obj then
        grid_obj = grid_new(self, grid_idx)
        self.grid_pool[grid_idx] = grid_obj
    end
    return grid_obj
end



function aoi_mt:aoi_add(obj_id, marked, pos_x, pos_y)
    local cur_grid_idx = self.objid_to_grididx[obj_id]
    if cur_grid_idx then
        error(string.format("duplicate aoi_add obj_id:%s", obj_id))
    end

    --- add  new obj to grid
    local grid_obj = get_gridobj_by_pos(self, pos_x, pos_y)
    local grid_idx = grid_obj.grid_idx
    grid_obj:grid_add(obj_id, marked, pos_x, pos_y)
    self.objid_to_grididx[obj_id] = grid_idx
    self.objid_to_marked[obj_id] = marked
end



function aoi_mt:aoi_remove(obj_id)
    local cur_grid_idx = self.objid_to_grididx[obj_id]
    if not cur_grid_idx then
        error(string.format("no exist aoi_remove obj_id:%s", obj_id))
    end

    --- delete obj from grid
    local cur_grid_obj = get_gridobj_by_idx(self, cur_grid_idx)
    cur_grid_obj:grid_delete(obj_id)
    self.objid_to_grididx[obj_id] = nil
    self.objid_to_marked[obj_id] = nil
end


function aoi_mt:aoi_set(obj_id, pos_x, pos_y)
    local cur_grid_idx = self.objid_to_grididx[obj_id]
    if not cur_grid_idx then
        error(string.format("no exist aoi_set obj_id:%s", obj_id))
    end

    --- update obj from grid
    local new_grid_obj = get_gridobj_by_pos(self, pos_x, pos_y)
    if new_grid_obj.grid_idx == cur_grid_idx then
        new_grid_obj:grid_update(obj_id, pos_x, pos_y)

    -- move obj to other grid
    else
        local cur_grid_obj = get_gridobj_by_idx(self, cur_grid_idx)
        cur_grid_obj:grid_delete(obj_id)
        local marked = self.objid_to_marked[obj_id]
        new_grid_obj:grid_add(obj_id, marked, pos_x, pos_y)
        self.objid_to_grididx[obj_id] = new_grid_obj.grid_idx
    end
end


local function aoi_get_9_gridobj_by_center_gridobj(self, grid_obj, ret_tbl)
    local n = 0
    local cur_grididx = grid_obj.grid_idx
    local max_col_count = self.max_col_count
    local grid_pool = self.grid_pool
    for i=-1,1 do
        for j=-1,1 do
            local k = i*max_col_count + cur_grididx + j
            local v = grid_pool[k]
            if v then
                n = n + 1
                ret_tbl[n] = v
            end
        end
    end
    return n
end


local function grid_get_merge_objs(self)
    if not self.merge then
        local touchs = self.touchs
        local objs = self.objs
        if not touchs or not next(touchs) then
            self.merge = objs
        else
            local merge = {}
            for obj_id,v in pairs(touchs) do
                local status = v ~= "D" and v.status or "D"
                if status == "A" or status == "U" then
                    merge[obj_id] = {
                        id = obj_id,
                        pos_x = v.pos_x,
                        pos_y = v.pos_y,
                    }
                end
            end
            for obj_id,v in pairs(objs) do
                local tv = touchs[obj_id]
                if not tv then
                    merge[obj_id] = v
                end
            end
            self.merge = merge
        end
    end
    return self.merge
end


local function grid_touch_result(self)
    self.aoi_obj.touch_grid_result[self] = true
end


local function grid_get_gu_data(self)
    local gu_data = self.result["GU"]
    if gu_data then
        return gu_data
    end

    local touchs = self.touchs
    if touchs then
        local ret = next(touchs) and {} or nil
        for obj_id,v in pairs(touchs) do
            local status = v ~= "D" and v.status or "D"
            local pos_x = status ~= "D" and v.pos_x or nil
            local pos_y = status ~= "D" and v.pos_y or nil
            ret[obj_id] = {
                id = obj_id,
                pos_x = pos_x,
                pos_y = pos_y,
                status = status,
            }
        end
        self.result["GU"] = ret
        if ret then
            grid_touch_result(self)
        end
        return ret
    end
    return nil
end


local function grid_get_gd_data(self)
    local gd_data = self.result["GD"]
    if gd_data then
        return gd_data
    end

    local objs = self.objs
    local ret = next(objs) and {} or nil
    for obj_id,v in pairs(objs) do
        ret[obj_id] = {
            id = obj_id,
            pos_x = v.pos_x,
            pos_y = v.pos_y,
            status = "D",
        }
    end
    self.result["GD"] = ret
    if ret then
        grid_touch_result(self)
    end
    return ret
end


local function grid_get_ga_data(self)
    local ga_data = self.result["GA"]
    if ga_data then
        return ga_data
    end

    local merge = grid_get_merge_objs(self)
    local ret = next(merge) and {} or nil
    for obj_id,v in pairs(merge) do
        ret[obj_id] = {
            id = obj_id,
            pos_x = v.pos_x,
            pos_y = v.pos_y,
            status = "A",
        }
    end
    self.result["GA"] = ret
    if ret then
        grid_touch_result(self)
    end
    return ret
end


local function aoi_do_message(self, grid_obj, grid_status, watcher_id, result_tbl)
    local watch_ret = result_tbl[watcher_id]
    if not watch_ret then
        watch_ret = {}
        result_tbl[watcher_id] = watch_ret
    end

    local data = nil
    if grid_status == "GU" then
        data = grid_get_gu_data(grid_obj)

    elseif grid_status == "GD" then
        data = grid_get_gd_data(grid_obj)

    elseif grid_status == "GA" then
        data = grid_get_ga_data(grid_obj)

    else
        error(string.format("invalid grid_status:%s", grid_status))
    end
    watch_ret[#watch_ret+1] = data
end


local TMP = {}
local LEFT, RIGHT = {}, {}
local function aoi_resolve_change_watcher(self, cur_grid_obj, last_grid_obj, watcher_id, result_tbl)
    local function list_to_map(list, n, map)
        for i=1,n do
            local v = list[i]
            map[v] = true
            list[i] = nil
        end
        return map
    end

    local n
    if last_grid_obj then
        n = aoi_get_9_gridobj_by_center_gridobj(self, last_grid_obj, TMP)
        list_to_map(TMP, n, LEFT)
    end

    n = aoi_get_9_gridobj_by_center_gridobj(self, cur_grid_obj, TMP)
    list_to_map(TMP, n, RIGHT)

    if last_grid_obj then
        if  LEFT[last_grid_obj] and LEFT[cur_grid_obj] and
            RIGHT[last_grid_obj] and RIGHT[cur_grid_obj] then
            aoi_do_message(self, last_grid_obj, "GU", watcher_id, result_tbl)
            aoi_do_message(self, cur_grid_obj, "GU", watcher_id, result_tbl)
            LEFT[last_grid_obj] = nil
            LEFT[cur_grid_obj] = nil
            RIGHT[last_grid_obj] = nil
            RIGHT[cur_grid_obj] = nil
        end
        for grid_obj,_ in pairs(LEFT) do
            if RIGHT[grid_obj] then
                aoi_do_message(self, grid_obj, "GU", watcher_id, result_tbl)
                RIGHT[grid_obj] = nil
            else
                aoi_do_message(self, grid_obj, "GD", watcher_id, result_tbl)
            end
            LEFT[grid_obj] = nil
        end
    end
    for grid_obj,_ in pairs(RIGHT) do
        aoi_do_message(self, grid_obj, "GA", watcher_id, result_tbl)
        RIGHT[grid_obj] = nil
    end
end


local GRIDS_TMP = {}
local function aoi_resolve_watcher(self, grid_obj, result_tbl)
    local watchers = grid_obj.watchers
    local cur_grididx = grid_obj.grid_idx
    local last_watchid_to_grididx = self.last_watchid_to_grididx
    local n = aoi_get_9_gridobj_by_center_gridobj(self, grid_obj, GRIDS_TMP)
    for watcher_id,_ in pairs(watchers) do
        local last_grididx = last_watchid_to_grididx[watcher_id]
        if last_grididx == cur_grididx then
            for i=1,n do
                local v = GRIDS_TMP[i]
                aoi_do_message(self, v, "GU", watcher_id, result_tbl)
            end
        else
            local last_grid_obj = last_grididx and get_gridobj_by_idx(self, last_grididx) or false
            assert(grid_obj ~= last_grid_obj)
            aoi_resolve_change_watcher(self, grid_obj, last_grid_obj, watcher_id, result_tbl)
            last_watchid_to_grididx[watcher_id] = cur_grididx
        end
    end
end


local function aoi_get_need_sync_watch_gridobjs_by_touch(self)
    local ret_tbl = {}
    local touch_grididx_map = self.touch_grididx_map
    local set_map = {}
    for grid_idx,_ in pairs(touch_grididx_map) do
        local grid_obj = get_gridobj_by_idx(self, grid_idx)
        local n = aoi_get_9_gridobj_by_center_gridobj(self, grid_obj, TMP)
        for i=1,n do
            local v = TMP[i]
            TMP[i] = nil
            local watcher_grididx = v.grid_idx
            local watchers = v.watchers
            local has_watchers = watchers and next(watchers)
            if has_watchers and not set_map[watcher_grididx] then
                ret_tbl[#ret_tbl+1] = v
                set_map[watcher_grididx] = true
            end
        end
    end
    return ret_tbl
end


local function aoi_clear_all_touch_result(self)
    local touch_grid_result = self.touch_grid_result
    for grid_obj,_ in pairs(touch_grid_result) do
        local result = grid_obj.result
        for k,_ in pairs(result) do
            result[k] = nil
        end
        touch_grid_result[grid_obj] = nil
    end
end


local function aoi_clear_all_touch_gridobjs(self)
    local touch_grididx_map = self.touch_grididx_map
     for grid_idx,_ in pairs(touch_grididx_map) do
        touch_grididx_map[grid_idx] = nil
        local grid_obj = get_gridobj_by_idx(self, grid_idx)
        local touchs = grid_obj.touchs
        local merge = grid_obj.merge
        if merge then
            grid_obj.merge = false
            grid_obj.objs = merge
            grid_obj.touchs = false
        elseif touchs then
            local objs = grid_obj.objs
            for obj_id,v in pairs(touchs) do
                local status = v ~= "D" and v.status or "D"
                touchs[obj_id] = nil
                if status == "A" or status == "U" then
                    v.status = nil
                    objs[obj_id] = v
                elseif status == "D" then
                    objs[obj_id] = nil
                else
                    error(string.format("error obj status:%s when resolve touch gridobj", status))
                end
            end
        end
     end
     self.touch_grid_count = 0
end


--[[
status = "D" -- delete obj
status = "A" -- insert obj
status = "U" -- change obj
local function handle_cb(watcher_id, maker_id, status, pos_x, pos_y) end
]]
function aoi_mt:aoi_update()
    local result_tbl = {}
    -- get watch grids from watch_grididx_map
    if self.touch_grid_count * 4 > self.watch_grid_count then
        for grid_idx,_ in pairs(self.watch_grididx_map) do
            local grid_obj = get_gridobj_by_idx(self, grid_idx)
            aoi_resolve_watcher(self, grid_obj, result_tbl)
        end
    -- get watch grids from touch_grididx_map
    else
        local t = aoi_get_need_sync_watch_gridobjs_by_touch(self)
        for _,grid_obj in ipairs(t) do
            aoi_resolve_watcher(self, grid_obj, result_tbl)
        end
    end

    -- clear all touch grid obj
    aoi_clear_all_touch_gridobjs(self)
    -- clear all result grid obj
    aoi_clear_all_touch_result(self)
    return result_tbl
end


return {
    aoi_new = aoi_new,
    WATCHER_MARK = WATCHER_MARK,
    MAKER_MARK = MAKER_MARK,
}

