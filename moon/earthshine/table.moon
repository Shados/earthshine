import insert, sort from table
local *

Module = with {}
  .sorted_pairs = (tbl) ->
    -- Iterator for tables that sorts keys, storing the sorted key table within
    -- the scope of the closure
    sorted_keys = .sorted_key_list tbl
    return sorted_iterator tbl, sorted_keys

  .sorted_iterator = (tbl, sorted_keys) ->
    -- errors = {}
    -- if (type tbl) != "table"
    --   errors[#errors + 1] = "Table argument has type #{type tbl}"
    -- if (type sorted_keys) != "table"
    --   errors[#errors + 1] = "Sorted key list argument has type #{type sorted_keys}"
    -- if #errors > 0
    --   error errors

    i = 1
    return () ->
      if i <= #sorted_keys
        key = sorted_keys[i]
        val = tbl[key]
        i += 1
        return key, val
      else
        return nil

  .sorted_key_list = (tbl) ->
    list = [key for key, val in pairs tbl]
    sort list
    return list

  .clone = (tbl) ->
    return {key, val for key, val in pairs tbl}

  .keys = (tbl) ->
    i = 0
    key_list = {}
    for key, _val in pairs tbl
      i += 1
      key_list[i] = key
    return key_list

  .size = (tbl) ->
    i = 0
    for _index, _val in pairs tbl
      i += 1
    return i


return Module
