THIRD_LIB_ROOT ?= ../3rd/
SKYNET_ROOT ?= ../skynet/
include $(SKYNET_ROOT)platform.mk


SKYNET_LUA_INC ?= $(SKYNET_ROOT)/3rd/lua
SKYNET_LUA_LIB ?= $(SKYNET_ROOT)/3rd/lua/
SKYNET_SRC ?= $(SKYNET_ROOT)/skynet-src

LFLAGS = $(SHARED) -I$(SKYNET_LUA_INC) -llua -L$(SKYNET_LUA_LIB) 

CURL_LIB ?= $(THIRD_LIB_ROOT)curl/lib/.libs/libcurl.a
CURL_INC ?= $(THIRD_LIB_ROOT)curl/include
CURL_SRC ?= $(THIRD_LIB_ROOT)curl/src

CRAB_INC ?= crab/
CJSON_INC ?= lua-cjson/
LFS_INC ?= luafilesystem/src
CAOI_INC ?= skynet_aoi/

LUA_CLIB_PATH ?= ../luaclib

HASH_SO      			= $(LUA_CLIB_PATH)/hash.so
LFS_SO 		 			= $(LUA_CLIB_PATH)/lfs.so
WEBCLIENT_SO 			= $(LUA_CLIB_PATH)/webclient.so
UTF8_SO 	 			= $(LUA_CLIB_PATH)/utf8.so
CRAB_SO 	 			= $(LUA_CLIB_PATH)/crab.so
WEBSOCKETNETPACK_SO		= $(LUA_CLIB_PATH)/websocketnetpack.so
CJSON_SO				= $(LUA_CLIB_PATH)/cjson.so
CAOI_SO					= $(LUA_CLIB_PATH)/caoi.so


all: $(HASH_SO) $(LFS_SO) $(WEBCLIENT_SO) $(UTF8_SO) $(CRAB_SO) \
	$(WEBSOCKETNETPACK_SO) $(CJSON_SO) $(CAOI_SO) \

#####################################################

$(HASH_SO): lua-hash.c $<
	$(CC) $(LFLAGS) -o $@ 

$(LFS_SO) :luafilesystem/src/lfs.c $<
	$(CC) $(LFLAGS) -o $@ -I$(LFS_INC)

$(WEBCLIENT_SO):lua-webclient.c
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< $(CURL_LIB) -I$(CURL_INC)

$(UTF8_SO): crab/lua-utf8.c $<
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -I$(CRAB_INC)

$(CRAB_SO): crab/lua-crab.c $<
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -I$(CRAB_INC)

$(WEBSOCKETNETPACK_SO):lua-websocketnetpack.c
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -I$(SKYNET_SRC)

$(CJSON_SO) : | $(LUA_CLIB_PATH)
	cd $(CJSON_INC) && $(MAKE) LUA_INCLUDE_DIR=../$(SKYNET_ROOT)/3rd/lua CC=$(CC) CJSON_LDFLAGS="$(SHARED)" && cp cjson.so ../$(LUA_CLIB_PATH)


#####################################################

$(CAOI_SO):
	cd $(CAOI_INC) && $(MAKE)



clean:
	rm -f $(LUA_CLIB_PATH)/*.so


.PHONY: all clean
