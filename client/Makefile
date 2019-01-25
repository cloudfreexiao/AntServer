SKYNET_ROOT ?= ../skynet/
include $(SKYNET_ROOT)platform.mk

SKYNET_LUA_INC ?= $(SKYNET_ROOT)3rd/lua
SKYNET_LUA_LIB ?= $(SKYNET_ROOT)3rd/lua/

LUA_CLIB_PATH 	?= luaclib

TERMFX_INC		?= ./termfx
LUASOCKET_INC	?= ./luasocket

TERMFX_SO ?= termfx.so
SOCKET_SO ?= socket.so
TERMFX_SO_PATH		?= $(LUA_CLIB_PATH)/$(TERMFX_SO)
SOCKET_SO_PATH 		?= $(LUA_CLIB_PATH)/socket.so

ifeq ($(PLAT),macosx)
OS = Darwin.3
else
OS = linux
endif

all: $(TERMFX_SO_PATH)   \
	$(SOCKET_SO_PATH)  \
	
$(TERMFX_SO): | $(LUA_CLIB_PATH)
	cd $(TERMFX_INC) && $(MAKE) LUA_INCDIR=../$(SKYNET_LUA_INC) LUA_LIBDIR=../$(SKYNET_LUA_LIB) OS=$(OS) && cp -f $(TERMFX_SO) ../$(LUA_CLIB_PATH)

$(SOCKET_SO_PATH) : | $(LUA_CLIB_PATH)
	cd $(LUASOCKET_INC) && $(MAKE) $(PLAT) LUAINC=../$(SKYNET_LUA_INC) && cp $(SOCKET_SO) ../$(LUA_CLIB_PATH)

clean:
	rm -f $(LUA_CLIB_PATH)/*.so

.PHONY: all clean
