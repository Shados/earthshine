require("earthshine.string")
local Path
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Path"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.parse_parent = function(self, path)
    local len = #path
    if len == 0 then
      return "."
    end
    local last_slash
    for i = len, 1, -1 do
      local char = path:at(i)
      if char == "/" then
        last_slash = i
        break
      end
    end
    if not (last_slash) then
      return "."
    end
    if last_slash ~= 1 then
      last_slash = last_slash - 1
    else
      local _ = 1
    end
    local str = path:sub(1, last_slash)
    if (path:at(1)) == "/" then
      return str
    elseif (path:sub(1, 2)) == "./" then
      return str
    else
      return "./" .. str
    end
  end
  self.parse_name = function(self, path)
    local parsed = path:match("^.-([^/]*)$")
    if parsed ~= "." then
      return parsed
    else
      return ""
    end
  end
  self.is_absolute = function(self, path)
    return (path:at(1)) == "/"
  end
  self.iterate = function(self, path)
    return path:gmatch("([^/]+)")
  end
  Path = _class_0
end
return Path
