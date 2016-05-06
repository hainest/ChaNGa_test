CXX		 = g++
CXXSTD   = -std=c++14
CXXFLAGS = -Wall -Wextra -Wnarrowing -Wsign-conversion
OPT      = -O3 -m64 -march=bdver2 -mavx2 -mfpmath=sse -ffast-math

.PHONY: debug all clean

SRCS = processAccFiles.cpp
OBJS = $(patsubst %.cpp, %.o, $(SRCS))
EXEC = processAccFiles

all : Makefile $(EXEC)

%.o : %.cpp
	@ echo Compiling $<
	@ $(CXX) $(CXXSTD) $(CXXFLAGS) $(OPT) -c $< -o $@

$(EXEC) : $(OBJS)
	@ echo Building $<
	@ $(CXX) -o $(EXEC) $^

clean:
	@ rm -f $(EXEC) $(OBJS)
