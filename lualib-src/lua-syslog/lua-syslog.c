#include <syslog.h>

#include <lua.h>
#include <lauxlib.h>

/*
 * args: appname, priority, msg
 *
 */
static int facilitys[] = {
    LOG_LOCAL0,
    LOG_LOCAL1,
    LOG_LOCAL2,
    LOG_LOCAL3,
    LOG_LOCAL4,
    LOG_LOCAL5,
    LOG_LOCAL6,
    LOG_LOCAL7,
};

static int
_openlog(lua_State *L) {
    const char* appname = luaL_checkstring(L, 1);
    int logid           = luaL_checkinteger(L, 2);
    int to_screen       = luaL_checkinteger(L, 3);

    int index    = logid % (sizeof(facilitys)/sizeof(int));
    int facility = facilitys[index];

    if(to_screen) openlog(appname, LOG_ODELAY | LOG_PERROR, facility);
    else openlog(appname, LOG_ODELAY, facility);
    return 0;
}

static int
_closelog(lua_State *L) {
    closelog();
    return 0;
}

static int
_log(lua_State *L) {
    int   priority  = LOG_PRI(luaL_checkinteger(L, 1));
    const char* msg = luaL_checkstring(L, 2);

    int facility = 0;
    if (lua_gettop(L) >= 3) {
        int logid = luaL_checkinteger(L, 3);
        int index = logid % (sizeof(facilitys)/sizeof(int));
        facility  = facilitys[index];
    }

    syslog(facility | priority, "%s", msg);
    return 0;
}

int luaopen_syslog(lua_State *L) {
    luaL_checkversion(L);

    luaL_Reg l[] = {
        {"openlog", _openlog},
        {"closelog", _closelog},
        {"log", _log},
        {NULL, NULL},
    };

    luaL_newlib(L, l);
    return 1;
}