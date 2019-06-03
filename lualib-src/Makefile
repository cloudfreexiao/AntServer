THIRD_LIB_ROOT ?= ../3rd/
SKYNET_ROOT ?= ../skynet/
include $(SKYNET_ROOT)platform.mk


SKYNET_LUA_INC ?= $(SKYNET_ROOT)/3rd/lua
SKYNET_LUA_LIB ?= $(SKYNET_ROOT)/3rd/lua/
SKYNET_SRC ?= $(SKYNET_ROOT)/skynet-src

LFLAGS = $(SHARED) -I$(SKYNET_LUA_INC) -llua -L$(SKYNET_LUA_LIB) 

# CURL_LIB ?= $(THIRD_LIB_ROOT)curl/lib/.libs/libcurl.a
# CURL_INC ?= $(THIRD_LIB_ROOT)curl/include
# CURL_SRC ?= $(THIRD_LIB_ROOT)curl/src

TLS_LIB=/usr/local/ssl/lib
TLS_INC=/usr/local/include


CRAB_INC ?= crab/
CJSON_INC ?= lua-cjson/
LFS_INC ?= luafilesystem/src
CAOI_INC ?= skynet_aoi/


LUA_CLIB_PATH ?= ../luaclib

HASH_SO_NAME = hash.so
LFS_SO_NAME = lfs.so
WEBCLIENT_SO_NAME = webclient.so
UTF8_SO_NAME = utf8.so
CRAB_SO_NAME = crab.so
WEBSOCKETNETPACK_SO_NAME = websocketnetpack.so
CJSON_SO_NAME = cjson.so
CAOI_SO_NAME = caoi.so
AES_SO_NAME = aes.so
CODEC_SO_NAME = codec.so


HASH_SO      			= $(LUA_CLIB_PATH)/$(HASH_SO_NAME)
LFS_SO 		 			= $(LUA_CLIB_PATH)/$(LFS_SO_NAME)
WEBCLIENT_SO 			= $(LUA_CLIB_PATH)/$(WEBCLIENT_SO_NAME)
UTF8_SO 	 			= $(LUA_CLIB_PATH)/$(UTF8_SO_NAME)
CRAB_SO 	 			= $(LUA_CLIB_PATH)/$(CRAB_SO_NAME)
WEBSOCKETNETPACK_SO		= $(LUA_CLIB_PATH)/$(WEBSOCKETNETPACK_SO_NAME)
CJSON_SO				= $(LUA_CLIB_PATH)/$(CJSON_SO_NAME)
CAOI_SO					= $(LUA_CLIB_PATH)/$(CAOI_SO_NAME)
AES_SO                  = $(LUA_CLIB_PATH)/$(AES_SO_NAME)
CODEC_SO                = $(LUA_CLIB_PATH)/$(CODEC_SO_NAME)

#####################################################
all: $(HASH_SO) $(LFS_SO)  $(UTF8_SO) $(CRAB_SO) \
	$(WEBSOCKETNETPACK_SO) $(CJSON_SO) $(CAOI_SO) \
	$(AES_SO) $(CODEC_SO) \
#####################################################

$(HASH_SO): lua-hash.c $<
	$(CC) $(LFLAGS) -o $@ 

$(LFS_SO) :luafilesystem/src/lfs.c $<
	$(CC) $(LFLAGS) -o $@ -I$(LFS_INC)

# $(WEBCLIENT_SO):lua-webclient.c
# 	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< $(CURL_LIB) -I$(CURL_INC)

$(UTF8_SO): crab/lua-utf8.c $<
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -I$(CRAB_INC)

$(CRAB_SO): crab/lua-crab.c $<
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -I$(CRAB_INC)

$(WEBSOCKETNETPACK_SO):lua-websocketnetpack.c
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -I$(SKYNET_SRC)

$(CJSON_SO) : | $(LUA_CLIB_PATH)
	cd $(CJSON_INC) && $(MAKE) LUA_INCLUDE_DIR=../$(SKYNET_ROOT)/3rd/lua CC=$(CC) CJSON_LDFLAGS="$(SHARED)" && cp -f $(CJSON_SO_NAME) ../$(LUA_CLIB_PATH)

$(AES_SO): lua-aes.c $<
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -L$(TLS_LIB) -I$(TLS_INC) -lcrypto

$(CODEC_SO): lua-codec.c $<
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -L$(TLS_LIB) -I$(TLS_INC) -lcrypto

#####################################################

$(CAOI_SO):
	cd $(CAOI_INC) && $(MAKE)



clean:
	rm -f $(LUA_CLIB_PATH)/*.so


.PHONY: all clean
