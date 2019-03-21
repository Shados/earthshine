Module = with string
  .at = (index) =>
    return @sub index, index

  .chars = () =>
    return @gmatch "."

  -- Longest common prefix of list of strings
  .lcp = (str_list) ->
    shortest, prefix = math.huge, ""
    unless str_list[1]
      return prefix

    for _, str in pairs str_list
      if str\len! < shortest then shortest = str\len!

    local first
    for str_pos = 1, shortest
      first = str_list[1]\sub str_pos, str_pos

      for list_pos = 2, #str_list
        if str_list[list_pos]\sub(str_pos, str_pos)~= first
          return prefix

      prefix ..= first

    return prefix

  -- Longest common suffix of list of strings
  .lcs = (str_list) ->
    shortest, suffix = math.huge, ""
    unless str_list[1]
      return suffix

    for _, str in pairs str_list
      if str\len! < shortest then shortest = str\len!

    local first
    for str_pos = shortest, 1, -1
      first = str_list[1]\sub str_pos, str_pos

      for list_pos = 2, #str_list
        if str_list[list_pos]\sub(str_pos, str_pos)~= first
          return suffix

      suffix = first .. suffix

    return suffix

  -- TODO UTF8, fuck me
  -- Splits strings on a given delimiter
  .split = (str, delimiter) ->
    -- Yes, we really do start the indexes at 0; this is because we're working
    -- with #str and str\sub, *not* indexing a table
    collected = {}
    previous_index = 0

    for current_index = 0, #str
      current_char = str\sub current_index, current_index
      is_delimiter = current_char == delimiter

      -- If we're at a delimiter, we need to append to the list of collected
      -- substrings
      if is_delimiter
        table.insert collected, str\sub previous_index, current_index - 1

        -- Update the previous_index value to point to just after this delimiter
        previous_index = current_index + 1

      -- We're done with the loop and need to return an actual value
      if current_index == #str
        if is_delimiter
          -- In the case of ending on a delimiter, we need a trailing empty
          -- string in order to be able to re-create the original str via a
          -- theoretical join(collected, ".") function - in order to be
          -- reversible, that is
          table.insert collected, ""
        else
          -- Otherwise, just add the current substring
          table.insert collected, str\sub previous_index, current_index
        return collected

  .join = (delimiter, tbl) ->
    collected = ""
    index = nil
    i = 0
    while true
      index, val = next tbl, index
      unless index
        return collected
      unless i == 0
        collected ..= delimiter
      collected ..= val
      i += 1

  -- TODO `strip` or `trim` function to remove leading/trailing whitespace?

return Module
