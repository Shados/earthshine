require 'earthshine.string'

Module = with {}
  .dir_separator = package.config\at 1
  .dir_separator_chars = if .dir_separator == "\\"
    "\\/"
  else
    .dir_separator

  .parse_dir = (path) ->
    (path\match "^(.-)[^#{.dir_separator_chars}]*$")

  .is_absolute = (path) ->
    first_char = path\at 1
    if .dir_separator == "\\"
      -- Windows
      return first_char == "/" or first == "\\" or (path\at 2) == ":"
    else
      -- POSIX
      return first_char == "/"

  .iterate = (path) ->
    path\gmatch "([^#{.dir_separator_chars}]+)"

return Module
