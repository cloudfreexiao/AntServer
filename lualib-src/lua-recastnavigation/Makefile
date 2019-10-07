
PLAT ?= none
TARGET ?= navigator.so

CXX=g++

ifeq ($(PLAT), macosx)
	CXXFLAGS = -O3 -Wall -pedantic -bundle -undefined dynamic_lookup
else
ifeq ($(PLAT), linux)
	CXXFLAGS = -O3 -Wall -shared -fPIC
endif
endif

LUA_INCLUDE_DIR ?= ../../skynet/3rd/lua/

DETOUR_DIR ?= ./recastnavigation/Detour
RECAST_DIR ?= ./recastnavigation/Recast

DETOUR_INC = $(DETOUR_DIR)/Include
RECAST_INC = $(RECAST_DIR)/Include

BUILD_CXXFLAGS = $(CXXFLAGS) -I$(LUA_INCLUDE_DIR) -I$(RECAST_INC) -I$(DETOUR_INC)

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
	$(CXX) $(BUILD_CXXFLAGS) -o $@ $^

clean:
	rm -f *.o $(TARGET)