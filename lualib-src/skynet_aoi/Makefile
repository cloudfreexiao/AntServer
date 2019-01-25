
SKYNET_ROOT ?= ../../skynet/
include $(SKYNET_ROOT)platform.mk

LUA_CLIB_PATH ?= $(SKYNET_ROOT)/../luaclib/

SKYNET_SRC ?= $(SKYNET_ROOT)skynet-src/
SKYNET_LUA_INC ?= $(SKYNET_ROOT)3rd/lua
SKYNET_LUA_LIB ?= $(SKYNET_ROOT)3rd/lua/


CAOI_SO = $(LUA_CLIB_PATH)/caoi.so
# LAOI_SO = $(LUA_CLIB_PATH)/laoi.so

LFLAGS = $(SHARED) -I$(SKYNET_LUA_INC) -llua -L$(SKYNET_LUA_LIB) 

all: $(CAOI_SO) #$(LAOI_SO)

$(CAOI_SO): service_aoi.c $<
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -I$(SKYNET_SRC)

# $(LAOI_SO): lua-aoi.c 
# 	gcc -O2 -Wall $^ -fPIC --shared -o $@  -llua -I$(SKYNET_SRC) -I$(SKYNET_LUA_INC)