require('earthshine.string')
local earthshine_table = require('earthshine.table')
local sorted_iterator, sorted_key_list
sorted_iterator, sorted_key_list = earthshine_table.sorted_iterator, earthshine_table.sorted_key_list
local clone_table = earthshine_table.clone
local MADFA
do
  local _class_0
  local _base_0 = {
    add_words = function(self, words)
      for _index_0 = 1, #words do
        local word = words[_index_0]
        self:add_word(word)
      end
    end,
    add_word = function(self, w)
      local l, r, q = "", w, self.initial_state
      while r ~= "" do
        local head = r:at(1)
        local tail = r:sub(2, #r)
        do
          local p = self:_step_transition(q, head)
          if p then
            if p.incoming > 1 then
              break
            end
            l, r, q = l .. head, tail, p
          else
            break
          end
        end
      end
      while r ~= "" do
        local head = r:at(1)
        local tail = r:sub(2, #r)
        do
          local p = self:_step_transition(q, head)
          if p then
            p = self:_clone_state(p)
            self:_replace_transition(q, head, p)
            q = p
            l, r = l .. head, tail
          else
            break
          end
        end
      end
      while r ~= "" do
        local head = r:at(1)
        local tail = r:sub(2, #r)
        local p = self:_new_state()
        local was_registered = self:_unregister_state(q)
        self:_add_transition(q, head, p)
        if was_registered then
          self:_register_state(q)
        end
        q = p
        l, r = l .. head, tail
      end
      self:_set_final(q)
      return self:_visit_min(self.initial_state, "", w)
    end,
    is_equivalent_to = function(self, other_madfa)
      return self:_is_equiv_state(self.initial_state, other_madfa.initial_state)
    end,
    subset = function(self, prefix)
      if prefix == nil then
        prefix = ""
      end
      local set = { }
      local start_state = self:_step_multiple(self.initial_state, prefix)
      if not (start_state) then
        return set
      end
      self:_state_subset(start_state, prefix, set)
      return set
    end,
    _step_transition = function(self, state, label)
      return state.transitions[label]
    end,
    _step_multiple = function(self, state, label_path)
      local current_state = state
      for label in label_path:chars() do
        current_state = self:_step_transition(current_state, label)
        if not current_state then
          return nil
        end
      end
      return current_state
    end,
    _is_confluence_free = function(self, state, word)
      if state.incoming > 1 then
        return false
      elseif #state.sorted_keys == 0 or #word == 0 then
        return true
      else
        local head, tail = (word:at(1)), (word:sub(2, #word))
        do
          local child = self:_step_transition(state, head)
          if child then
            return self:_is_confluence_free(child, tail)
          else
            return true
          end
        end
      end
    end,
    _clone_state = function(self, state)
      local new
      do
        local _with_0 = { }
        _with_0.transitions = clone_table(state.transitions)
        _with_0.sorted_keys = clone_table(state.sorted_keys)
        _with_0.incoming = 0
        _with_0.final = state.final
        new = _with_0
      end
      for _label, transition_state in pairs(new.transitions) do
        transition_state.incoming = transition_state.incoming + 1
      end
      return new
    end,
    _new_state = function(self)
      local new = {
        transitions = { },
        sorted_keys = { },
        incoming = 0,
        final = false
      }
      return new
    end,
    _add_transition = function(self, state, label, transition_state)
      transition_state.incoming = transition_state.incoming + 1
      do
        state.transitions[label] = transition_state
        state.sorted_keys = sorted_key_list(state.transitions)
        return state
      end
    end,
    _set_final = function(self, state)
      local was_registered = self:_unregister_state(state)
      state.final = true
      if was_registered then
        return self:_register_state(state)
      end
    end,
    _visit_min = function(self, p, l, r)
      if r ~= "" then
        local head = r:at(1)
        local tail = r:sub(2, #r)
        local next_p = self:_step_transition(p, head)
        self:_visit_min(next_p, l .. head, tail)
      end
      do
        local q = self:_find_equivalent_state(p)
        if q then
          local parent = self:_step_multiple(self.initial_state, (l:sub(1, #l - 1)))
          local label = l:at(#l)
          self:_unregister_state(parent)
          self:_replace_transition(parent, label, q)
          self:_register_state(parent)
          self:_unregister_state(p)
          return self:_delete_state(p)
        else
          return self:_register_state(p)
        end
      end
    end,
    _find_equivalent_state = function(self, state)
      do
        local index_set = self:_retrieve_index_set(state, false)
        if index_set then
          for other_state, _ in pairs(index_set) do
            local _continue_0 = false
            repeat
              if state == other_state then
                _continue_0 = true
                break
              end
              local ok = true
              local _list_0 = state.sorted_keys
              for _index_0 = 1, #_list_0 do
                local label = _list_0[_index_0]
                local child_a, child_b = state.transitions[label], other_state.transitions[label]
                if not (child_a == child_b) then
                  ok = false
                  break
                end
              end
              if ok then
                return other_state
              end
              _continue_0 = true
            until true
            if not _continue_0 then
              break
            end
          end
        end
      end
      return nil
    end,
    _compare_state_labels = function(self, state_a, state_b)
      for index, label in pairs(state_a.sorted_keys) do
        if state_b.sorted_keys[index] ~= label then
          return false
        end
      end
      return true
    end,
    _replace_transition = function(self, state, label, transition_state)
      state.transitions[label] = nil
      transition_state.incoming = transition_state.incoming + 1
      do
        state.transitions[label] = transition_state
        return state
      end
    end,
    _unregister_state = function(self, state)
      do
        local index_set = self:_retrieve_index_set(state, false)
        if index_set then
          if index_set[state] then
            index_set[state] = nil
            return true
          end
        end
      end
      return false
    end,
    _register_state = function(self, state)
      local index_set = self:_retrieve_index_set(state, true)
      index_set[state] = true
    end,
    _retrieve_index_set = function(self, state, create_new)
      local index_by_transition_count = self.register[state.final]
      local index_by_labels
      do
        local _ = index_by_transition_count[#state.sorted_keys]
        if _ then
          index_by_labels = _
        elseif create_new then
          _ = { }
          index_by_transition_count[#state.sorted_keys] = _
          index_by_labels = _
        else
          return false
        end
      end
      local labels = (""):join(state.sorted_keys)
      do
        local set = index_by_labels[labels]
        if set then
          return set
        elseif create_new then
          set = { }
          index_by_labels[labels] = set
          return set
        else
          return false
        end
      end
    end,
    _delete_state = function(self, state)
      for _label, child in self:_iterate_transitions(state) do
        child.incoming = child.incoming - 1
      end
      local index = nil
      while true do
        local val
        index, val = next(state, index)
        if not (index) then
          return 
        end
        state[index] = nil
      end
    end,
    _iterate_transitions = function(self, state)
      return sorted_iterator(state.transitions, state.sorted_keys)
    end,
    _state_subset = function(self, state, prefix, accumulator)
      if prefix == nil then
        prefix = ""
      end
      if state.final then
        accumulator[#accumulator + 1] = prefix
      end
      for label, transition_state in self:_iterate_transitions(state) do
        self:_state_subset(transition_state, prefix .. label, accumulator)
      end
    end,
    _is_equiv_state = function(self, state_a, state_b)
      if state_a.final ~= state_b.final then
        return false
      end
      if #state_a.sorted_keys ~= #state_b.sorted_keys then
        return false
      end
      if not (self:_compare_state_labels(state_a, state_b)) then
        return false
      end
      local _list_0 = state_a.sorted_keys
      for _index_0 = 1, #_list_0 do
        local label = _list_0[_index_0]
        local child_a, child_b = state_a.transitions[label], state_b.transitions[label]
        if not (self:_is_equiv_state(child_a, child_b)) then
          return false
        end
      end
      return true
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self.register = {
        [true] = { },
        [false] = { }
      }
      self.initial_state = self:_new_state()
    end,
    __base = _base_0,
    __name = "MADFA"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  MADFA = _class_0
end
return MADFA
