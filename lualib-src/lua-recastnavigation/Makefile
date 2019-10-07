
PLAT ?= none
TARGET ?= navigator.so

CXX=g++

ifeq ($(PLAT), macosx)
	CXXFLAGS = -g -O2 -pedantic -bundle -undefined dynamic_lookup
else
ifeq ($(PLAT), linux)
	CXXFLAGS = -g -O2 -shared -fPIC
endif
endif

LUA_INC ?= ../../skynet/3rd/lua/
LUA_LIB = $(LUA_INC)/liblua.a

DETOUR_INC = recastnavigation/Detour/Include
RECAST_INC = recastnavigation/Recast/Include

DETOUR_SRC = DetourAlloc.cpp DetourCommon.cpp DetourNavMesh.cpp DetourNavMeshBuilder.cpp \
							DetourNavMeshBuilder.cpp  DetourNavMeshQuery.cpp DetourNode.cpp\

RECAST_SRC = Recast.cpp RecastAlloc.cpp RecastArea.cpp RecastContour.cpp RecastFilter.cpp RecastLayers.cpp\
							RecastMesh.cpp RecastMeshDetail.cpp RecastRasterization.cpp RecastRegion.cpp

UTIL_SRC = recastnavigator.cpp lua-recastnavigation.cpp

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(foreach v, $(DETOUR_SRC), recastnavigation/Detour/Source/$(v)) \
					$(foreach v, $(RECAST_SRC), recastnavigation/Recast/Source/$(v)) \
					$(foreach v, $(UTIL_SRC), $(v))
	$(CXX) $(CXXFLAGS) -o $@ $^ -I$(LUA_INC) -I$(RECAST_INC) -I$(DETOUR_INC)

clean:
	rm -f *.o $(TARGET)