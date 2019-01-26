SKYNET_ROOT ?= ../skynet/
include $(SKYNET_ROOT)platform.mk

SKYNET_LUA_INC ?= $(SKYNET_ROOT)/3rd/lua
SKYNET_LUA_LIB ?= $(SKYNET_ROOT)/3rd/lua/

LUA_CLIB_PATH ?= luaclib/

TERMFX_INC ?= termfx/
LUASOCKET_INC ?= luasocket/

TERMFX_SO_NAME = termfx.so
LUASOCKET_NAME = socket.so

TERMFX_SO      			= $(LUA_CLIB_PATH)/$(TERMFX_SO_NAME)
LUASOCKET_SO 		 	= $(LUA_CLIB_PATH)/$(LUASOCKET_NAME)


all: $(TERMFX_SO) \
	$(LUASOCKET_SO) \

#####################################################

ifeq ($(PLAT),macosx)
OS = Darwin
else
OS = linux
endif

$(TERMFX_SO) : | $(LUA_CLIB_PATH)
	cd $(TERMFX_INC) && $(MAKE) OS=$(OS) LUA_INCLUDE_DIR=../$(SKYNET_LUA_INC) && cp -f $(TERMFX_SO_NAME) ../$(LUA_CLIB_PATH)

$(LUASOCKET_SO) : $(LUASOCKET_INC)
	PLAT=$(PLAT) DEBUG=NODEBUG LUAV=5.3 LUAINC_$(PLAT)=../$(SKYNET_LUA_INC) $(MAKE) -C $(LUASOCKET_INC)
	cp -f $(LUASOCKET_INC)src/socket-3.0-rc1.so $@

#####################################################

clean:
	rm -f $(LUA_CLIB_PATH)/*.so

.PHONY: all clean
