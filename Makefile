THIRD_LIB_ROOT ?= 3rd/
CLIENT_DEPS ?= client/

SKYNET_ROOT ?= skynet/
SKYNET_LUA_BIN ?= $(SKYNET_ROOT)/3rd/lua/lua

SKYNET_DEPS ?= lualib-src/

include $(SKYNET_ROOT)platform.mk

.PHONY: all 

all : skynet skynetdeps clientdeps 

clientdebug: CLIENT_DEBUG := true

clientdebug: | client

client:
	@if [ ! -f "client/client.lua" ]; then cp client/client_template.lua client/client.lua; fi
	$(SKYNET_LUA_BIN) client/client.lua $(CLIENT_DEBUG) $(UIN)

skynet:
	cd $(SKYNET_ROOT) && $(MAKE) $(PLAT)

third_part:
	cd $(THIRD_LIB_ROOT) && $(MAKE)

skynetdeps:
	cd $(SKYNET_DEPS) && $(MAKE) $(PLAT)

clientdeps:
	cd $(CLIENT_DEPS) && $(MAKE) $(PLAT)
