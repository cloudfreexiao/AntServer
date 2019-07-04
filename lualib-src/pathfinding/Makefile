all : pathfinding.dll

LUA_INCLUDE = /usr/local/include
LUA_LIB = -L/usr/local/bin -llua53

pathfinding.dll : pathfinding.c
	gcc -g -Wall --shared -o $@ $^ -I$(LUA_INCLUDE) $(LUA_LIB)

clean :
	rm pathfinding.dll
