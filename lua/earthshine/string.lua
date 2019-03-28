local Module
do
  local _with_0 = string
  _with_0.at = function(self, index)
    return self:sub(index, index)
  end
  _with_0.chars = function(self)
    return self:gmatch(".")
  end
  _with_0.lcp = function(str_list)
    local shortest, prefix = math.huge, ""
    if not (str_list[1]) then
      return prefix
    end
    for _, str in pairs(str_list) do
      if str:len() < shortest then
        shortest = str:len()
      end
    end
    local first
    for str_pos = 1, shortest do
      first = str_list[1]:sub(str_pos, str_pos)
      for list_pos = 2, #str_list do
        if str_list[list_pos]:sub(str_pos, str_pos) ~= first then
          return prefix
        end
      end
      prefix = prefix .. first
    end
    return prefix
  end
  _with_0.lcs = function(str_list)
    local shortest, suffix = math.huge, ""
    if not (str_list[1]) then
      return suffix
    end
    for _, str in pairs(str_list) do
      if str:len() < shortest then
        shortest = str:len()
      end
    end
    local first
    for str_pos = shortest, 1, -1 do
      first = str_list[1]:sub(str_pos, str_pos)
      for list_pos = 2, #str_list do
        if str_list[list_pos]:sub(str_pos, str_pos) ~= first then
          return suffix
        end
      end
      suffix = first .. suffix
    end
    return suffix
  end
  _with_0.split = function(str, delimiter)
    local collected = { }
    local previous_index = 0
    for current_index = 0, #str do
      local current_char = str:sub(current_index, current_index)
      local is_delimiter = current_char == delimiter
      if is_delimiter then
        table.insert(collected, str:sub(previous_index, current_index - 1))
        previous_index = current_index + 1
      end
      if current_index == #str then
        if is_delimiter then
          table.insert(collected, "")
        else
          table.insert(collected, str:sub(previous_index, current_index))
        end
        return collected
      end
    end
  end
  _with_0.join = function(delimiter, tbl)
    local collected = ""
    local index = nil
    local i = 0
    while true do
      local val
      index, val = next(tbl, index)
      if not (index) then
        return collected
      end
      if not (i == 0) then
        collected = collected .. delimiter
      end
      collected = collected .. val
      i = i + 1
    end
    return collected
  end
  _with_0.join_list = function(delimiter, list)
    local collected = ""
    for index = 1, #list do
      if not (index == 0) then
        collected = collected .. delimiter
      end
      collected = collected .. val
    end
    return collected
  end
  Module = _with_0
end
return Module
