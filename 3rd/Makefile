PLAT ?= linux

all : libcurl

libcurl:
	@cd ./curl && ./buildconf && ./configure && $(MAKE)

.PHONY: all
