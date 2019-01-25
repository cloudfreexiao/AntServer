#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdint.h>
#include <time.h>

#include "./aoi/aoi.h"

struct laoi_cookie {
    int count;
    int max;
    int current;
};

// 此结构体创建后,将不会释放掉,主要是用于预付中层操作失误(如多次执行gc)导致程序崩溃。它只会占用微不足道的内存。
struct laoi_space {
    uint32_t map_id;
    float map_x;
    float map_y;
    float map_z;
    struct aoi_space *space;
    struct laoi_cookie *cookie;
};

struct laoi_cb {
    lua_State *L;
    uint32_t cb_num;
    uint64_t begin_time;
    uint64_t end_time;
};

//获取linux系统启动到现在的微秒 1s=1000ms(毫秒)=1000000μs(微秒)
/*
struct timespec {
    time_t tv_sec;//秒
    long tv_nsec;//纳秒 10亿纳秒==1秒
}
 */
static uint64_t
aoi_gettime() {
    uint64_t t;
    struct timespec ti;
    clock_gettime(CLOCK_MONOTONIC_RAW, &ti); //单调递增时间
    t = (uint64_t)ti.tv_sec * 1000000;
    t += ti.tv_nsec / 1000;
    return t;
}

static void *
aoi_alloc(void *ud, void *ptr, size_t sz) {
    struct laoi_cookie *cookie = ud;
    if (ptr == NULL) {
        void *p = server_malloc(sz);
        ++cookie->count;
        cookie->current += sz;
        if (cookie->max < cookie->current)
        {
            cookie->max = cookie->current;
        }
        return p;
    }
    --cookie->count;
    cookie->current -= sz;
    server_free(ptr);
    return NULL;
}

static int
_aoi_create(lua_State *L) {
    uint32_t map_id = (uint32_t)lua_tointeger(L, 1);
    float map_x = (float)lua_tointeger(L, 2);
    float map_y = (float)lua_tointeger(L, 3);
    float map_z = (float)lua_tointeger(L, 4);
    if (map_id <= 0 || map_x <= 0 || map_y <= 0)
    {
        luaL_error(L, "aoi create map len error. id=>(%d) x=>(%f) y=>(%f)", map_id, map_x, map_y);
    }
    struct laoi_space *lspace = server_malloc(sizeof(*lspace));
    lspace->map_id = map_id;
    lspace->map_x = map_x;
    lspace->map_y = map_y;
    lspace->map_z = map_z;
    lspace->cookie = server_malloc(sizeof(struct laoi_cookie));
    lspace->cookie->count = 0;
    lspace->cookie->max = 0;
    lspace->cookie->current = 0;
    lspace->space = aoi_create(aoi_alloc, lspace->cookie);

    lua_pushlightuserdata(L, lspace);
    return 1;
}

static struct laoi_space *
get_lspace(lua_State *L, int index) {
    struct laoi_space *lspace = lua_touserdata(L, index);
    if (lspace == NULL) {
        luaL_error(L, "aoi lspace type (%s) must be a userdata.", lua_typename(L, lua_type(L, index)));
    }
    return lspace;
}

static int
_aoi_update(lua_State *L) {
    struct laoi_space *lspace = get_lspace(L, 1);
    struct aoi_space *space = lspace->space;
    uint32_t id = (uint32_t)lua_tointeger(L, 2);
    const char *mode = lua_tostring(L, 3);
    float pos_x = (float)lua_tointeger(L, 4);
    float pos_y = (float)lua_tointeger(L, 5);
    float pos_z = (float)lua_tointeger(L, 6);

    if (pos_x > lspace->map_x || pos_y > lspace->map_y || pos_z > lspace->map_z ||
        pos_x < 0 || pos_y < 0 || pos_z < 0) {
        luaL_error(L, "aoi update pos error. map_id=>%d map=>(%f,%f,%f) pos=>(%f,%f,%f)",
                lspace->map_id, pos_x, pos_y, pos_z, lspace->map_x, lspace->map_y, lspace->map_z);
    }

    float pos[3] = {pos_x, pos_y, pos_z};

    aoi_update(space, id, mode, pos);
    return 0;
}

static void
aoi_cb_message(void *ud, uint32_t watcher, uint32_t marker) {
    struct laoi_cb *clua = ud;
    clua->cb_num++;
    lua_State *L = clua->L;

    lua_pushnumber(L, clua->cb_num);
    lua_newtable(L);

    lua_pushstring(L, "w");
    lua_pushnumber(L, watcher);
    lua_rawset(L, -3);

    lua_pushstring(L, "m");
    lua_pushnumber(L, marker);
    lua_rawset(L, -3);

    lua_rawset(L, -3);
}

static int
_aoi_message(lua_State *L) {
    struct laoi_space *lspace = get_lspace(L, 1);
    struct aoi_space *space = lspace->space;
    struct laoi_cb clua = {L, 0, 0, 0};
    clua.begin_time = aoi_gettime();
    lua_newtable(L);
    aoi_message(space, aoi_cb_message, &clua);
    clua.end_time = aoi_gettime();

    lua_pushstring(L, "num");
    lua_pushnumber(L, clua.cb_num);
    lua_rawset(L, -3);

    lua_pushstring(L, "begin_time"); //微秒
    lua_pushnumber(L, clua.begin_time);
    lua_rawset(L, -3);

    lua_pushstring(L, "end_time"); //微秒
    lua_pushnumber(L, clua.end_time);
    lua_rawset(L, -3);

    return 1;
}

static int
_aoi_release(lua_State *L) {
    struct laoi_space *lspace = get_lspace(L, 1);
    struct aoi_space *space = lspace->space;
    if (space == NULL)
    {
        luaL_error(L, "aoi release space is null");
    }
    aoi_release(space);
    lspace->space = NULL;
    server_free(lspace->cookie);
    lspace->cookie = NULL;

    return 0;
}

static int
_aoi_dump(lua_State *L){
    struct laoi_space *lspace = get_lspace(L, 1);
    printf("map id = %u, count memory = %d, max memory = %d, current memory = %d\n",
    lspace->map_id, lspace->cookie->count, lspace->cookie->max, lspace->cookie->current);

    return 0;
}

int luaopen_aoi(lua_State *L) {
    luaL_checkversion(L);

    luaL_Reg l[] = {
        {"create", _aoi_create},
        {"update", _aoi_update},
        {"message", _aoi_message},
        {"release", _aoi_release},
        {"dump", _aoi_dump},
        {NULL, NULL},
    };

    luaL_newlib(L, l);

    return 1;
}
