require('earthshine.string')
local Module
do
  local _with_0 = { }
  _with_0.dir_separator = package.config:at(1)
  if _with_0.dir_separator == "\\" then
    _with_0.dir_separator_chars = "\\/"
  else
    _with_0.dir_separator_chars = _with_0.dir_separator
  end
  _with_0.parse_dir = function(path)
    return (path:match("^(.-)[^" .. tostring(_with_0.dir_separator_chars) .. "]*$"))
  end
  _with_0.is_absolute = function(path)
    local first_char = path:at(1)
    if _with_0.dir_separator == "\\" then
      return first_char == "/" or first == "\\" or (path:at(2)) == ":"
    else
      return first_char == "/"
    end
  end
  _with_0.iterate = function(path)
    return path:gmatch("([^" .. tostring(_with_0.dir_separator_chars) .. "]+)")
  end
  Module = _with_0
end
return Module
