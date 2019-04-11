require "earthshine.string"

local *

-- NOTE: POSIX-compatible paths, not NT or Win32
-- TODO: In addition the class functions, add methods forming a structured path
-- type
class Path
  -- These parsing functions work on strings representing paths, and return
  -- partially-normalized fragments of those strings
  @parse_parent = (path) =>
    len = #path
    return "." if len == 0

    local last_slash
    for i = len, 1, -1
      char = path\at i
      if char == "/"
        last_slash = i
        break
    -- If we haven't found a slash, it's a two-component implicitly relative
    -- path, so the parent is just "."
    return "." unless last_slash

    last_slash = last_slash - 1 if last_slash != 1 else 1
    str = path\sub 1, last_slash
    if (path\at 1) == "/"
      -- Handle absolute paths
      return str
    elseif (path\sub 1, 2) == "./"
      -- Handle explicitly relative paths
      return str
    else
      -- Handle implicitly relative paths
      return "./" .. str

  @parse_name = (path) =>
    parsed = path\match "^.-([^/]*)$"
    return parsed if parsed != "." else ""

  @is_absolute = (path) =>
    return (path\at 1) == "/"

  @iterate = (path) =>
    path\gmatch "([^/]+)"

return Path
