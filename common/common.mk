# Using ?= makes these variables overridable
# Simply define them before including common.mk
CXX ?= clang++
STDCXX ?= c++17
DBG_FLAGS ?= -Og -g -Wall -Wextra
OPT_FLAGS ?= -O3 -DNDEBUG -Wall -Wextra
CPP_FILES ?= $(shell find . -name '*.cpp' -not -name 'plugin.cpp' -not -name 'main.cpp' -not -path '*/tests/*')
CPP_TEST_FILES ?= $(shell find tests/ -name '*.cpp')
HPP_FILES ?= $(shell find -L . -name '*.hpp')
# I need -L to follow symlinks in common/
LDFLAGS := -ggdb $(LDFLAGS)

# In the future, if compilation is slow, we can enable partial compilation of object files with
#  $(OBJ_FILES:.o=.dbg.o) and  $(OBJ_FILES:.o=.opt.o)
plugin.dbg.so: plugin.cpp $(CPP_FILES) $(HPP_FILES) Makefile
	$(CXX) -ggdb -std=$(STDCXX) $(CFLAGS) $(CPPFLAGS) $(DBG_FLAGS) -shared -fpic \
	-o $@ plugin.cpp $(CPP_FILES) $(LDFLAGS)

plugin.opt.so: plugin.cpp $(CPP_FILES) $(HPP_FILES) Makefile
	$(CXX)       -std=$(STDCXX) $(CFLAGS) $(CPPFLAGS) $(OPT_FLAGS) -shared -fpic \
	-o $@ plugin.cpp $(CPP_FILES) $(LDFLAGS)

main.dbg.exe: main.cpp $(CPP_FILES) $(HPP_FILES) Makefile
	$(CXX) -ggdb -std=$(STDCXX) $(CFLAGS) $(CPPFLAGS) $(DBG_FLAGS) \
	-o $@ main.cpp $(CPP_FILES) $(LDFLAGS)

main.opt.exe: main.cpp $(CPP_FILES) $(HPP_FILES) Makefile
	$(CXX)        -std=$(STDCXX) $(CFLAGS) $(CPPFLAGS) $(OPT_FLAGS) \
	-o $@ main.cpp $(CPP_FILES) $(LDFLAGS)

%.dbg.o: %.cpp $(OTHER_DEPS) Makefile
	$(CXX) -ggdb  -std=$(STDCXX) $(CFLAGS) $(CPPFLAGS) $(DBG_FLAGS) \
	-o $@ $<

%.opt.o: %.cpp $(OTHER_DEPS) Makefile
	$(CXX)        -std=$(STDCXX) $(CFLAGS) $(CPPFLAGS) $(OPT_FLAGS) \
	-o $@ $<

.PHONY: test/run test/gdb
ifeq ($(CPP_TEST_FILES),)
tests/run:
tests/gdb:
else
tests/run: tests/test.exe
	./tests/test.exe

tests/gdb: tests/test.exe
	gdb -q ./tests/test.exe -ex r

tests/test.exe: $(CPP_TEST_FILES) $(CPP_FILES) $(HPP_FILES)
	$(CXX) -ggdb -std=$(STDCXX) $(CFLAGS) $(CPPFLAGS) $(DBG_FLAGS) \
	$(shell pkg-config --libs --cflags gtest_main) -fsanitize=address,undefined -o ./tests/test.exe \
	$(CPP_TEST_FILES) $(CPP_FILES) $(LDFLAGS)
endif

.PHONY: clean
clean:
	touch _target && \
	$(RM) _target *.so *.exe *.o
# if *.so and *.o do not exist, rm will still work, because it still receives an operand (target)

.PHONY: deepclean
deepclean: clean
