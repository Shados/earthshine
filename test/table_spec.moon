-- Manipulate the package path to include the local moonscript sources
path = require 'pl.path'
source_path = debug.getinfo(1).source\sub(2, -1) -- Relative path of currently-executing file
source_path = path.dirname(path.abspath source_path)
source_path = path.normpath("#{source_path}/../moon") -- Up a directory and into moon/
package.moonpath = "#{source_path}/?.moon;#{package.moonpath}"

inspect = require 'inspect'

local *

describe "Earthshine table tests:", () ->

  describe "sorted_iterator() tests:", () ->
    import sorted_iterator from require "earthshine.table"

    local test_tbl
    before_each () ->
      test_tbl =
        c: "third"
        z: "last"
        r: "late"

    it "tests that nothing is run for an empty table", () ->
      empty_tbl = {}
      empty_key_list = {}

      i = 0
      for key, val in sorted_iterator empty_tbl, empty_key_list
        i += 1

      assert.are.equal i, 0


  describe "max() tests:", () ->
    import max from require "earthshine.table"

    local test_tbl
    before_each () ->
      test_tbl = {5, 8, 19, 3, 47, 6, 9, 9, 411, 12}


    it "returns nil if the table is empty", () ->
      empty_tbl = {}

      max_val, max_key = max empty_tbl

      assert.is.Nil max_val
      assert.is.Nil max_key

    it "returns a value that is greater than or equal to all values in the table", () ->
      max_val, _max_key = max test_tbl

      for _key, val in pairs test_tbl
        assert max_val >= val

    it "returns a (value, key) pair such that the key indexes the value in the table", () ->
      max_val, max_key = max test_tbl

      assert.are.equal max_val, test_tbl[max_key]

    it "does not modify the table", () ->
      nil

    it "works with a custom comparator", () ->
      most_as = "baaaaa"
      a_tbl = {"a", "bbbbbbbbbbbbb", most_as, "aaba", "aaaa", "foobar"}
      char_count = (str, char) ->
        count = 0
        for _char in str\gmatch char
          count += 1
        return count
      comparator = (a, b) ->
        return (char_count a, "a") < (char_count b, "a")

      max_val, max_key = max a_tbl
      custom_max_val, custom_max_key = max a_tbl, comparator

      assert.are.same most_as, custom_max_val
      assert.are.not.same max_val, custom_max_val
      assert.are.not.same max_key, custom_max_key
