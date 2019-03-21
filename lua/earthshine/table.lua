local insert, sort
do
  local _obj_0 = table
  insert, sort = _obj_0.insert, _obj_0.sort
end
local Module
do
  local _with_0 = { }
  _with_0.sorted_pairs = function(tbl)
    local sorted_keys = _with_0.sorted_key_list(tbl)
    return sorted_iterator(tbl, sorted_keys)
  end
  _with_0.sorted_iterator = function(tbl, sorted_keys)
    local i = 1
    return function()
      if i <= #sorted_keys then
        local key = sorted_keys[i]
        local val = tbl[key]
        i = i + 1
        return key, val
      else
        return nil
      end
    end
  end
  _with_0.sorted_key_list = function(tbl)
    local list
    do
      local _accum_0 = { }
      local _len_0 = 1
      for key, val in pairs(tbl) do
        _accum_0[_len_0] = key
        _len_0 = _len_0 + 1
      end
      list = _accum_0
    end
    sort(list)
    return list
  end
  _with_0.clone = function(tbl)
    local _tbl_0 = { }
    for key, val in pairs(tbl) do
      _tbl_0[key] = val
    end
    return _tbl_0
  end
  _with_0.keys = function(tbl)
    local i = 0
    local key_list = { }
    for key, _val in pairs(tbl) do
      i = i + 1
      key_list[i] = key
    end
    return key_list
  end
  _with_0.size = function(tbl)
    local i = 0
    local index = nil
    while true do
      i = i + 1
      local val
      index, val = next(tbl, index)
      if not (index) then
        return i
      end
    end
  end
  Module = _with_0
end
return Module
