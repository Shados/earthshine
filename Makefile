MOONC?=moonc
BUSTED?=busted
LUAROCKS?=luarocks
ESCALATE?=sudo
MOON_DIR=moon
LUA_OUT_DIR=lua
TEST_DIR=test
MOON_FILES=$(wildcard $(MOON_DIR)/**.moon)
LUA_FILES=$(patsubst moon/%,lua/%,$(patsubst %.moon,%.lua,$(MOON_FILES)))

PREFIX?=/usr/local
LUA_LIBDIR?=$(PREFIX)/lua/5.1

.PHONY: all install clean test watch

all: build

local: build
	$(LUAROCKS) make --force --local earthshine-scm-1.rockspec

global: build
	$(ESCALATE) $(LUAROCKS) make earthshine-scm-1.rockspec

watch: build
	moonc -w $(MOON_DIR)/ -t $(LUA_OUT_DIR)

build: $(LUA_FILES)

# $(@D) == lua/sub/directories
lua/%.lua: moon/%.moon
	@test -d $(@D) || mkdir -pm 755 $(@D)
	$(MOONC) $< -o $@

install: build
	@test -d $(LUA_LIBDIR) || mkdir -pm 755 $(LUA_LIBDIR)
	cp -rf $(LUA_OUT_DIR)/* $(LUA_LIBDIR)/

test:
	$(BUSTED) --pattern=_spec $(TEST_DIR)

clean:
	rm -f $(LUA_FILES)
