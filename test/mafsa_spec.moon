-- Manipulate the package path
path = require 'pl.path'
source_path = debug.getinfo(1).source\sub(2, -1) -- Relative path of currently-executing file
source_path = path.dirname(path.abspath source_path)
source_path = path.normpath("#{source_path}/../moon/earthshine/mafsa")
package.moonpath = "#{source_path}/?.moon;#{package.moonpath}"
inspect = require 'inspect'

earthshine_table = require 'earthshine.table'
clone_table = earthshine_table.clone
require 'earthshine.string'

local *

describe "MAFSA package tests:", ->
  Mafsa = require 'earthshine.mafsa'
  import State, Register from Mafsa

  describe "State tests:", ->
    describe "new! tests:", -> -- {{{
      local new_state

      before_each ->
        new_state = State.new!

      it "has the correct metatable", ->
        assert.are.equals getmetatable(new_state), State.__class_metatable

      it "has empty .transitions and .sorted_keys", ->
        assert.are.equals 0, #new_state.transitions
        assert.are.equals 0, #new_state.sorted_keys

      it "has no incoming transitions set", ->
        assert.are.equals 0, new_state.incoming

      it "is not final", ->
        assert.is.False new_state.final

      it "has the correct hash", ->
        assert.are.equals "f:false.n:0.l:", new_state.hash

      it "has the correct right language", ->
        assert.are.equals "", new_state\__get_right_language!
    -- }}}

    describe "clone! tests:", -> -- {{{
      local state
      setup ->
        parent_state = State.new!
        state = with State.new!
          \add_transition "a", State.new!
          \add_transition "z", State.new!
          \add_transition "d", State.new!
        parent_state\add_transition "a", state

      it "has the same metatable as the original", ->
        cloned_state = state\clone!

        assert.are.equals getmetatable(cloned_state), getmetatable(state)

      it "has the same .transitions and .sorted_keys as the original", ->
        cloned_state = state\clone!

        assert.are.equals #cloned_state.transitions, #state.transitions
        assert.are.equals #cloned_state.sorted_keys, #state.sorted_keys
        for i, label in pairs state.sorted_keys
          assert.are.equals label, cloned_state.sorted_keys[i]
          assert.are.equals state.transitions[label], cloned_state.transitions[label]

      it "has the same final value as the original", ->
        cloned_state = state\clone!

        assert.are.equals state.final, cloned_state.final

      it "has the same hash as the original", ->
        cloned_state = state\clone!

        assert.are.equals state.hash, cloned_state.hash

      it "has the same right language as the original", ->
        cloned_state = state\clone!

        assert.are.equals state\__get_right_language!, cloned_state\__get_right_language!

      it "has no incoming transitions", ->
        cloned_state = state\clone!

        assert.are.equals 0, cloned_state.incoming

      it "is not the same object as the original", ->
        cloned_state = state\clone!

        assert.are.not.equal state, cloned_state

      it "increases the incoming transition count on all pointed-to transitions", ->
        old_counts = {}
        for label, transition in state\iterate_transitions!
          old_counts[label] = transition.incoming

        cloned_state = state\clone!

        for label, transition in state\iterate_transitions!
          assert.are.equal old_counts[label] + 1 , transition.incoming
    -- }}}

    describe "add_transition() tests:", -> -- {{{
      local state
      before_each ->
        state = State.new!

      describe "single transition tests:", -> -- {{{
        local next_state, label
        before_each ->
          next_state = State.new!
          label = "a"

        it "makes the target state reachable from the source state under the given label", ->
          assert.is.Nil state\step_if_valid label

          state\add_transition label, next_state

          assert.are.equals (state\step_if_valid label), next_state

        it "increments the count of sorted transition labels", ->
          label_count = #state.sorted_keys

          state\add_transition label, next_state

          assert.are.equals label_count + 1, #state.sorted_keys

        it "has a sorted label list entry corresponding to the correct label", ->
          for existing_label in *state.sorted_keys
            assert.are.not.same label, existing_label

          state\add_transition label, next_state

          seen_label = false
          for current_label in *state.sorted_keys
            if current_label == label
              seen_label = true
          assert seen_label

        it "has a different hash than originally", ->
          old_hash = state.hash

          state\add_transition label, next_state

          assert.are.not.equal old_hash, state.hash

        it "has the correct hash", ->
          expected_hash = "f:false.n:1.l:#{label}"
          assert.are.not.equals expected_hash, state.hash

          state\add_transition label, next_state

          assert.are.equal expected_hash, state.hash

        it "has a different right language than originally", ->
          old_right_language = state\__get_right_language!

          state\add_transition label, next_state

          assert.are.not.equal old_right_language, state\__get_right_language!

        it "has the correct right language", ->
          state\add_transition label, next_state

          assert.are.equal "a", state\__get_right_language!

        it "increases the incoming transition count on the target state", ->
          old_count = next_state.incoming

          state\add_transition label, next_state

          assert.are.equal old_count + 1, next_state.incoming
      -- }}}

      describe "multiple transition tests:", -> -- {{{
        labels = { "a", "z", "c" }
        local next_states

        before_each ->
          next_states = {}

        add_transitions_with_fn = (fn) ->
          for i, label in ipairs labels
            next_states[i] = State.new!
            state\add_transition label, next_states[i]
            fn!

        add_transitions = -> add_transitions_with_fn -> nil

        assert_lexicographically_sorted = (tbl) ->
          key, val = next tbl, nil
          previous_val = nil
          while key != nil
            if previous_val
              assert val > previous_val
            previous_val = val
            key, val = next tbl, key

        it "preserves the lexicographical sorting of the labels after each addition", ->
          add_transitions_with_fn, ->
            assert_lexicographically_sorted state.sorted_keys

        it "has the correct right language", ->
          add_transitions!

          assert.are.equals "acz", state\__get_right_language!

        it "has the correct hash", ->
          add_transitions!

          assert.are.equals "f:false.n:3.l:acz", state.hash
      -- }}}

    -- }}}

  describe "last_child_label! tests:", -> -- {{{
    local state
    before_each ->
      state = State.new!

    it "tests that nil is returned for a state with no children", ->
      assert.is.Nil state\last_child_label!

    it "tests that the correct label is returned with only one child", ->
      child_state = State.new!
      label = "a"
      state\add_transition label, child_state
      assert.are.equal label, state\last_child_label!

    it "tests that the correct label is returned with multiple children", ->
      first_state = State.new!
      last_state = State.new!
      first_label = "a"
      last_label = "z"
      with state
        \add_transition last_label, last_state
        \add_transition first_label, first_state
      assert.are.equal last_label, state\last_child_label!
  -- }}}

  describe "last_child! tests:", -> -- {{{
    local state
    before_each ->
      state = State.new!

    it "tests that an exception is thrown for a state with no children", ->
      expected_error = "last_child called on a state with no children, state #{state}:#{inspect state}"
      should_error = ->
        state\last_child!
      assert.has.error should_error, expected_error

    it "tests that the correct state is returned with only one child", ->
      child_state = State.new!
      label = "a"
      state\add_transition label, child_state
      assert.are.equal child_state, state\last_child!

    it "tests that the correct state is returned with multiple children", ->
      first_state = State.new!
      last_state = State.new!
      first_label = "a"
      last_label = "z"
      with state
        \add_transition last_label, last_state
        \add_transition first_label, first_state
      assert.are.equal state\last_child!, last_state
  -- }}}

  describe "replace_last_child() tests:", -> -- {{{
    local state, existing_child, label
    before_each ->
      state = State.new!
      existing_child = State.new!
      label = "z"
      state\add_transition label, existing_child

    it "tests that the child is replaced with only one child", ->
      new_child = State.new!
      assert.are.equal existing_child, state\step_transition label
      state\replace_last_child new_child
      assert.are.equal new_child, state\step_transition label

    it "tests that the correct child is replaced among multiple children", ->
      earlier_child = State.new!
      earlier_label = "a"
      new_child = State.new!

      state\add_transition earlier_label, earlier_child
      assert.are.equal existing_child, state\step_transition label
      state\replace_last_child new_child
      assert.are.equal new_child, state\step_transition label

    it "tests that the replaced child has an incremented incoming value", ->
      new_child = State.new!
      assert.are.equal 0, new_child.incoming
      state\replace_last_child new_child
      assert.are.equal 1, new_child.incoming
  -- }}}

  describe "has_children tests:", -> -- {{{
    local state
    before_each ->
      state = State.new!

    it "tests that a state without children returns false", ->
      assert.is.False state.has_children

    it "tests that a state with 1 child returns true", ->
      with state
        \add_transition "a", State.new!
      assert.is.True state.has_children

    it "tests that a state with multiple children returns true", ->
      with state
        \add_transition "a", State.new!
        \add_transition "b", State.new!
      assert.is.True state.has_children
  -- }}}

    describe "set_final() tests:", -> -- {{{
      local state
      before_each ->
        state = State.new!

      it "changes the value correctly", ->
        state\set_final true
        assert.is.True state.final
        state\set_final false
        assert.is.False state.final

      it "changes the hash", ->
        old_hash = state.hash

        state\set_final true

        assert.are.not.equal old_hash, state.hash

      it "updates the hash correctly", ->
        state\set_final true
        assert.are.equals "f:true.n:0.l:", state.hash
        state\set_final false
        assert.are.equals "f:false.n:0.l:", state.hash
    -- }}}

    describe "iterate_transitions! tests:", -> -- {{{
      local state
      before_each ->
        state = with State.new!
          \add_transition "a", State.new!
          \add_transition "z", State.new!
          \add_transition "d", State.new!

      it "should return keys in lexicographically increasing order", ->
        previous_key = nil

        for key, value in state\iterate_transitions!
          if previous_key
            assert previous_key < key
          previous_key = key

      it "should return only (key, value) pairs that are present in the state's transitions", ->
        for key, value in state\iterate_transitions!
          assert.are.same state.transitions[key], value

      it "should return all the (key, value) pairs that are present in the state's transitions", ->
        seen_pairs = {}

        for key, value in state\iterate_transitions!
          seen_pairs[key] = value

        key, val = next state.transitions, nil
        while key != nil
          assert.are.same val, seen_pairs[key]
          key, val = next state.transitions, key
    -- }}}


  describe "Register tests:", ->
    -- {{{
    local register
    before_each ->
      register = Register.new!

    describe "new! tests:", ->
      it "has the correct metatable", ->
        assert.are.equal Register.__class_metatable, getmetatable(register)

      it "returns a function for 'equivalent_state' lookups", ->
        assert.are.equal type(register.equivalent_state), "function"

    it "correctly returns added members", ->
      state = State.new!
      register[state] = true
      assert.is.True register[state]

    describe "equivalent_state() tests:", ->
      local state, label, child_state

      before_each ->
        child_state = State.new!
        label = "a"
        state = with State.new!
          \add_transition label, child_state

      it "returns nil if there is no matching state", ->
        assert.is.Nil register\equivalent_state state

      it "returns the state if there is a matching state", ->
        equivalent_state = with State.new!
          \add_transition label, State.new!
        non_equivalent_state = with State.new!
          \add_transition label, State.new!
          \add_transition "b", State.new!
          \add_transition "c", State.new!
        register[equivalent_state] = true
        register[non_equivalent_state] = true
        assert.are.equal equivalent_state, register\equivalent_state state
  -- }}}

  describe "Mafsa tests:", ->
    describe "add_suffix_sorted() tests:", -> -- {{{
      local mafsa
      suffix = "bar"

      before_each ->
        mafsa = with Mafsa.new!
          \add_suffix_sorted .initial_state, suffix

      it "adds the correct transitions in the correct order", ->
        current_state = mafsa.initial_state
        i = 1
        for i = 1, #suffix
          char = suffix\sub i, i
          assert.is.not.Nil current_state\step_if_valid char
          assert.are.equal 1, #current_state.sorted_keys
          -- final = if i == #suffix then true else false
          expected_hash = "f:false.n:1.l:#{char}"
          assert.are.equal expected_hash, current_state.hash
          expected_right_language = (suffix\sub i, -1)
          assert.are.equal expected_right_language, current_state\__get_right_language!
          current_state = current_state\step_transition char

        last_state = current_state
        assert.are.equals 0, #last_state.sorted_keys

      it "marks the last state (and only the last state) in the branch as final", ->
        current_state = mafsa.initial_state
        for char in suffix\chars!
          assert.is.False current_state.final
          current_state = current_state.transitions[char]

        last_state = current_state
        assert.is.True last_state.final
    -- }}}

    describe "common_prefix() tests:", -> -- {{{
      local mafsa, prefix, common_prefix, expected_prefix
      existing_string = "foobar"
      -- Another string to add via add_suffix_sorted directly off the initial node;
      -- must form a totally independent branch of the MAFSA in order to be
      -- added this way validly. We add it to ensure that having branches does
      -- not confused common_prefix()
      -- TODO tests with confluent states
      extra_string = "nak"

      before_each ->
        mafsa = with Mafsa.new!
          \add_suffix_sorted .initial_state, existing_string
          \add_suffix_sorted .initial_state, extra_string

      prefix_before_each = (local_prefix) ->
        ->
          prefix = local_prefix
          common_prefix = mafsa\common_prefix prefix
          expected_prefix = string.lcp { prefix, existing_string }

      expected_prefix_test = {
        "returns the expected portion of the prefix",
        ->
          assert.are.equals common_prefix, expected_prefix
      }
      valid_prefix_state_test = {
        "tests that returned prefix can be stepped through to retrieve a valid state",
        ->
          current_state = mafsa.initial_state
          for char in common_prefix\chars!
            assert.is.not.Nil current_state\step_if_valid char
            current_state = current_state\step_transition char
      }
      longest_possible_prefix_test = {
        "tests that returned prefix is the longest one that returns a valid state",
        ->
          -- test is only valid for cases where the returned common_prefix is shorter than the argument prefix
          if #common_prefix < #prefix
            current_state = mafsa.initial_state
            longer_prefix = prefix\sub 1, #common_prefix + 1

            last_state = current_state\step_multiple common_prefix
            last_label = prefix\sub #common_prefix + 1, #common_prefix + 1
            expected_error = "Undefined next_state for transition with label #{last_label} on state #{last_state}:#{inspect last_state}"
            should_error = ->
              current_state\step_multiple longer_prefix

            assert.has.error should_error, expected_error
      }

      describe "tests with prefix matching part of existing string:", ->
        before_each (prefix_before_each "foo")
        it unpack expected_prefix_test
        it unpack valid_prefix_state_test
        it unpack longest_possible_prefix_test

      describe "tests with prefix match to end of existing string:", ->
        before_each (prefix_before_each "foobar")
        it unpack expected_prefix_test
        it unpack valid_prefix_state_test
        it unpack longest_possible_prefix_test

      describe "tests with prefix longer than end of existing string:", ->
        before_each (prefix_before_each "foobarbaz")
        it unpack expected_prefix_test
        it unpack valid_prefix_state_test
        it unpack longest_possible_prefix_test

      describe "tests with prefix not matching:", ->
        before_each (prefix_before_each "hello")
        it unpack expected_prefix_test
        it unpack valid_prefix_state_test
        it unpack longest_possible_prefix_test
    -- }}}

    describe "sorted_replace_or_register() tests:", -> -- {{{
      local mafsa
      label = "z"

      make_state_with_child = ->
        with State.new!
          \add_transition "a", State.new!

      before_each ->
        mafsa = Mafsa.new!

      -- Mafsa.sorted_replace_or_register(state) should:
      -- - Work on the lexicographically last child of the argument state
      -- - Initially be called with the argument that is the last state in the
      --   common_prefix path
      --     - Or with the initial state in the final usage
      -- - The function starts by calling itself recursively until it reaches the
      --   end of the path of the previously added word
      --     - It does so because always selecting the lexicographically last
      --       child when recursing to the child state effectively selects the
      --       path most-recently added, because words are added in
      --       lexicographical order
      -- - After recursing down the full depth of the previously-added word, it
      --   checks whether a state equivalent to the current 'last child' state
      --   can be found in the register
      -- - If one can, it replaces the current child with the registered state
      -- - If not, it registers the current child
      -- - It then continues spooling back up the call stack, replacing or
      --   registering the parent of the state it just worked on

      -- Test ideaas:
      -- - Check that equivalent new state gets replaced by registered state
      --     - Confirm it is not itself registered
      -- - Check that new state gets registered due to lacking equivalent
      -- - Confirm that the states are considered in reverse order

      describe "registered equivalent tests:", ->
        local state, equivalent_state, child_state
        before_each ->
          equivalent_state = make_state_with_child!
          mafsa.register[equivalent_state] = true
          child_state = make_state_with_child!
          state = with State.new!
            \add_transition label, child_state

        it "tests that a child state with a registered equivalent gets replaced by the equivalent", ->
          assert.are.not.equals equivalent_state, child_state
          assert.are.equals state.transitions[label], child_state

          mafsa\sorted_replace_or_register state

          assert.are.not.equals state.transitions[label], child_state
          assert.are.equals state.transitions[label], equivalent_state

        it "tests that a child state with a registered equivalent is not itself registered", ->
          mafsa\sorted_replace_or_register state
          assert.is.Nil mafsa.register[child_state]

      it "tests that a child state without a registered equivalent gets registered", ->
        child_state = make_state_with_child!
        assert.is.Nil mafsa.register[child_state]
        state = with State.new!
          \add_transition label, child_state
        mafsa\sorted_replace_or_register state
        assert.is.True mafsa.register[child_state]

      describe "recursive tests:", ->
        local states
        word = "foobar"
        before_each ->
          mafsa\add_suffix_sorted mafsa.initial_state, word

          -- Get a list of the added states in word-order
          current_state = mafsa.initial_state
          states = { current_state }
          for char in word\chars!
            current_state = current_state\step_transition char
            states[#states + 1] = current_state

        it "tests that the states are checked for equivalency in reverse word order", ->
          order = word\reverse!

          -- Set up a spy on the equivalent_state function
          equivalent_state_spy = spy.on mafsa.register, "equivalent_state"
          -- Call the tested function
          mafsa\sorted_replace_or_register mafsa.initial_state

          -- The spy tracks calls in a list of tables:
          -- { refs: { ... }, vals: { arg1, arg2, ..., argn } }
          -- We need to inspect each `vals[2]` to confirm the transition labels
          -- match up to the reverse order
          calls = equivalent_state_spy.calls
          for i, call in ipairs calls
            checked_state = call.vals[2]
            -- The very first call should be to a state with no children (the final state)
            if i == 1
              assert.are.equal 0, #checked_state.sorted_keys
            else
              -- Because the first call is to the final state, we need to lower
              -- the index by 1 when checking the other transition labels to
              -- verify the call order correctly
              char = order\sub i - 1, i - 1
              assert.is.not.falsy checked_state.transitions[char]
              assert.are.equal #checked_state.sorted_keys, 1
              -- Unfortunately, we can't directly compare the state tables like
              -- the below, because luassert.spy works by copying the arguments
              -- in the case of reference types like tables.
              -- assert.are.equal checked_state, states[#states + 1 - i]

        it "tests that each of the new states do end up registered", ->
          mafsa\sorted_replace_or_register mafsa.initial_state

          -- We can skip the first one, because Mafsa.initial_state is never registered
          for i = 2, #states
            state = states[i]
            assert.is.True mafsa.register[state]
    -- }}}

    describe "add_sorted_word() tests:", -> -- {{{
      local mafsa, sorted_words

      before_each ->
        sorted_words = {"foobar", "zebra", "foo", "foonot", "notbar", "follar", "wollak"}
        table.sort sorted_words
        mafsa = Mafsa.new!

      it "increases the length of the right language of the initial state after each call", ->
        -- Well, for non-duplicate input words. Because they're sorted we don't
        -- need to worry about words that are prefixes of other words.
        previous_length = 0

        for word in *sorted_words
          mafsa\add_sorted_word word
          current_length = #(mafsa.initial_state\__get_right_language!)
          assert previous_length < current_length
          previous_length = current_length
    -- }}}

    describe "add_sorted_words() tests:", -> -- {{{
      base_word = "foobar"
      later_word = "zebra"
      sub_word = "foo"
      prefix_shared = "foonot"
      suffix_shared = "notbar"
      -- both_shared shares prefix and suffix with existing_string
      both_shared = "follar"
      local mafsa

      before_each ->
        mafsa = Mafsa.new!

      it "tests that prefixes are shared between added words", -> -- {{{
        sorted_words = { base_word, prefix_shared }
        table.sort sorted_words

        mafsa\add_sorted_words sorted_words
        base_prefix = string.lcp sorted_words

        -- For the base_prefix's states, there should each be only one child,
        -- up to the last one
        current_state = mafsa.initial_state
        for char in (base_prefix\sub 1, -2)\chars!
          assert.are.equal 1, #current_state.sorted_keys
          assert.are.equal char, current_state.sorted_keys[1]
          current_state = current_state\step_transition char

        -- The last state in the base_prefix should instead have 2 children
        last_shared_state = mafsa.initial_state\step_multiple base_prefix
        assert.are.equal 2, #last_shared_state.sorted_keys

        -- After that, we should have two chains of states, equal to the two suffixes
        for word in *sorted_words
          suffix = word\sub #base_prefix + 1, -1
          current_state = last_shared_state
          for char in suffix\chars!
            assert.is.not.Nil current_state\step_if_valid char
            current_state = current_state\step_transition char
          assert.is.True current_state.final
      -- }}}

      it "tests that the suffixes are shared between added words", -> -- {{{
        sorted_words = { base_word, suffix_shared }
        table.sort sorted_words

        mafsa\add_sorted_words sorted_words
        base_suffix = string.lcs sorted_words

        -- We start with the initial state breaking out into two separate
        -- chains of states, up to the shared suffix
        local current_state
        after_prefix = {}
        for word in *sorted_words
          prefix = word\sub 1, #word - #base_suffix
          current_state = mafsa.initial_state
          -- Initial state has two children, subsequent prefix chains only have
          -- 1 child
          assert.are.equal 2, #current_state.sorted_keys

          -- for char in prefix\chars!
          for i = 1, #prefix
            char = prefix\sub i, i
            assert.is.not.Nil current_state\step_if_valid char
            current_state = current_state\step_transition char
            assert.are.equal 1, #current_state.sorted_keys

            -- Keep track of the state that follows the prefix for later
            -- comparison
            if i == #prefix
              after_prefix[#after_prefix + 1] = current_state

        -- Confirm that the following state of each chain is the same
        assert.are.equal current_state, after_prefix[1], after_prefix[2]
        for i = 1, #after_prefix
          assert.are.equal current_state, after_prefix[i]
        assert.is.True current_state.is_confluence

        -- Now check that the suffix is shared
        for i = 1, #base_suffix
          char = base_suffix\sub i, i

          -- Each should only have a single child
          if i != 1
            assert.are.equal 1, #current_state.sorted_keys
          assert.is.not.Nil current_state\step_if_valid char
          current_state = current_state\step_transition char

        assert.is.True current_state.final
      -- }}}

      it "tests that both prefix and suffix can be shared between added words", -> -- {{{
        sorted_words = { base_word, both_shared }
        table.sort sorted_words

        mafsa\add_sorted_words sorted_words
        base_prefix = string.lcp sorted_words
        base_suffix = string.lcs sorted_words

        -- Confirm that each state in the base_prefix path has only one child,
        -- up to the last one
        current_state = mafsa.initial_state
        for char in (base_prefix\sub 1, -2)\chars!
          assert.are.equal 1, #current_state.sorted_keys
          assert.are.equal char, current_state.sorted_keys[1]
          current_state = current_state\step_transition char

        -- The last state in the base_prefix should instead have 2 children
        last_shared_state = mafsa.initial_state\step_multiple base_prefix
        assert.are.equal 2, #last_shared_state.sorted_keys

        -- Now we should have two separate chains, up until the shared suffix
        after_unique_middle = {}
        for word in *sorted_words
          char_start, char_end = #base_prefix + 1, #word - #base_suffix

          current_state = last_shared_state
          for i = char_start, char_end
            char = word\sub i, i
            assert.is.not.Nil current_state\step_if_valid char
            current_state = current_state\step_transition char
            assert.are.equal 1, #current_state.sorted_keys

            -- Keep track of the state that follows the word-unique portion,
            -- for later comparison
            if i == char_end
              after_unique_middle[#after_unique_middle + 1] = current_state

        -- Confirm that the following state of each chain is the same
        for i = 2, #after_unique_middle
          assert.are.equal after_unique_middle[1], after_unique_middle[i]
        assert.is.True current_state.is_confluence

        -- Now check that the suffix is shared
        current_state = after_unique_middle[1]
        for i = 1, #base_suffix
          char = base_suffix\sub i, i

          -- Each should only have a single child
          if i != 1
            assert.are.equal 1, #current_state.sorted_keys
          assert.is.not.Nil current_state\step_if_valid char
          current_state = current_state\step_transition char

        assert.is.True current_state.final
      -- }}}

      it "tests that words can be added in separate calls with identical results", ->
        first_words = { base_word }
        last_words = { later_word }
        all_words = { base_word, later_word }
        split_call_mafsa = mafsa

        split_call_mafsa\add_sorted_words first_words
        split_call_mafsa\add_sorted_words last_words
        single_call_mafsa = Mafsa.new!
        single_call_mafsa\add_sorted_words all_words

        assert.is.True single_call_mafsa\is_equivalent_to split_call_mafsa

      it "tests that all (and only) the words added are in the subset of the initial state", ->
        sorted_words = { base_word, later_word, sub_word, prefix_shared, suffix_shared, both_shared }
        table.sort sorted_words

        mafsa\add_sorted_words sorted_words

        subset = mafsa\subset ""
        table.sort subset
        for i = 1, #sorted_words
          assert.are.equal sorted_words[i], subset[i]
        assert.are.equal #sorted_words, #subset
    -- }}}

    describe "add_words() tests:", -> -- {{{
      base_word = "foobar"
      later_word = "zebra"
      sub_word = "foo"
      prefix_shared = "foonot"
      suffix_shared = "notbar"
      -- both_shared shares prefix and suffix with existing_string
      both_shared = "follar"
      local mafsa

      before_each ->
        mafsa = Mafsa.new!

      it "tests that prefixes are shared between added words", -> -- {{{
        words = { prefix_shared, base_word }

        mafsa\add_words words
        base_prefix = string.lcp words

        -- For the base_prefix's states, there should each be only one child,
        -- up to the last one
        current_state = mafsa.initial_state
        for char in (base_prefix\sub 1, -2)\chars!
          assert.are.equal 1, #current_state.sorted_keys
          assert.are.equal char, current_state.sorted_keys[1]
          current_state = current_state\step_transition char

        -- The last state in the base_prefix should instead have 2 children
        last_shared_state = mafsa.initial_state\step_multiple base_prefix
        assert.are.equal 2, #last_shared_state.sorted_keys

        -- After that, we should have two chains of states, equal to the two suffixes
        for word in *words
          suffix = word\sub #base_prefix + 1, -1
          current_state = last_shared_state
          for char in suffix\chars!
            assert.is.not.Nil current_state\step_if_valid char
            current_state = current_state\step_transition char
          assert.is.True current_state.final
      -- }}}

      it "tests that the suffixes are shared between added words", -> -- {{{
        words = { suffix_shared, base_word }

        mafsa\add_words words
        base_suffix = string.lcs words

        -- We start with the initial state breaking out into two separate
        -- chains of states, up to the shared suffix
        local current_state
        after_prefix = {}
        for word in *words
          prefix = word\sub 1, #word - #base_suffix
          current_state = mafsa.initial_state
          -- Initial state has two children, subsequent prefix chains only have
          -- 1 child
          assert.are.equal 2, #current_state.sorted_keys

          -- for char in prefix\chars!
          for i = 1, #prefix
            char = prefix\sub i, i
            assert.is.not.Nil current_state\step_if_valid char
            current_state = current_state\step_transition char
            assert.are.equal 1, #current_state.sorted_keys

            -- Keep track of the state that follows the prefix for later
            -- comparison
            if i == #prefix
              after_prefix[#after_prefix + 1] = current_state

        -- Confirm that the following state of each chain is the same
        assert.are.equal current_state, after_prefix[1], after_prefix[2]
        for i = 1, #after_prefix
          assert.are.equal current_state, after_prefix[i]
        assert.is.True current_state.is_confluence

        -- Now check that the suffix is shared
        for i = 1, #base_suffix
          char = base_suffix\sub i, i

          -- Each should only have a single child
          if i != 1
            assert.are.equal 1, #current_state.sorted_keys
          assert.is.not.Nil current_state\step_if_valid char
          current_state = current_state\step_transition char

        assert.is.True current_state.final
      -- }}}

      it "tests that both prefix and suffix can be shared between added words", -> -- {{{
        words = { base_word, both_shared }

        mafsa\add_words words
        base_prefix = string.lcp words
        base_suffix = string.lcs words

        -- Confirm that each state in the base_prefix path has only one child,
        -- up to the last one
        current_state = mafsa.initial_state
        for char in (base_prefix\sub 1, -2)\chars!
          assert.are.equal 1, #current_state.sorted_keys
          assert.are.equal char, current_state.sorted_keys[1]
          current_state = current_state\step_transition char

        -- The last state in the base_prefix should instead have 2 children
        last_shared_state = mafsa.initial_state\step_multiple base_prefix
        assert.are.equal 2, #last_shared_state.sorted_keys

        -- Now we should have two separate chains, up until the shared suffix
        after_unique_middle = {}
        for word in *words
          char_start, char_end = #base_prefix + 1, #word - #base_suffix

          current_state = last_shared_state
          for i = char_start, char_end
            char = word\sub i, i
            assert.is.not.Nil current_state\step_if_valid char
            current_state = current_state\step_transition char
            assert.are.equal 1, #current_state.sorted_keys

            -- Keep track of the state that follows the word-unique portion,
            -- for later comparison
            if i == char_end
              after_unique_middle[#after_unique_middle + 1] = current_state

        -- Confirm that the following state of each chain is the same
        for i = 2, #after_unique_middle
          assert.are.equal after_unique_middle[1], after_unique_middle[i]
        assert.is.True current_state.is_confluence

        -- Now check that the suffix is shared
        current_state = after_unique_middle[1]
        for i = 1, #base_suffix
          char = base_suffix\sub i, i

          -- Each should only have a single child
          if i != 1
            assert.are.equal 1, #current_state.sorted_keys
          assert.is.not.Nil current_state\step_if_valid char
          current_state = current_state\step_transition char

        assert.is.True current_state.final
      -- }}}

      it "tests that words can be added in separate calls with identical results", ->
        first_words = { base_word }
        last_words = { later_word }
        all_words = { base_word, later_word }
        split_call_mafsa = mafsa

        split_call_mafsa\add_sorted_words first_words
        split_call_mafsa\add_sorted_words last_words
        single_call_mafsa = Mafsa.new!
        single_call_mafsa\add_sorted_words all_words

        assert.is.True single_call_mafsa\is_equivalent_to split_call_mafsa

      it "tests that all (and only) the words added are in the subset of the initial state", ->
        sorted_words = { base_word, later_word, sub_word, prefix_shared, suffix_shared, both_shared }
        table.sort sorted_words

        mafsa\add_sorted_words sorted_words

        subset = mafsa\subset ""
        table.sort subset
        for i = 1, #sorted_words
          assert.are.equal sorted_words[i], subset[i]
        assert.are.equal #sorted_words, #subset
    -- }}}

    describe "add_word() tests:", -> -- {{{
      local mafsa, words

      before_each ->
        words = {"foobar", "zebra", "foo", "foonot", "notbar", "follar", "wollak"}
        mafsa = Mafsa.new!

      it "the length of the right language of the initial state does not decrease after each call", ->
        -- One of these two cases always happens:
        -- - A new word is a prefix of an existing one, in which case the right
        --   language of the starting state remains the same
        -- - A new word is not purely a prefix of an existing one, in which
        --   case the right language of the starting state gets larger
        previous_length = 0

        for word in *words
          mafsa\add_word word
          current_length = #(mafsa.initial_state\__get_right_language!)
          assert previous_length <= current_length, "NOT: #{previous_length} <= #{current_length}"
          previous_length = current_length
    -- }}}
