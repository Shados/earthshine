--- A class for building minimal acyclic finite-state automata.
--
--    > Mafsa = require 'mafsa.sorted'
--    > mafsa = Mafsa.new!
--    > sorted_words = { "foo", "foobar", "foobaz", "bazbar", "barfoo" }
--    > table.sort sorted_words
--    > mafsa\add_sorted_words sorted_words
--    > mafsa\subset "foo"
--    { "foo", "foobar", "foobaz" }
--
-- Dependencies: `earthshine.string`, `earthshine.table`, `inspect`
-- @module earthshine.mafsa
-- @author Alexei Robyn <shados@shados.net>
-- @copyright 2019 Alexei Robyn
-- @license 2-Clause BSD

inspect = require 'inspect'
require 'earthshine.string'
earthshine_table = require 'earthshine.table'
import sorted_iterator, sorted_key_list from earthshine_table
clone_table = earthshine_table.clone

local ^

--- MAFSA module/pseudo-class.
--
-- Contains the necessary data structures and algorithms required to
-- incrementally construct a minimal acyclic finite-state automaton from a
-- sorted or unsorted list of words.
--
-- @type Mafsa
Mafsa =
  __class_metatable:
    __index: (mafsa, key) ->
      if mafsa_val = Mafsa[key]
        return mafsa_val
      else
        return rawget mafsa, key

  --- Creates a new Mafsa.
  --
  -- @treturn Mafsa a new Mafsa instance
  new: () ->
    mafsa = with setmetatable {}, Mafsa.__class_metatable
      .register = Register.new!
      .initial_state = State.new!
    return mafsa

  --- Finds the longest prefix of the given word that forms a valid series of
  -- state transitions in the MAFSA.
  --
  -- @tparam string word the word to determine a prefix from
  -- @treturn string the longest common prefix between the given word and the MAFSA
  common_prefix: (word) =>
    assert @ != nil and word != nil
    current_state = @initial_state
    prefix = ""
    for char in word\chars!
      if next_state = current_state\step_if_valid char
        current_state = next_state
        prefix ..= char
      else
        break
    return prefix

  --- Adds a chain of new states off of the given state, with labels taken
  -- sequentially from the given suffix.
  --
  -- @tparam State branch_off_state the state in the MAFSA to branch off of
  -- @tparam string suffix the suffix to append
  add_suffix: (branch_off_state, suffix) =>
    assert @ != nil and branch_off_state != nil and suffix != nil

    current_state = branch_off_state
    states = {branch_off_state}
    -- Add new states
    for char in suffix\chars!
      new_state = State.new!
      states[#states + 1] = new_state
      current_state\add_transition char, new_state
      current_state = new_state
    current_state.final = true

    -- Replace or register new states, from 'furthest' to 'nearest' the
    -- branch-off state. Won't run if the suffix is "", which is the correct
    -- behaviour.
    -- Note that this loop begins with the *penultimate* state in the suffix,
    -- because the function @replace_or_register acts on a child of its
    -- argument state
    for i = #states - 1, 1, -1
      current_state = states[i]
      child_label = suffix\sub i, i
      @replace_or_register current_state, child_label

  -- The sorted-only version exists because in the sorted algorithm state
  -- registration/replacement is handled differently
  add_suffix_sorted: (branch_off_state, suffix) =>
    assert @ != nil and branch_off_state != nil and suffix != nil
    current_state = branch_off_state
    for char in suffix\chars!
      new_state = State.new!
      current_state\add_transition char, new_state
      current_state = new_state
    current_state.final = true

  --- Checks if the MAFSA is equivalent to the given MAFSA.
  --
  -- Two MAFSAs are equivalent all states in the same position in a tree walk
  -- are in the same equivalence class as one another.
  --
  -- @tparam Mafsa other_mafsa the other MAFSA to compare against
  -- @treturn boolean whether or not the two MAFSAs are equivalent
  is_equivalent_to: (other_mafsa) =>
    assert @ != nil and other_mafsa != nil
    return @compare_state_trees @initial_state, other_mafsa.initial_state
    -- return @initial_state\is_equivalent_to other_mafsa.initial_state

  compare_state_trees: (state_a, state_b) =>
    if state_a\is_equivalent_to state_b
      for label in state_a\iterate_transitions!
        if child_b = state_b\step_if_valid label
          child_a = state_a\step_if_valid label
          if compare_state_trees state_a, state_b
            continue
          else
            return false
        else
          return false
      return true
    else
      return false

  --- Returns the subset of words represented in the MAFSA prefixed by the
  -- optional prefix.
  --
  -- @tparam[opt=''] string prefix the returned words will be limited to those
  -- that start with this
  -- @treturn {string,...} the list of words in the specified subset;
  -- incidentally this will be alphabetically sorted
  subset: (prefix = "") =>
    assert @ != nil
    set = {}
    start_state = @initial_state\step_multiple_if_valid prefix
    unless start_state
      return set

    start_state\subset prefix, set
    return set

  add_words: (words) =>
    assert @ != nil and words != nil
    @previous_word = nil -- To mark this as no longer sorted-insertion TODO
    for word in *words
      @add_word word

  add_word: (word) =>
    -- Find the common prefix
    common_prefix = @common_prefix word
    current_suffix = word\sub #common_prefix + 1, #word
    -- Skip duplicates
    if current_suffix == ""
      if state = @initial_state\step_multiple_if_valid common_prefix
        return if state.final

    -- Find the first confluence state in the common prefix path
    first_confluence_state, current_index = @find_first_confluence_state common_prefix
    -- Get the last state in the common prefix path
    last_state = @initial_state\step_multiple common_prefix
    -- If we do have a confluence state in the path, use a clone the last state
    -- instead of the last state itself
    if first_confluence_state != nil
      last_state = last_state\clone!

    -- Add the suffix from the last state (or its clone)
    @add_suffix last_state, current_suffix

    -- Addition of a new suffix to the last state in the common prefix changes
    -- the right languages of all states that precede that state in the common
    -- prefix path.
    -- If a confluence state is found, all states from the first confluence
    -- state to the end of the common prefix path are cloned (last first), and
    -- then considered for replacement or registering.
    if first_confluence_state != nil
      -- Note that this loop begins with the *penultimate* state in the common
      -- prefix, because the last state has already been cloned, and the
      -- function @replace_or_register acts on a child of its argument state
      for i = #common_prefix - 1, current_index, -1
        sub_prefix = common_prefix\sub 1, i
        current_state = (@initial_state\step_multiple sub_prefix)\clone!
        current_char = common_prefix\sub i, i
        word_char = word\sub i + 1, i + 1
        current_state\add_transition current_char, last_state
        @replace_or_register current_state, (word\sub i + 1, i + 1)
        last_state = current_state
    else
      current_index = #common_prefix


    local current_state
    changed = current_index > 0
    while changed
      current_index -= 1
      sub_word = word\sub 1, current_index
      current_state = @initial_state\step_multiple sub_word
      old_state = last_state
      if current_index > 0
        @register[last_state] = nil

      current_char = word\sub current_index + 1, current_index + 1
      @replace_or_register current_state, current_char
      last_state = current_state\step_transition current_char
      changed = old_state != last_state
      last_state = current_state

    if current_index > 0
      @register[current_state] = true

  -- Returns nil if there are no confluence states
  -- Otherwise returns the first confluence state, + the # of transitions
  -- required to get there
  find_first_confluence_state: (prefix) =>
    current_state = @initial_state
    length = 0
    for char in prefix\chars!
      if current_state.is_confluence
        return current_state, length
      elseif next_state = current_state\step_if_valid char
        current_state = next_state
        length += 1
      else
        return nil

  replace_or_register: (state, symbol) =>
    child = state\step_transition symbol
    if equivalent_state = @register\equivalent_state child
      state\replace_transition symbol, equivalent_state
      child\delete!
    else
      @register[child] = true

  --- Sorted-only functions {{{

  --- Takes the given state and replaces its alphabetically last child with an
  -- equivalent one from the Register if it exists, or adds it to the register
  -- if it does not.
  --
  -- Additionally, it recursively calls itself on said child state if it in
  -- turn has children, prior to performing the above.
  --
  -- @tparam State state the state whose last child will be registered or replaced
  sorted_replace_or_register: (state) =>
    assert @ != nil and state != nil
    child = state\last_child!
    if child.has_children
      @sorted_replace_or_register child
    if equivalent_state = @register\equivalent_state child
      state\replace_last_child equivalent_state
      -- The child can't already be in the register, so we just need to tell it
      -- to clean up any transitions it may have
      child\delete!
    else
      @register[child] = true

  --- Incrementally adds a list of sorted words to the in-construction MAFSA.
  --
  -- Can be called multiple times, so long as all subsequent calls add a sorted
  -- list that starts with a word lexicographically after the
  -- most-recently-added word. It is more efficient to add all words in one
  -- pass however (skips an extra `Mafsa\sorted_replace_or_register` call).
  --
  -- @tparam {string,...} sorted_words a sorted list of words to add to the MAFSA
  add_sorted_words: (sorted_words) =>
    assert @ != nil and sorted_words != nil
    for word in *sorted_words
      @add_sorted_word word
    @sorted_replace_or_register @initial_state

  -- Splitting this out makes it testable
  add_sorted_word: (word) =>
    -- Contract checking
    if @previous_word
      if @previous_word == word
        -- Duplicates would just be merged anyway :)
  e     return
      assert word >= @previous_word,
        "add_sorted_words called on a Mafsa that has a later previous word added (word: '#{word}', previous word: '#{@previous_word}')"
    else
      assert #@initial_state.sorted_keys == 0,
        "add_sorted_words called on a Mafsa that has been initialiazed fully, or with non-sorted words"
    @previous_word = word

    common_prefix = @common_prefix word
    last_state = @initial_state\step_multiple common_prefix
    current_suffix = word\sub #common_prefix + 1, #word
    if last_state.has_children
      @sorted_replace_or_register last_state
    @add_suffix_sorted last_state, current_suffix
  -- }}}

