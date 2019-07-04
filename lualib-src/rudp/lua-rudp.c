#define LUA_LIB

#include "rudp.h"

#include <lua.h>
#include <lauxlib.h>

#include <string.h>
#include <assert.h>

#define MAX_FROM_LEN (256)

struct rudp_aux {
	lua_State *L;
	struct rudp *u;
	size_t sz;
	char from[MAX_FROM_LEN];
	char buffer[MAX_PACKAGE];
};

static int
lsend(lua_State *L) {
	struct rudp_aux *aux = (struct rudp_aux *)lua_touserdata(L, 1);
	size_t sz = 0;
	const char *buffer = luaL_checklstring(L, 2, &sz);
	rudp_send(aux->u, buffer, sz);
	return 0;
}

static int
lupdate(lua_State *L) {
	struct rudp_aux *aux = (struct rudp_aux *)lua_touserdata(L, 1);
	int tick = lua_tointeger(L, 2);

	size_t sz = 0;
	const char *buffer = NULL;
	if (lua_type(L, 3) == LUA_TSTRING) {
		buffer = luaL_checklstring(L, 3, &sz);	
	}
	
	lua_geti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
	lua_rawgetp(L, -1, aux);
	lua_getfield(L, -1, "send"); // -2
	lua_getfield(L, -2, "recv"); // -1

	struct rudp_package *res = rudp_update(aux->u, buffer, sz, tick);
	while (res) {
		lua_pushvalue(L, -2);  // send func
		lua_pushvalue(L, 1);   // u
		lua_pushlstring(L, aux->from, aux->sz); // from
		lua_pushlstring(L, res->buffer, res->sz);         // data
		lua_pcall(L, 3, 0, 0);
		res = res->next;
	}
	int n;
	while ((n = rudp_recv(aux->u, aux->buffer))) {
		if (n < 0) {
			break;
		}
		lua_pushvalue(L, -1);    // recv
		lua_pushvalue(L, 1);     // u
		lua_pushlstring(L, aux->from, aux->sz); // from
		lua_pushlstring(L, aux->buffer, n);               // data
		lua_pcall(L, 3, 0, 0);
	}
	return 0;
}

static int
lset_from(lua_State *L) {
	struct rudp_aux *aux = (struct rudp_aux *)lua_touserdata(L, 1);
	size_t sz = 0;
	const char *addr = luaL_checklstring(L, 2, &sz);
	assert(sz <= MAX_FROM_LEN);
	memset(aux->from, 0, 256);
	memcpy(aux->from, addr, sz);
	aux->sz = sz;
	return 0;
}

static int
lget_from(lua_State *L) {
	struct rudp_aux *aux = (struct rudp_aux *)lua_touserdata(L, 1);
	lua_pushstring(L, aux->from);
	return 1;
}

static int
lfree(lua_State *L) {
	if (lua_gettop(L) >= 1) {
		struct rudp_aux *aux = (struct rudp_aux *)lua_touserdata(L, 1);
		rudp_delete(aux->u);
		return 0;
	} else {
		luaL_error(L, "must be.");
		return 0;
	}
}

static int 
lalloc(lua_State *L) {
	struct rudp_aux *aux = (struct rudp_aux *)lua_newuserdata(L, sizeof(*aux));
	if (aux == NULL) {
		luaL_error(L, "new udata failture.");
		return 0;
	} else {
		lua_pushvalue(L, lua_upvalueindex(1));
		lua_setmetatable(L, -2);

		aux->L = L;
		lua_geti(L, LUA_REGISTRYINDEX, LUA_RIDX_GLOBALS);
		lua_newtable(L);
		lua_pushvalue(L, 1);
		lua_setfield(L, -2, "send");
		lua_pushvalue(L, 2);
		lua_setfield(L, -2, "recv");

		lua_rawsetp(L, -2, aux);
		lua_pop(L, 1);
		
		struct rudp *U = rudp_new(1, 5);
		aux->u = U;
		memset(aux->buffer, 0, MAX_PACKAGE);
		return 1;
	}
}

LUAMOD_API int
luaopen_chestnut_rudp(lua_State *L) {
	luaL_checkversion(L);
	lua_newtable(L); // met
	luaL_Reg l[] = {
		{ "send", lsend },
		{ "update", lupdate },
		{ "set_from", lset_from },
		{ "get_from", lget_from },
		{ NULL, NULL },
	};
	luaL_newlib(L,l);
	lua_setfield(L, -2, "__index");
	lua_pushcclosure(L, lfree, 0);
	lua_setfield(L, -2, "__gc");
	lua_pushcclosure(L, lalloc, 1);
	return 1;
}