#define LUA_LIB

#include <lua.h>
#include <lauxlib.h>


// defined in md5.c
int lmd5(lua_State *L);
int lhmac_md5(lua_State *L);

// defined in crc.c
int lcrc32(lua_State *L);
int lcrc64(lua_State *L);

// defined sha256.c
int lsha256(lua_State *L);
int lhmac_sha256(lua_State *L);

int lsha512(lua_State *L);
int lhmac_sha512(lua_State *L);

LUAMOD_API int
luaopen_cryptoaux(lua_State *L) {
	luaL_checkversion(L);
	static int init = 0;
	if (!init) {
		// Don't need call srandom more than once.
		init = 1 ;
		srandom((random() << 8) ^ (time(NULL) << 16) ^ getpid());
	}
	luaL_Reg l[] = {
		{ "md5", lmd5 },
		{ "hmac_md5", lhmac_md5 },
		{ "crc32", lcrc32 },
		{ "crc64", lcrc64 },
		{ "sha256", lsha256 },
		{ "sha512", lsha512 },
		{ "hmac_sha256", lhmac_sha256 },
		{ "hmac_sha512", lhmac_sha512 },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	return 1;
}
