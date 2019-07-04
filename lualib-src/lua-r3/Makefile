UNAME ?= $(shell uname)

CFLAGS := -O3 -g -Wall -fpic

C_SO_NAME := libr3.so
LDFLAGS := -shared

# on Mac OS X, one should set instead:
# for Mac OS X environment, use one of options
ifeq ($(UNAME),Darwin)
	LDFLAGS := -bundle -undefined dynamic_lookup
	C_SO_NAME := libr3.dylib
endif

MY_CFLAGS := $(CFLAGS) -DBUILDING_SO
MY_LDFLAGS := $(LDFLAGS) -fvisibility=hidden

OBJS := lua_r3.o
R3_FOLDER := r3
R3_CONGIGURE := $(R3_FOLDER)/configure
R3_STATIC_LIB := $(R3_FOLDER)/.libs/libr3.a

.PHONY: default
default: compile

### clean:        Remove generated files
.PHONY: clean
clean:
	rm -f $(C_SO_NAME) $(OBJS) ${R3_CONGIGURE}
	cd $(R3_FOLDER) && $(MAKE) clean

### compile:      Compile library
.PHONY: compile

compile: ${R3_CONGIGURE} ${R3_STATIC_LIB} #$(C_SO_NAME)

${OBJS} : %.o : %.c
	$(CC) $(MY_CFLAGS) -c $<

${C_SO_NAME} : ${OBJS}
	$(CC) $(MY_LDFLAGS) $(OBJS) $(R3_FOLDER)/.libs/libr3.a -o $@ 

${R3_CONGIGURE} :
	cd $(R3_FOLDER) && ./autogen.sh

${R3_STATIC_LIB} :
	cd $(R3_FOLDER) && ./configure && make


### help:         Show Makefile rules
.PHONY: help
help:
	@echo Makefile rules:
	@echo
	@grep -E '^### [-A-Za-z0-9_]+:' Makefile | sed 's/###/   /'
