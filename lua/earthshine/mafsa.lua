local inspect = require('inspect')
require('earthshine.string')
local earthshine_table = require('earthshine.table')
local sorted_iterator, sorted_key_list
sorted_iterator, sorted_key_list = earthshine_table.sorted_iterator, earthshine_table.sorted_key_list
local clone_table = earthshine_table.clone
local Mafsa, Register, State
Mafsa = {
  __class_metatable = {
    __index = function(mafsa, key)
      do
        local mafsa_val = Mafsa[key]
        if mafsa_val then
          return mafsa_val
        else
          return rawget(mafsa, key)
        end
      end
    end
  },
  new = function()
    local mafsa
    do
      local _with_0 = setmetatable({ }, Mafsa.__class_metatable)
      _with_0.register = Register.new()
      _with_0.initial_state = State.new()
      mafsa = _with_0
    end
    return mafsa
  end,
  common_prefix = function(self, word)
    assert(self ~= nil and word ~= nil)
    local current_state = self.initial_state
    local prefix = ""
    for char in word:chars() do
      do
        local next_state = current_state:step_if_valid(char)
        if next_state then
          current_state = next_state
          prefix = prefix .. char
        else
          break
        end
      end
    end
    return prefix
  end,
  add_suffix = function(self, branch_off_state, suffix)
    assert(self ~= nil and branch_off_state ~= nil and suffix ~= nil)
    local current_state = branch_off_state
    local states = {
      branch_off_state
    }
    for char in suffix:chars() do
      local new_state = State.new()
      states[#states + 1] = new_state
      current_state:add_transition(char, new_state)
      current_state = new_state
    end
    current_state.final = true
    for i = #states - 1, 1, -1 do
      current_state = states[i]
      local child_label = suffix:sub(i, i)
      self:replace_or_register(current_state, child_label)
    end
  end,
  add_suffix_sorted = function(self, branch_off_state, suffix)
    assert(self ~= nil and branch_off_state ~= nil and suffix ~= nil)
    local current_state = branch_off_state
    for char in suffix:chars() do
      local new_state = State.new()
      current_state:add_transition(char, new_state)
      current_state = new_state
    end
    current_state.final = true
  end,
  is_equivalent_to = function(self, other_mafsa)
    assert(self ~= nil and other_mafsa ~= nil)
    return self.initial_state:is_equivalent_to(other_mafsa.initial_state)
  end,
  subset = function(self, prefix)
    if prefix == nil then
      prefix = ""
    end
    assert(self ~= nil)
    local set = { }
    local start_state = self.initial_state:step_multiple_if_valid(prefix)
    if not (start_state) then
      return set
    end
    start_state:subset(prefix, set)
    return set
  end,
  add_words = function(self, words)
    assert(self ~= nil and words ~= nil)
    self.previous_word = nil
    for _index_0 = 1, #words do
      local word = words[_index_0]
      self:add_word(word)
    end
  end,
  add_word = function(self, word)
    local common_prefix = self:common_prefix(word)
    local current_suffix = word:sub(#common_prefix + 1, #word)
    if current_suffix == "" then
      do
        local state = self.initial_state:step_multiple_if_valid(common_prefix)
        if state then
          if state.final then
            return 
          end
        end
      end
    end
    local first_confluence_state, current_index = self:find_first_confluence_state(common_prefix)
    local last_state = self.initial_state:step_multiple(common_prefix)
    if first_confluence_state ~= nil then
      last_state = last_state:clone()
    end
    self:add_suffix(last_state, current_suffix)
    if first_confluence_state ~= nil then
      for i = #common_prefix - 1, current_index, -1 do
        local sub_prefix = common_prefix:sub(1, i)
        local current_state = (self.initial_state:step_multiple(sub_prefix)):clone()
        local current_char = common_prefix:sub(i, i)
        local word_char = word:sub(i + 1, i + 1)
        current_state:add_transition(current_char, last_state)
        self:replace_or_register(current_state, (word:sub(i + 1, i + 1)))
        last_state = current_state
      end
    else
      current_index = #common_prefix
    end
    local current_state
    local changed = current_index > 0
    while changed do
      current_index = current_index - 1
      local sub_word = word:sub(1, current_index)
      current_state = self.initial_state:step_multiple(sub_word)
      local old_state = last_state
      if current_index > 0 then
        self.register[last_state] = nil
      end
      local current_char = word:sub(current_index + 1, current_index + 1)
      self:replace_or_register(current_state, current_char)
      last_state = current_state:step_transition(current_char)
      changed = old_state ~= last_state
      last_state = current_state
    end
    if current_index > 0 then
      self.register[current_state] = true
    end
  end,
  find_first_confluence_state = function(self, prefix)
    local current_state = self.initial_state
    local length = 0
    for char in prefix:chars() do
      if current_state.is_confluence then
        return current_state, length
      else
        do
          local next_state = current_state:step_if_valid(char)
          if next_state then
            current_state = next_state
            length = length + 1
          else
            return nil
          end
        end
      end
    end
  end,
  replace_or_register = function(self, state, symbol)
    local child = state:step_transition(symbol)
    do
      local equivalent_state = self.register:equivalent_state(child)
      if equivalent_state then
        state:replace_transition(symbol, equivalent_state)
        return child:delete()
      else
        self.register[child] = true
      end
    end
  end,
  sorted_replace_or_register = function(self, state)
    assert(self ~= nil and state ~= nil)
    local child = state:last_child()
    if child.has_children then
      self:sorted_replace_or_register(child)
    end
    do
      local equivalent_state = self.register:equivalent_state(child)
      if equivalent_state then
        state:replace_last_child(equivalent_state)
        return child:delete()
      else
        self.register[child] = true
      end
    end
  end,
  add_sorted_words = function(self, sorted_words)
    assert(self ~= nil and sorted_words ~= nil)
    for _index_0 = 1, #sorted_words do
      local word = sorted_words[_index_0]
      self:add_sorted_word(word)
    end
    return self:sorted_replace_or_register(self.initial_state)
  end,
  add_sorted_word = function(self, word)
    if self.previous_word then
      if self.previous_word == word then
        return 
      end
      assert(word >= self.previous_word, "add_sorted_words called on a Mafsa that has a later previous word added (word: '" .. tostring(word) .. "', previous word: '" .. tostring(self.previous_word) .. "')")
    else
      assert(#self.initial_state.sorted_keys == 0, "add_sorted_words called on a Mafsa that has been initialiazed fully, or with non-sorted words")
    end
    self.previous_word = word
    local common_prefix = self:common_prefix(word)
    local last_state = self.initial_state:step_multiple(common_prefix)
    local current_suffix = word:sub(#common_prefix + 1, #word)
    if last_state.has_children then
      self:sorted_replace_or_register(last_state)
    end
    return self:add_suffix_sorted(last_state, current_suffix)
  end
}
Register = {
  __class_metatable = {
    __index = function(tbl, key)
      assert(tbl ~= nil and key ~= nil)
      if key == "equivalent_state" then
        return Register[key]
      else
        return rawget(tbl, key)
      end
    end
  },
  new = function()
    return setmetatable({ }, Register.__class_metatable)
  end,
  equivalent_state = function(self, state)
    assert(self ~= nil and state ~= nil)
    for register_state, _val in pairs(self) do
      if state:is_equivalent_to(register_state) then
        return register_state
      end
    end
    return nil
  end
}
State = {
  __class_metatable = {
    __index = function(state, key)
      assert(state ~= nil and key ~= nil)
      local _exp_0 = key
      if "transitions" == _exp_0 or "final" == _exp_0 or "sorted_keys" == _exp_0 then
        return rawget(state, key)
      elseif "is_confluence" == _exp_0 then
        return state.incoming > 1
      elseif "has_children" == _exp_0 then
        return #state.sorted_keys > 0
      else
        return State[key]
      end
    end
  },
  new = function()
    local new_state = {
      transitions = { },
      sorted_keys = { },
      final = false,
      incoming = 0
    }
    setmetatable(new_state, State.__class_metatable)
    return new_state:__update_state_hash()
  end,
  clone = function(self)
    assert(self ~= nil)
    local new_state
    do
      local _with_0 = { }
      _with_0.transitions = clone_table(self.transitions)
      _with_0.sorted_keys = clone_table(self.sorted_keys)
      _with_0.final = self.final
      _with_0.incoming = 0
      _with_0.hash = self.hash
      new_state = _with_0
    end
    setmetatable(new_state, State.__class_metatable)
    for _label, transition_state in pairs(new_state.transitions) do
      transition_state.incoming = transition_state.incoming + 1
    end
    return new_state
  end,
  iterate_transitions = function(self)
    assert(self ~= nil)
    return sorted_iterator(self.transitions, self.sorted_keys)
  end,
  add_transition = function(self, label, transition_state)
    assert(self ~= nil and transition_state ~= nil, "self and transition_state must both be valid States (were: '" .. tostring(self) .. "', '" .. tostring(transition_state) .. "' respectively)")
    assert(self.transitions[label] == nil, "Cannot add transition with label " .. tostring(label) .. " to state " .. tostring(self) .. " because it already has a transition with that label")
    do
      self.transitions[label] = transition_state
      self.sorted_keys = sorted_key_list(self.transitions)
      self:__update_state_hash()
    end
    transition_state.incoming = transition_state.incoming + 1
    return self
  end,
  replace_transition = function(self, label, transition_state)
    assert(self ~= nil and transition_state ~= nil, "self and transition_state must both be valid States (were: '" .. tostring(self) .. "', '" .. tostring(transition_state) .. "' respectively)")
    assert(self.transitions[label] ~= nil, "Cannot replace transition with label " .. tostring(label) .. " to go to state " .. tostring(self) .. " because it does not already have a transition with that label")
    self.transitions[label] = nil
    return self:add_transition(label, transition_state)
  end,
  set_final = function(self, val)
    assert(self ~= nil)
    assert(val ~= nil and assert(type(val) == "boolean", "val must be a boolean value (given '" .. tostring(val) .. "')"))
    do
      self.final = val
      self:__update_state_hash()
      return self
    end
  end,
  __update_state_hash = function(self)
    assert(self ~= nil)
    self.hash = "f:" .. tostring(self.final) .. ".n:" .. tostring(#self.sorted_keys) .. ".l:" .. tostring(self:__get_labels())
    return self
  end,
  __get_labels = function(self)
    assert(self ~= nil)
    local ret = ""
    for label, _transition in self:iterate_transitions() do
      ret = ret .. label
    end
    return ret
  end,
  __get_right_language = function(self)
    assert(self ~= nil)
    local ret = ""
    if #self.sorted_keys > 0 then
      for label, transition in self:iterate_transitions() do
        ret = ret .. tostring(label) .. tostring(transition:__get_right_language())
      end
    else
      local _ = nil
    end
    return ret
  end,
  step_transition = function(self, label)
    assert(self ~= nil and label ~= nil)
    if label == "" then
      return self
    else
      do
        local next_state = self.transitions[label]
        if next_state then
          return next_state
        else
          return error("Undefined next_state for transition with label " .. tostring(label) .. " on state " .. tostring(self) .. ":" .. tostring(inspect(self)))
        end
      end
    end
  end,
  step_if_valid = function(self, label)
    assert(self ~= nil and label ~= nil)
    return self.transitions[label]
  end,
  step_multiple = function(self, word)
    assert(self ~= nil and word ~= nil)
    local current_state = self
    for char in word:chars() do
      current_state = current_state:step_transition(char)
    end
    return current_state
  end,
  step_multiple_if_valid = function(self, word)
    assert(self ~= nil and word ~= nil)
    local current_state = self
    for char in word:chars() do
      current_state = current_state:step_if_valid(char)
      if not current_state then
        return nil
      end
    end
    return current_state
  end,
  replace_last_child = function(self, new_child)
    assert(self ~= nil and new_child ~= nil)
    self.transitions[self:last_child_label()] = new_child
    new_child.incoming = new_child.incoming + 1
    return self
  end,
  last_child = function(self)
    assert(self ~= nil)
    if self.has_children then
      return self.transitions[self:last_child_label()]
    else
      return error("last_child called on a state with no children, state " .. tostring(self) .. ":" .. tostring(inspect(self)))
    end
  end,
  last_child_label = function(self)
    assert(self ~= nil)
    return self.sorted_keys[#self.sorted_keys]
  end,
  delete = function(self)
    assert(self ~= nil)
    for _label, transition_state in pairs(self.transitions) do
      transition_state.incoming = transition_state.incoming - 1
    end
    return nil
  end,
  is_equivalent_to = function(self, other_state)
    assert(self ~= nil and other_state ~= nil)
    if self.hash == other_state.hash then
      if self:__get_right_language() == other_state:__get_right_language() then
        return true
      else
        return false
      end
    end
  end,
  subset = function(self, prefix, accumulator)
    if prefix == nil then
      prefix = ""
    end
    assert(self ~= nil and accumulator ~= nil)
    if self.final then
      accumulator[#accumulator + 1] = prefix
    end
    for label, transition in self:iterate_transitions() do
      transition:subset(prefix .. label, accumulator)
    end
  end
}
do
  local _with_0 = Mafsa
  _with_0.Register = Register
  _with_0.State = State
  return _with_0
end