--- Register submodule/pseudo-class.
--
-- Represents the register used during incremental construction of a minimal
-- acyclic finite-state automaton.
--
-- @type Mafsa.Register
Register =
  -- We take it on good faith that states added to the register do not already
  -- have an equivalent within it

  __class_metatable:
    __index: (tbl, key) ->
      assert tbl != nil and key != nil
      if key == "equivalent_state"
        return Register[key]
      else
        return rawget tbl, key

  --- Creates a new Register.
  -- @treturn Register a new Register instance
  new: () ->
    return setmetatable {}, Register.__class_metatable

  --- Search in the register for an equivalent state to the given one.
  --
  -- Equivalence here is defined by the formal 'equivalence class' from the
  -- paper.
  --
  -- @tparam State state the State to compare against
  -- @treturn State|nil returns either the (sole) matching State, or nil
  equivalent_state: (state) =>
    assert @ != nil and state != nil
    for register_state, _val in pairs @
      if state\is_equivalent_to register_state
        return register_state
    return nil

--- State submodule/pseudo-class.
--
-- Represents individual states in an acyclic finite state machine.
--
-- @type Mafsa.State
State =
  __class_metatable:
    __index: (state, key) ->
      assert state != nil and key != nil
      switch key
        -- Pass these through to the underlying table
        when "transitions", "final", "sorted_keys"
          return rawget state, key
        -- Calculate these on the fly
        when "is_confluence"
          return state.incoming > 1
        when "has_children"
          return #state.sorted_keys > 0
        -- Use 'class' methods, if they exist
        else
          return State[key]

  --- Creates a new State.
  -- @treturn State a new State instance
  new: () ->
    new_state =
      transitions: {}
      sorted_keys: {}
      final: false
      incoming: 0
    setmetatable new_state, State.__class_metatable
    return new_state\__update_state_hash!

  --- Clones an existing State.
  --
  -- Cloning a new state creates a new state that has outgoing transitions with
  -- the same labels to the same destination states as the cloned state.
  --
  -- Algorithmic Invariants:
  -- 1. The clone is only final if the original is
  -- 2. The clone has the same number of transitions as the original
  -- 3. The clone has the same set of transition labels as the original
  -- 4. One of:
  --     1) The clone has the same right language as the original
  --     2) Each of the clone's transition labels lead to the same state as the
  --        corresponding label on the original -- if this is a sorted-input
  --        MAFSA
  --
  -- Implementation Invariants:
  --
  -- 5. The clone has 0 incoming transition count
  -- 6. The clone is a different table to the original
  -- 7. After cloning, each of the original's transitions have an increased
  --    incoming transition count
  --
  -- Additionally, 1 through 4 can be looked at as "similarities" between the
  -- clone and the original, 5 and 6 are "differences" between them.
  --
  -- No matter the concrete implementation, 5 must hold in some sense.
  --
  -- @treturn State the clone crdopy of the given State
  clone: () =>
    assert @ != nil
    new_state = with {}
      .transitions = clone_table @transitions
      .sorted_keys = clone_table @sorted_keys
      .final = @final
      .incoming = 0
      .hash = @hash
    setmetatable new_state, State.__class_metatable

    for _label, transition_state in pairs new_state.transitions
      transition_state.incoming += 1

    return new_state

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
  iterate_transitions: () =>
    assert @ != nil
    return sorted_iterator @transitions, @sorted_keys

  --- Adds a new State transition to an existing State.
  --
  -- Invariants:
  -- 1. The target state should become accessible from the source state, as a
  --    transition with the given label
  --
  -- Implementation Invariants:
  -- 2. The incoming transition count on the target state should increment
  -- 3. The total transition count on the source state should increment
  -- 4. The list of transitions on the source state should remain
  --    lexicographically sorted afterward
  -- 5. The hash of the source state should change
  --
  -- @tparam string label the label for the new transition
  -- @tparam State transition_state the state to direct the transition to
  -- @treturn State the self-State (to enable function chaining)
  add_transition: (label, transition_state) =>
    assert @ != nil and transition_state != nil,
      "self and transition_state must both be valid States (were: '#{@}', '#{transition_state}' respectively)"
    assert @transitions[label] == nil,
      "Cannot add transition with label #{label} to state #{@} because it already has a transition with that label"
    with @
      .transitions[label] = transition_state
      .sorted_keys = sorted_key_list @transitions
      \__update_state_hash!
    transition_state.incoming += 1
    return @

  replace_transition: (label, transition_state) =>
    assert @ != nil and transition_state != nil,
      "self and transition_state must both be valid States (were: '#{@}', '#{transition_state}' respectively)"
    assert @transitions[label] != nil,
      "Cannot replace transition with label #{label} to go to state #{@} because it does not already have a transition with that label"
    @transitions[label] = nil
    return @add_transition label, transition_state

  --- Sets the 'final' flag on a State to the given value.
  -- @tparam boolean val the value to set the flag to
  -- @treturn State the self-state (to enable function chaining)
  set_final: (val) =>
    assert @ != nil
    assert val != nil and assert type(val) == "boolean",
      "val must be a boolean value (given '#{val}')"
    return with @
      .final = val
      \__update_state_hash!

  --- Updates the State's hash value.
  --
  -- We use a hash to represent and compare all four equivalence class
  -- properties for any two states:
  -- 1. Both are final or non-final
  -- 2. Both have the same number of outgoing transitions
  -- 3. Corresponding outgoing transitions have the same labels
  -- 4. Corresponding outgoing transitions have the same right language -- this
  --    must be confirmed manually each time (see Register.equivalent_state()),
  --    as we can't update it without detecting updates of all substates of
  --    this state
  __update_state_hash: () =>
    assert @ != nil
    @hash = "f:#{@final}.n:#{#@sorted_keys}.l:#{@__get_labels!}"
    return @

  --- Gets the sorted set of transition labels as a string.
  __get_labels: () =>
    assert @ != nil
    ret = ""
    for label, _transition in @iterate_transitions!
      ret ..= label
    return ret

  --- Returns the 'right language' of the State.
  --
  -- Sorted recursive iteration of the character set used gives deterministic
  -- representation of the right language.
  __get_right_language: () =>
    assert @ != nil
    ret = ""
    if #@sorted_keys > 0
      for label, transition in @iterate_transitions!
        ret ..= "#{label}#{transition\__get_right_language!}"
      -- print "Built ret for state #{@}: #{ret}"
    else
      nil
      -- print "Empty sorted keys on state #{inspect @}"
    return ret

  --- Steps forward one State.
  --
  -- Theoretically, the result of performing a step with an invalid label is
  -- undefined, and in this function we throw an exception.
  --
  -- @tparam character label the character label of the transition to step across
  -- @treturn State the state transitioned to
  step_transition: (label) =>
    assert @ != nil and label != nil
    if label == ""
      return @
    elseif next_state = @transitions[label]
      return next_state
    else
      error "Undefined next_state for transition with label #{label} on state #{@}:#{inspect @}"

  --- Steps forward one State, if the label is valid for the given State.
  --
  -- The same as `step_transition`, but rather than throwing an exception on a
  -- non-existent label, it returns `nil`.
  --
  -- @tparam character label the character label of the transition to step across
  -- @treturn State the State transitioned to
  step_if_valid: (label) =>
    assert @ != nil and label != nil
    return @transitions[label]

  --- Steps forward multiple States.
  --
  -- Iterates through the characters in the given word and steps through a
  -- chain of State transitions using them.
  --
  -- @tparam string word the string to use as a source of labels to step across
  -- @treturn State the State transitioned to
  step_multiple: (word) =>
    assert @ != nil and word != nil
    current_state = @
    for char in word\chars!
      current_state = current_state\step_transition char
    return current_state

  --- Steps forward multiple States, if the word forms a sequence of valid
  -- labels for the given State chain.
  --
  -- The same as `step_multiple`, but rather than throwing an exception on a
  -- non-existent transition label, it returns `nil`.
  --
  -- @tparam string word the string to use as a source of labels to step across
  -- @treturn State the State transitioned to
  step_multiple_if_valid: (word) =>
    assert @ != nil and word != nil
    current_state = @
    for char in word\chars!
      current_state = current_state\step_if_valid char
      if not current_state
        return nil
    return current_state

  --- Replaces the alphabetically-last label's transition state.
  -- @tparam State new_child the State to replace the last child with
  -- @treturn State the self-State (to enable function chaining)
  replace_last_child: (new_child) =>
    assert @ != nil and new_child != nil
    @transitions[@last_child_label!] = new_child
    new_child.incoming += 1
    return @

  --- Returns the alphabetically-last label's transition State.
  -- @treturn State the child state
  last_child: () =>
    assert @ != nil
    if @has_children
      return @transitions[@last_child_label!]
    else
      error "last_child called on a state with no children, state #{@}:#{inspect @}"

  --- Returns the alphabetically-last label.
  -- @treturn character the alphabetically-last label
  last_child_label: () =>
    assert @ != nil
    return @sorted_keys[#@sorted_keys]

  --- Cleans up a State in preparation for being GC'd.
  --
  -- Required to properly track confluence states among pointed-to children
  -- states.
  --
  -- @treturn character the alphabetically-last label
  delete: () =>
    assert @ != nil
    for _label, transition_state in pairs @transitions
      transition_state.incoming -= 1
    return nil

  --- Checks if a State is in the same equivalence class as another State.
  -- @tparam State other_state the second State which is being compared
  -- @treturn boolean whether or not both states are in the same equivalence class
  is_equivalent_to: (other_state) =>
    assert @ != nil and other_state != nil
    -- __get_right_language! is relatively expensive, because it's
    -- recursive and can't easily be cached at state-update time, so we
    -- compare by hash first
    if @hash == other_state.hash
      if @__get_right_language! == other_state\__get_right_language!
        return true
      else
        return false

  --- Adds to the accumulator the subset of strings reachable from this State,
  -- optionally prefixed by the given prefix.
  --
  -- @tparam[opt=''] string prefix prepends this to each string in the subset
  -- @tparam {string,...} accumulator the array to append new strings to
  subset: (prefix = "", accumulator) =>
    assert @ != nil and accumulator != nil
    if @final
      accumulator[#accumulator + 1] = prefix

    for label, transition in @iterate_transitions!
      transition\subset prefix .. label, accumulator

return with Mafsa
  .Register = Register
  .State = State
