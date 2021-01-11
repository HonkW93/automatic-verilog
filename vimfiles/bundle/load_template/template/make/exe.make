CXX = g++

TARGET =  REPLACE

C_FLAGS += -g -Wall 

LIB_FLAGS = -pthread 

all: $(TARGET)

REPLACE:  REPLACE.o
	$(CXX) -o $@ $^  $(LIB_FLAGS) $(LIB) $(C_FLAGS)

.cpp.o:
	$(CXX) -c -o $*.o $(INC) $(C_FLAGS) $*.cpp
.cc.o:
	$(CXX) -c -o $*.o $(INC) $(C_FLAGS) $*.cc


clean:
	-rm -f *.o $(TARGET) 
