#
# Use luarocks to install LuaFFI:
# > git clone https://github.com/facebook/luaffifb
# > cd luaffifb && luarocks make
#
# To rebuild the call_* headers:
# > rm call_*.h && make headers
#


LUA_INCLUDE_DIR ?=../../skynet/3rd/lua
LUA=./$(LUA_INCLUDE_DIR)/lua


.PHONY: all clean test


LUA_CFLAGS= -I$(LUA_INCLUDE_DIR)
SOCFLAGS=-fPIC
SOCC=$(CC) -shared $(SOCFLAGS)
CFLAGS=-fPIC -g -O2 -Wall  $(LUA_CFLAGS) -fvisibility=hidden -Wno-unused-function --std=gnu99
MODSO=ffi.so

all:
	if [ `uname` = "Darwin" ]; then $(MAKE) macosx; else $(MAKE) posix; fi

test:
	if [ `uname` = "Darwin" ]; then $(MAKE) test_macosx; else $(MAKE) test_posix; fi

macosx:
	$(MAKE) posix "SOCC=MACOSX_DEPLOYMENT_TARGET=10.3 $(CC) -dynamiclib -single_module -undefined dynamic_lookup $(SOCFLAGS)"

test_macosx:
	$(MAKE) test_posix "SOCC=MACOSX_DEPLOYMENT_TARGET=10.3 $(CC) -dynamiclib -single_module -undefined dynamic_lookup $(SOCFLAGS)"

posix: $(MODSO) test_cdecl.so

clean:
	rm -f *.o *.so call_*.h

call_x86.h: call_x86.dasc dynasm/*.lua
	$(LUA) dynasm/dynasm.lua -LN -o $@ $<

call_x64.h: call_x86.dasc dynasm/*.lua
	$(LUA) dynasm/dynasm.lua -D X64 -LN -o $@ $<

call_x64win.h: call_x86.dasc dynasm/*.lua
	$(LUA) dynasm/dynasm.lua -D X64 -D X64WIN -LN -o $@ $<

%.o: %.c *.h dynasm/*.h call_x86.h call_x64.h call_x64win.h
	$(CC) $(CFLAGS) -o $@ -c $<

$(MODSO): ffi.o ctype.o parser.o call.o
	$(SOCC) $^ -o $@

test_cdecl.so: test.o
	$(SOCC) $^ -o $@

test_posix: test_cdecl.so $(MODSO)
	LD_LIBRARY_PATH=$(LUA_INCLUDE_DIR) $(LUA) test.lua

