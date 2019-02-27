MOONC?=moonc
BUSTED?=busted
LUAROCKS?=luarocks
ESCALATE?=sudo
MOON_DIR=moon
LUA_DIR=lua
MOON_FILES=$(wildcard $(MOON_DIR)/**.moon)
LUA_FILES=$(patsubst moon/%,lua/%,$(patsubst %.moon,%.lua,$(MOON_FILES)))

.PHONY: all clean test watch

local: build
	$(LUAROCKS) make --force --local earthshine-scm-1.rockspec

global: build
	$(ESCALATE) $(LUAROCKS) make earthshine-scm-1.rockspec

watch: build
	moonc -w $(MOON_DIR)/ -t $(LUA_DIR)

build: $(LUA_FILES)

lua/%.lua: moon/%.moon
# $(@D) == lua/sub/directories
	@test -d $(@D) || mkdir -pm 755 $(@D)
	$(MOONC) $< -o $@

test:
	$(BUSTED) --pattern=_spec test/

clean:
	rm -f $(LUA_FILES)
