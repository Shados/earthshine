--- A class for building minimal acyclic finite-state automata.
--
--    > MADFA = require 'earthshine.madfa'
--    > madfa = MADFA.new!
--    > words = { "foo", "foobar", "foobaz", "bazbar", "barfoo" }
--    > madfa\add_words words
--    > madfa\subset "foo"
--    { "foo", "foobar", "foobaz" }
--
-- Dependencies: `earthshine.string`, `earthshine.table`
-- @module earthshine.madfa
-- @author Alexei Robyn <shados@shados.net>
-- @copyright 2019 Alexei Robyn
-- @license 2-Clause BSD

require 'earthshine.string'
earthshine_table = require 'earthshine.table'
import sorted_iterator, sorted_key_list from earthshine_table
clone_table = earthshine_table.clone

local ^

--- MADFA module/pseudo-class.
--
-- Contains the necessary data structures and algorithms required to
-- incrementally construct a minimal acyclic finite-state automaton from a
-- sorted or unsorted list of words.
--
-- @type MADFA
class MADFA
  -- Public API
  --- Creates and initializes a new, empty MADFA.
  --
  -- @treturn MADFA a new MADFA instance
  new: () =>
    -- Holds indexes grouping registered states by various properties
    -- Boolean for indexes by finality
    -- Numeric for indexes by # of outgoing transitions
    -- Strings for indexes by sorted list of transition labels
    @register =
      [true]: {}
      [false]: {}
    @initial_state = @_new_state!

  add_words: (words) =>
    -- assert @ != nil and words != nil
    for word in *words
      @add_word word

  add_word: (w) =>
    l, r, q = "", w, @initial_state
    while r != ""
      head = r\at 1
      tail = r\sub 2, #r
      if p = @_step_transition q, head
        break if p.incoming > 1
        -- Loop invariants
        -- print "`#{w}` == `#{l}` .. `#{r}` == `#{l .. r}`"
        -- assert w == l .. r
        -- assert q == @_step_multiple @initial_state, l
        -- assert q != nil
        -- assert @_is_confluence_free @initial_state, l

        l, r, q = l .. head, tail, p
      else break

    while r != ""
      head = r\at 1
      tail = r\sub 2, #r
      if p = @_step_transition q, head
        -- Loop invariants
        -- assert w == l .. r
        -- assert q == @_step_multiple @initial_state, l
        -- assert q != nil
        -- assert p.incoming > 1

        p = @_clone_state p
        @_replace_transition q, head, p
        q = p
        l, r = l .. head, tail
      else break

    -- assert @_is_confluence_free @initial_state, w
    -- assert q == @_step_multiple @initial_state, l
    -- assert q != nil
    -- assert r == "" or (@_step_transition q, r\at 1) == nil

    while r != ""
      head = r\at 1
      tail = r\sub 2, #r
      -- Loop invariants
      -- assert w == l .. r
      -- assert q == @_step_multiple @initial_state, l
      -- assert q != nil

      p = @_new_state!
      -- This is the one of only three places where we may modify a pre-existing
      -- (non-new, non-cloned) state, so we have to unregister and possibly
      -- re-register it to account for the change
      was_registered = @_unregister_state q
      @_add_transition q, head, p
      @_register_state q if was_registered
      q = p
      l, r = l .. head, tail

    -- assert q == @_step_multiple @initial_state, w
    -- assert q != nil

    @_set_final q

    @_visit_min @initial_state, "", w

  --- Checks if the MADFA is equivalent to the given MADFA.
  --
  -- Two MADFAs are equivalent all states in the same position in a tree walk
  -- are in the same equivalence class as one another.
  --
  -- @tparam madfa other_madfa the other MADFA to compare against
  -- @treturn boolean whether or not the two MADFAs are equivalent
  is_equivalent_to: (other_madfa) =>
    -- assert @ != nil and other_madfa != nil
    return @_is_equiv_state @initial_state, other_madfa.initial_state

  --- Returns the subset of words represented in the MADFA prefixed by the
  -- optional prefix.
  --
  -- @tparam[opt=''] string prefix the returned words will be limited to those
  -- that start with this
  -- @treturn {string,...} the list of words in the specified subset;
  -- incidentally this will be alphabetically sorted
  subset: (prefix = "") =>
    -- assert @ != nil
    set = {}
    start_state = @_step_multiple @initial_state, prefix
    unless start_state
      return set

    @_state_subset start_state, prefix, set
    return set


  -- Internal functions


  _step_transition: (state, label) =>
    -- assert state != nil and label != nil
    return state.transitions[label]

  _step_multiple: (state, label_path) =>
    -- assert state != nil and label_path != nil
    current_state = state
    for label in label_path\chars!
      current_state = @_step_transition current_state, label
      if not current_state
        return nil
    return current_state

  _is_confluence_free: (state, word) =>
    -- assert state != nil and word != nil
    if state.incoming > 1
      return false
    elseif #state.sorted_keys == 0 or #word == 0
      return true
    else
      head, tail = (word\at 1), (word\sub 2, #word)
      if child = @_step_transition state, head
        return @_is_confluence_free child, tail
      else
        return true

  _clone_state: (state) =>
    -- assert state != nil
    new = with {}
      .transitions = clone_table state.transitions
      .sorted_keys = clone_table state.sorted_keys
      .incoming = 0
      .final = state.final
    for _label, transition_state in pairs new.transitions
      transition_state.incoming += 1
    return new

  _new_state: () =>
    new = {
      transitions: {}
      sorted_keys: {}
      incoming: 0
      final: false
    }
    return new

  _add_transition: (state, label, transition_state) =>
    -- assert state != nil and transition_state != nil,
    --   "self and transition_state must both be valid States (were: '#{state}', '#{transition_state}' respectively)"
    -- assert state.transitions[label] == nil,
    --   "Cannot add transition with label #{label} to state #{state} because it already has a transition with that label"
    transition_state.incoming += 1
    return with state
      .transitions[label] = transition_state
      .sorted_keys = sorted_key_list state.transitions

  _set_final: (state) =>
    -- This is the one of only three places where we may modify a pre-existing
    -- (non-new, non-cloned) state, so we have to unregister and possibly
    -- re-register it to account for the change
    was_registered = @_unregister_state state
    state.final = true
    @_register_state state if was_registered

  _visit_min: (p, l, r) =>
    -- Preconditions
    -- assert (@_is_confluence_free @initial_state, l .. r), "p1"
    -- assert Inequiv(Q - [states along @_step_multiple @initial-state, l..r])
    -- assert (p != nil), "p2"
    if r != ""
      head = r\at 1
      tail = r\sub 2, #r

      next_p = @_step_transition p, head
      @_visit_min next_p, l .. head, tail

    -- assert (@_is_confluence_free @initial_state, l), "i1"

    if q = @_find_equivalent_state p
      -- Replace with existing and delete
      -- assert q != p
      parent = @_step_multiple @initial_state, (l\sub 1, #l - 1)
      label = l\at #l
      -- This is the one of only three places where we modify a pre-existing
      -- (non-new, non-cloned) state, so we have to unregister and re-register
      -- it to account for the change
      @_unregister_state parent
      @_replace_transition parent, label, q
      @_register_state parent

      @_unregister_state p
      @_delete_state p
    else
      -- Register
      @_register_state p

    -- assert (@_is_confluence_free @initial_state, l\sub 1, #l - 1), "Postcondition failure"

  _find_equivalent_state: (state) =>
    -- assert state != nil
    if index_set = @_retrieve_index_set state, false
      for other_state, _ in pairs index_set
        -- Yes, really. Equivalence, not identity, because at this level we
        -- intend to merge.
        continue if state == other_state
        ok = true
        -- The two states are in the same classes, so we just need to check
        -- their children for equivalence recursively
        for label in *state.sorted_keys
          child_a, child_b = state.transitions[label], other_state.transitions[label]
          -- We can compare children for simple equality because we know that
          -- all child states have already been minimized; ergo all equivalent
          -- child states are also equal ones
          unless child_a == child_b
            ok = false
            break
        return other_state if ok

    return nil

  _compare_state_labels: (state_a, state_b) =>
    for index, label in pairs state_a.sorted_keys
      if state_b.sorted_keys[index] != label
        return false
    return true

  _replace_transition: (state, label, transition_state) =>
    -- assert state != nil and transition_state != nil,
    --   "self and transition_state must both be valid States (were: '#{state}', '#{transition_state}' respectively)"
    -- assert state.transitions[label] != nil,
    --   "Cannot replace transition with label #{label} to go to state #{transition_state} because it does not already have a transition with that label"
    state.transitions[label] = nil
    transition_state.incoming += 1
    return with state
      .transitions[label] = transition_state

  _unregister_state: (state) =>
    -- assert state != nil
    if index_set = @_retrieve_index_set state, false
      if index_set[state]
        index_set[state] = nil
        return true
    return false

  _register_state: (state) =>
    -- assert state != nil
    index_set = @_retrieve_index_set state, true
    index_set[state] = true

  _retrieve_index_set: (state, create_new) =>
    -- assert state != nil
    index_by_transition_count = @register[state.final]

    -- Retrieve or create an index level
    index_by_labels = if _ = index_by_transition_count[#state.sorted_keys]
      _
    elseif create_new
      _ = {}
      index_by_transition_count[#state.sorted_keys] = _
      _
    else return false

    -- Retrieve or create an index level
    labels = ""\join state.sorted_keys
    if set = index_by_labels[labels]
      return set
    elseif create_new
      set = {}
      index_by_labels[labels] = set
      return set
    else return false

  _delete_state: (state) =>
    -- assert state != nil
    for _label, child in @_iterate_transitions state
      child.incoming -= 1

    index = nil
    while true
      index, val = next state, index
      unless index
        return
      state[index] = nil

  --- An iterator factory to perform sorted iteration of state transitions.
  --
  -- Invariants:
  -- 1. Each subsequent key should be lexicographically greater than the
  --    previous
  -- 2. Each iteration should produce a (key, value) pair that exists in the
  --    transition table of the State
  -- 3. The set of (key, value) pairs iterated over should match the set of
  --    trasitions that exists in the State
  --     - A State with no children should iterate no times
  --
  -- @treturn function an iterator function
  _iterate_transitions: (state) =>
    -- assert state != nil
    return sorted_iterator state.transitions, state.sorted_keys

  --- Adds to the accumulator the subset of strings reachable from the given
  -- state, optionally prefixed by the given prefix.
  --
  -- @tparam[opt=''] string prefix prepends this to each string in the subset
  -- @tparam {string,...} accumulator the array to append new strings to
  _state_subset: (state, prefix = "", accumulator) =>
    -- assert state != nil and accumulator != nil
    if state.final
      accumulator[#accumulator + 1] = prefix

    for label, transition_state in @_iterate_transitions state
      @_state_subset transition_state, prefix .. label, accumulator

  _is_equiv_state: (state_a, state_b) =>
    return false if state_a.final != state_b.final
    return false if #state_a.sorted_keys != #state_b.sorted_keys
    return false unless @_compare_state_labels state_a, state_b
    for label in *state_a.sorted_keys
      child_a, child_b = state_a.transitions[label], state_b.transitions[label]
      return false unless @_is_equiv_state child_a, child_b
    return true

return MADFA
