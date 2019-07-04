#Project settings
PROJECT = fixmath
LIB = -llua -static -L../lua-5.3.5/install/lib
SRC = .
INC = -I. -I../lua-5.3.5/install/include

#Compiler settings
CPP = gcc
CC = gcc
AS = gcc
LD = gcc
AR = ar
CPP_FLAGS = -O2 -fPIC $(LIB) $(INC) -Wall -Wextra -c
CC_FLAGS  = -O2 -fPIC $(LIB) $(INC) -Wall -Wextra -c
AS_FLAGS  = $(CC_FLAGS) -D_ASSEMBLER_
LD_FLAGS = -Wall

# Find all source files
SRC_CPP = $(foreach dir, $(SRC), $(wildcard $(dir)/*.cpp))
SRC_C   = $(foreach dir, $(SRC), $(wildcard $(dir)/*.c))
SRC_S   = $(foreach dir, $(SRC), $(wildcard $(dir)/*.S))
OBJ_CPP = $(patsubst %.cpp, %.o, $(SRC_CPP))
OBJ_C   = $(patsubst %.c, %.o, $(SRC_C))
OBJ_S   = $(patsubst %.S, %.o, $(SRC_S))
OBJ     = $(OBJ_CPP) $(OBJ_C) $(OBJ_S)

# Compile rules.
.PHONY : all
all: $(PROJECT).a

$(PROJECT).a: $(OBJ)
	ld -shared $(OBJ) -o $(PROJECT).so

$(OBJ_CPP) : %.o : %.cpp
	$(CPP) $(CPP_FLAGS) -o $@ $<

$(OBJ_C) : %.o : %.c
	$(CC) $(CC_FLAGS) -o $@ $<

$(OBJ_S) : %.o : %.S
	$(AS) $(AS_FLAGS) -o $@ $<



# Clean rules
.PHONY : clean
clean:
	rm -f $(PROJECT).a $(PROJECT).so $(OBJ)
