local print_r = require "print_r"
local aoi = require "aoi"
local MAKER_MARK = aoi.MAKER_MARK
local WATCHER_MARK = aoi.WATCHER_MARK


local aoi_obj


local obj_idx = 0
local all_objs = {}
local function add_obj(marked, pos_x, pos_y)
    obj_idx = obj_idx + 1
    local v = {
        marked = marked,
        pos_x = pos_x,
        pos_y = pos_y,
        id = obj_idx,
    }
    all_objs[obj_idx] = v
    aoi_obj:aoi_add(obj_idx, marked, pos_x, pos_y)
    return obj_idx
end

local function del_obj(obj_id)
    all_objs[obj_id] = nil
    aoi_obj:aoi_remove(obj_id)
end


local function set_obj(obj_id, pos_x, pos_y)
    local v = all_objs[obj_id]
    v.pos_x = pos_x
    v.pos_y = pos_y
    aoi_obj:aoi_set(obj_id, pos_x, pos_y)
end


local watchers_map = {}
local function handle_func(watcher_id, maker_id, status, pos_x, pos_y)
    for k,v in pairs(watcher_id) do
        -- print(k,v)
    end
end



local function set_watcher(watcher_id, maker_id, status, pos_x, pos_y)
    print("set_watcher:", watcher_id, maker_id, status, pos_x, pos_y)
    local w = watchers_map[watcher_id] or {}
    watchers_map[watcher_id] = w
    local v = w[maker_id]
    if status == "A" then
        assert(not v)
        w[maker_id] = {
            id = maker_id,
            pos_x = pos_x,
            pos_y = pos_y,
        }
    elseif status == "D" then
        assert(v)
        w[maker_id] = nil
    elseif status == "U" then
        assert(v)
        v.pos_x = pos_x
        v.pos_y = pos_y
    else
        assert(false, status)
    end
end

local function check_aoi(ret)
    for watcher_id,t in pairs(ret) do
        for _,r in ipairs(t) do
            for maker_id,v in pairs(r) do
                set_watcher(watcher_id, maker_id, v.status, v.pos_x, v.pos_y)
            end
        end
    end

    local check_error = false
    for w_id,t in pairs(watchers_map) do
        for id,v in pairs(t) do
            local rv = all_objs[id]
            if not rv or rv.pos_x ~= v.pos_x or rv.pos_y ~= v.pos_y then
                check_error = true
                local rps = rv and string.format("(%s,%s)", rv.pos_x, rv.pos_y) or "nil"
                print(string.format("check_aoi error maker:%s pos:(%s,%s) real_pos:%s from watcher:%s",
                    v.id, v.pos_x, v.pos_y, rps, id))
            end
        end
    end
    print("check_aoi:", not check_error)
end


local function update_aoi(check)
    local b = os.clock()
    local ret = aoi_obj:aoi_update(handle_func)
    local e = os.clock()
    print("update_aoi cost:", e - b)
    -- print_r(ret)
    if check then
        check_aoi(ret)
    end
end

-- cost 1.243078s
local function m1_test()
    local m1_aoi = require "lgamescene.aoi"
    local world = m1_aoi.create_world(20, 20, 10)
    local p = {1}
    local n = 10000
    local b  = os.clock()
    for i=1,n do
        p[1] = i
        local ret = m1_aoi.add_obj(world, i, p, 10, 10, true, true)
        -- if i == n then
        --     print_r(ret)
        -- end
    end
    local e  = os.clock()
    print("m1_test cost:", e-b)
end


-- cost:0.028496s
local function test2()
    local n = 10000
    aoi_obj = aoi.aoi_new(10, 20, 10, 20)
    for i=1,n do
        add_obj(WATCHER_MARK | MAKER_MARK, 0, 0)
    end
    update_aoi()
end


local function test1()
    aoi_obj = aoi.aoi_new(10, 20, 3, 3)
    local obj1 = add_obj(WATCHER_MARK | MAKER_MARK, 0, 0)
    local obj2 = add_obj(WATCHER_MARK | MAKER_MARK, 19, 9)
    local obj3 = add_obj(WATCHER_MARK | MAKER_MARK, 2, 2)
    local obj4 = add_obj(WATCHER_MARK | MAKER_MARK, 3, 3)
    local obj5 = add_obj(WATCHER_MARK | MAKER_MARK, 6, 7)
    set_obj(obj4, 9, 9)
    set_obj(obj2, 0, 0)
    update_aoi(true)
    print("-----------")
    set_obj(obj1, 9, 9)
    set_obj(obj5, 4, 5)
    local obj6 = add_obj(MAKER_MARK, 10, 9)
    local obj7 = add_obj(MAKER_MARK, 10, 9)
    local obj8 = add_obj(MAKER_MARK, 10, 9)
    update_aoi(true)
    del_obj(obj6)
    set_obj(obj7, 0, 0)
    update_aoi(true)
end


test2()
-- test1()
-- m1_test()

