THIRD_LIB_ROOT ?= 3rd/
CLIENT_DEPS ?= lua_httpws/

SKYNET_ROOT ?= skynet/
SKYNET_LUA_BIN ?= $(SKYNET_ROOT)/3rd/lua/lua

SKYNET_DEPS ?= lualib-src/

PLAT ?= linux

TLS_MODULE ?= ltls 
TLS_LIB ?= /usr/local/ssl/lib
TLS_INC ?= /usr/local/include



.PHONY: all 

all : skynetruntime skynetdeps clientdeps 


clientdebug: CLIENT_DEBUG := true

clientdebug: | client

client:
	@if [ ! -f "client/client.lua" ]; then cp client/client_template.lua client/client.lua; fi
	$(SKYNET_LUA_BIN) client/client.lua $(CLIENT_DEBUG) $(UIN)

skynetruntime:
	cd $(SKYNET_ROOT) && $(MAKE) $(PLAT) TLS_MODULE=$(TLS_MODULE) TLS_LIB=$(TLS_LIB) TLS_INC=$(TLS_INC)

third_part:
	cd $(THIRD_LIB_ROOT) && $(MAKE)

skynetdeps:
	cd $(SKYNET_DEPS) && $(MAKE) $(PLAT) TLS_LIB=$(TLS_LIB) TLS_INC=$(TLS_INC)

clientdeps:
	cd $(CLIENT_DEPS) && $(MAKE) $(PLAT)

cleanall:
	cd $(SKYNET_ROOT) && $(MAKE) cleanall
	cd $(CLIENT_DEPS) && $(MAKE) clean 
	cd $(SKYNET_DEPS) && $(MAKE) clean 
