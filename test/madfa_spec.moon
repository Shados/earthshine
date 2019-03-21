-- Manipulate the package path
path = require 'pl.path'
source_path = debug.getinfo(1).source\sub(2, -1) -- Relative path of currently-executing file
source_path = path.dirname(path.abspath source_path)
source_path = path.normpath("#{source_path}/../moon/earthshine/madfa")
package.moonpath = "#{source_path}/?.moon;#{package.moonpath}"
inspect = require 'inspect'

earthshine_table = require 'earthshine.table'
clone_table = earthshine_table.clone
require 'earthshine.string'

local *

describe "MADFA package tests:", ->
  MADFA = require 'earthshine.madfa'
  import State, Register from MADFA

  describe "madfa tests:", ->
    describe "_step_transition() tests:", -> -- {{{
      local madfa, state, next_state, label
      before_each ->
        madfa = MADFA.new!
        state = madfa.initial_state
        next_state = madfa\_new_state!
        label = "a"

      it "makes the target state reachable from the source state under the given label", ->
        assert.is.Nil madfa\_step_transition state, label

        madfa\_add_transition state, label, next_state

        assert.are.equals (madfa\_step_transition state, label), next_state

      it "increments the count of sorted transition labels", ->
        label_count = #state.sorted_keys

        madfa\_add_transition state, label, next_state

        assert.are.equals label_count + 1, #state.sorted_keys

      it "has a sorted label list entry corresponding to the correct label", ->
        for existing_label in *state.sorted_keys
          assert.are.not.same label, existing_label

        madfa\_add_transition state, label, next_state

        seen_label = false
        for current_label in *state.sorted_keys
          if current_label == label
            seen_label = true
        assert seen_label

      it "increases the incoming transition count on the target state", ->
        old_count = next_state.incoming

        madfa\_add_transition state, label, next_state

        assert.are.equal old_count + 1, next_state.incoming
    -- }}}

    describe "_step_multiple() tests:", -> -- {{{
      labels = { "a", "z", "c" }
      local madfa, state, next_states

      before_each ->
        madfa = MADFA.new!
        state = madfa.initial_state
        next_states = {}

      _add_transitions_with_fn = (fn) ->
        for i, label in ipairs labels
          next_states[i] = madfa\_new_state!
          madfa\_add_transition state, label, next_states[i]
          fn!

      _add_transitions = -> _add_transitions_with_fn -> nil

      assert_lexicographically_sorted = (tbl) ->
        key, val = next tbl, nil
        previous_val = nil
        while key != nil
          if previous_val
            assert val > previous_val
          previous_val = val
          key, val = next tbl, key

      it "preserves the lexicographical sorting of the labels after each addition", ->
        _add_transitions_with_fn, ->
          assert_lexicographically_sorted state.sorted_keys
    -- }}}

    describe "_clone_state() tests:", -> -- {{{
      local madfa, state
      setup ->
        madfa = MADFA.new!
        parent_state = madfa\_new_state!
        state = madfa\_new_state!
        with madfa
          \_add_transition state, "a", \_new_state!
          \_add_transition state, "z", \_new_state!
          \_add_transition state, "d", \_new_state!
          \_add_transition parent_state, "a", state

      it "has the same .transitions and .sorted_keys as the original", ->
        cloned_state = madfa\_clone_state state

        assert.are.equals #cloned_state.transitions, #state.transitions
        assert.are.equals #cloned_state.sorted_keys, #state.sorted_keys
        for i, label in pairs state.sorted_keys
          assert.are.equals label, cloned_state.sorted_keys[i]
          assert.are.equals state.transitions[label], cloned_state.transitions[label]

      it "has the same final value as the original", ->
        cloned_state = madfa\_clone_state state

        assert.are.equals state.final, cloned_state.final

      it "has no incoming transitions", ->
        cloned_state = madfa\_clone_state state

        assert.are.equals 0, cloned_state.incoming

      it "is not the same object as the original", ->
        cloned_state = madfa\_clone_state state

        assert.are.not.equal state, cloned_state

      it "increases the incoming transition count on all pointed-to transitions", ->
        old_counts = {}
        for label, transition in madfa\_iterate_transitions state
          old_counts[label] = transition.incoming

        cloned_state = madfa\_clone_state state

        for label, transition in madfa\_iterate_transitions state
          assert.are.equal old_counts[label] + 1 , transition.incoming
    -- }}}

    describe "_delete_state() tests:", -> -- {{{

      it "decrements the incoming transition count on all child states", -> 
        nil
    -- }}}

    describe "_register_state() tests:", -> -- {{{
    -- }}}

    describe "add_words() tests:", -> -- {{{
      base_word = "foobar"
      later_word = "zebra"
      sub_word = "foo"
      prefix_shared = "foonot"
      suffix_shared = "notbar"
      -- both_shared shares prefix and suffix with existing_string
      both_shared = "follar"
      local madfa

      before_each ->
        madfa = MADFA.new!

      it "prefixes are shared between added words", -> -- {{{
        words = { prefix_shared, base_word }

        madfa\add_words words
        base_prefix = string.lcp words

        -- For the base_prefix's states, there should each be only one child,
        -- up to the last one
        current_state = madfa.initial_state
        for char in (base_prefix\sub 1, -2)\chars!
          assert.are.equal 1, #current_state.sorted_keys
          assert.are.equal char, current_state.sorted_keys[1]
          current_state = madfa\_step_transition current_state, char

        -- The last state in the base_prefix should instead have 2 children
        last_shared_state = madfa\_step_multiple madfa.initial_state, base_prefix
        assert.are.equal 2, #last_shared_state.sorted_keys

        -- After that, we should have two chains of states, equal to the two suffixes
        for word in *words
          suffix = word\sub #base_prefix + 1, -1
          current_state = last_shared_state
          for char in suffix\chars!
            assert.is.not.Nil madfa\_step_transition current_state, char
            current_state = madfa\_step_transition current_state, char
          assert.is.True current_state.final
      -- }}}

      it "the suffixes are shared between added words", -> -- {{{
        words = { suffix_shared, base_word }

        madfa\add_words words
        base_suffix = string.lcs words

        -- We start with the initial state breaking out into two separate
        -- chains of states, up to the shared suffix
        local current_state
        after_prefix = {}
        for word in *words
          prefix = word\sub 1, #word - #base_suffix
          current_state = madfa.initial_state
          -- Initial state has two children, subsequent prefix chains only have
          -- 1 child
          assert.are.equal 2, #current_state.sorted_keys

          -- for char in prefix\chars!
          for i = 1, #prefix
            char = prefix\sub i, i
            assert.is.not.Nil madfa\_step_transition current_state, char
            current_state = madfa\_step_transition current_state, char
            assert.are.equal 1, #current_state.sorted_keys

            -- Keep track of the state that follows the prefix for later
            -- comparison
            if i == #prefix
              after_prefix[#after_prefix + 1] = current_state

        -- Confirm that the following state of each chain is the same
        assert.are.equal current_state, after_prefix[1], after_prefix[2]
        for i = 1, #after_prefix
          assert.are.equal current_state, after_prefix[i]
        assert.is.True current_state.incoming >= 2

        -- Now check that the suffix is shared
        for i = 1, #base_suffix
          char = base_suffix\sub i, i

          -- Each should only have a single child
          if i != 1
            assert.are.equal 1, #current_state.sorted_keys
          assert.is.not.Nil madfa\_step_transition current_state, char
          current_state = madfa\_step_transition current_state, char

        assert.is.True current_state.final
      -- }}}

      it "both prefix and suffix can be shared between added words", -> -- {{{
        words = { base_word, both_shared }

        madfa\add_words words
        base_prefix = string.lcp words
        base_suffix = string.lcs words

        -- Confirm that each state in the base_prefix path has only one child,
        -- up to the last one
        current_state = madfa.initial_state
        for char in (base_prefix\sub 1, -2)\chars!
          assert.are.equal 1, #current_state.sorted_keys
          assert.are.equal char, current_state.sorted_keys[1]
          current_state = madfa\_step_transition current_state, char

        -- The last state in the base_prefix should instead have 2 children
        last_shared_state = madfa\_step_multiple madfa.initial_state, base_prefix
        assert.are.equal 2, #last_shared_state.sorted_keys

        -- Now we should have two separate chains, up until the shared suffix
        after_unique_middle = {}
        for word in *words
          char_start, char_end = #base_prefix + 1, #word - #base_suffix

          current_state = last_shared_state
          for i = char_start, char_end
            char = word\sub i, i
            assert.is.not.Nil madfa\_step_transition current_state, char
            current_state = madfa\_step_transition current_state, char
            assert.are.equal 1, #current_state.sorted_keys

            -- Keep track of the state that follows the word-unique portion,
            -- for later comparison
            if i == char_end
              after_unique_middle[#after_unique_middle + 1] = current_state

        -- Confirm that the following state of each chain is the same
        for i = 2, #after_unique_middle
          assert.are.equal after_unique_middle[1], after_unique_middle[i]
        assert.is.True current_state.incoming >= 2

        -- Now check that the suffix is shared
        current_state = after_unique_middle[1]
        for i = 1, #base_suffix
          char = base_suffix\sub i, i

          -- Each should only have a single child
          if i != 1
            assert.are.equal 1, #current_state.sorted_keys
          assert.is.not.Nil madfa\_step_transition current_state, char
          current_state = madfa\_step_transition current_state, char

        assert.is.True current_state.final
      -- }}}

      it "words can be added in separate calls with identical results", ->
        first_words = { base_word }
        last_words = { later_word }
        all_words = { base_word, later_word }
        split_call_madfa = madfa

        split_call_madfa\add_words first_words
        split_call_madfa\add_words last_words
        single_call_madfa = MADFA.new!
        assert.is.not.True single_call_madfa\is_equivalent_to split_call_madfa
        single_call_madfa\add_words all_words

        assert.is.True single_call_madfa\is_equivalent_to split_call_madfa

      it "all (and only) the words added are in the subset of the initial state", ->
        words = { base_word, later_word, sub_word, prefix_shared, suffix_shared, both_shared }

        madfa\add_words words

        subset = madfa\subset ""
        table.sort words
        assert.are.equal #subset, #words
        for i = 1, #words
          assert.are.equal words[i], subset[i]
        assert.are.equal #words, #subset

      it "tests against 1,000 random words", ->
        words = {}
        for word in io.lines "test/data/1000-words.txt"
          words[#words + 1] = word

        madfa\add_words words

        subset = madfa\subset ""
        table.sort words
        assert.are.equal #subset, #words
        for i = 1, #words
          assert.are.equal words[i], subset[i]
    -- }}}

    describe "add_word() tests:", -> -- {{{
      local madfa, words

      before_each ->
        words = {"foobar", "zebra", "foo", "foonot", "notbar", "follar", "wollak"}
        madfa = MADFA.new!

      it "the length of the right language of the initial state does not decrease after each call", ->
        -- One of these two cases always happens:
        -- - A new word is a prefix of an existing one, in which case the right
        --   language of the starting state remains the same
        -- - A new word is not purely a prefix of an existing one, in which
        --   case the right language of the starting state gets larger
        previous_length = 0

        for word in *words
          madfa\add_word word
          current_length = #(madfa\subset "")
          assert previous_length <= current_length, "NOT: #{previous_length} <= #{current_length}"
          previous_length = current_length
    -- }}}
