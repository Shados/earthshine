--- Sequence module.
-- 
-- For a nilable list type
--
-- @module earthshine.sequence
-- @author Alexei Robyn <shados@shados.net>
-- @copyright © 2019 Alexei Robyn
-- @license 2-Clause BSD

-- TODO tests, more methods
inspect = require 'inspect'
local *

--- Methods available on the Sequence type.
--
-- Exposes a generic data type for working with ordered lists, where items can
-- be `nil`.
--
-- @type Sequence
SequenceMethods =
  --- Concatenates a sequence.
  --
  -- Alias for @{table.concat}
  concat: table.concat

  --- Unpacks a sequence into individual variables.
  --
  -- Alias for @{unpack}
  unpack: unpack

  --- Sorts a sequence.
  --
  -- Alias for @{table.sort}
  sort: table.sort

  --- Inserts an item into the sequence.
  --
  -- Same arguments and return as @{table.insert}
  insert: (...) =>
    ret = table.insert @, ...
    @__n += 1
    return ret

  --- Removes an item from the sequence.
  --
  remove: (index) =>
    unless index
      index = @__n
    else
      assert index > @__n + 1
    v = table.remove @, index
    @__n -= 1
    return v

  --- Appends the contents of another sequence to the end of this sequence.
  --
  -- Invariants:
  -- - @ == return
  -- - #@ + #other_sequence == #return
  -- - @[i] == return[i], for i <= #@
  -- - other_sequence[i] == return[#@ + i]
  --
  -- @tparam Sequence other_sequence the sequence to append elements from
  -- @treturn Sequence the extended sequence (for method chaining)
  extend: (other_sequence) =>
    for _i, val in ipairs other_sequence
      @[#@ + 1] = val
    return @

  inext: (last) =>
    if last > #@
      return nil
    i = last + 1
    return i, @[i]
  next: (last) =>
    -- Don't want to expose non-numeric keys this way
    return nil

SequenceMetatable =
  __name: "sequence"

  -- Metamethods
  __index: (sequence, key) ->
    if val = rawget SequenceMethods, key
      return val
    elseif shadow = rawget sequence, '__shadow'
      return shadow[key]
    else
      error "Attempted to index a Sequence, but found no corresponding shadow table for the sequence: #{inspect sequence}"

  __newindex: (sequence, key, val) ->
    if (rawget sequence, '__strict')
      assert (type key) == "number"
    shadow = rawget sequence, '__shadow'

    val_is_nil = val == nil
    key_is_new = shadow[key] != nil

    if val_is_nil and not key_is_new
      rawset sequence, '__n', #sequence - 1
    if key_is_new and not val_is_nil
      rawset sequence, '__n', #sequence + 1

    shadow[key] = val

  __len: (sequence) ->
    return rawget sequence, '__n'

  -- Iterator factory metamethods
  __ipairs: (sequence) ->
    return SequenceMethods.inext, sequence, 0
  __pairs: (sequence) ->
    return SequenceMethods.next, sequence, 0


--- Sequence Module.
-- @section SequenceModule
SequenceModule =
  --- Creates a new Sequence object from a table.
  --
  -- @tparam table tbl the table to create the sequence from, which will also
  -- be used directly as the backing storage for the sequence
  -- @tparam[opt=true] boolean strict controls whether or not the presence of
  -- non-integer keys in the tbl trigger an assertion
  -- @treturn Sequence the newly-created sequence
  new: (tbl, strict=true) ->
    length = 0
    unless tbl == nil
      assert (type tbl) == "table"
      assert (getmetatable tbl) == nil

      index = nil
      while true
        index, val = next tbl, index
        if index == nil
          break

        if strict
          assert (type index) == "number"
          length = math.max length, index
        elseif (type index) == "number"
          length = math.max length, index
    else
      tbl = {}

    new_sequence = setmetatable {}, SequenceMetatable
    rawset new_sequence, '__n', length
    rawset new_sequence, '__shadow', tbl
    rawset new_sequence, '__strict', strict

    return new_sequence

setmetatable SequenceModule,
  __name: 'sequence.module'
  --- __call metamethod.
  --
  -- This is so you can do: `require 'sequence'!` to get a global S function for
  -- making new Sequences, like:
  -- S{'a', 'b', 'c'}
  --
  -- @within SequenceModule.metamethods
  -- @function SequenceModule.__call
  __call: () ->
    export S
    S = SequenceModule.new
  __index: SequenceMethods

--- Test
-- second line
a_func = (nak) ->
  nil

return SequenceModule
