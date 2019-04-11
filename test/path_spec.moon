-- Manipulate the package path to include the local moonscript sources
path = require 'pl.path'
source_path = debug.getinfo(1).source\sub(2, -1) -- Relative path of currently-executing file
source_path = path.dirname(path.abspath source_path)
source_path = path.normpath("#{source_path}/../moon")
package.moonpath = "#{source_path}/?/init.moon;#{source_path}/?.moon;#{package.moonpath}"

describe "path module tests:", ->
  Path = require "earthshine.path"

  describe "class tests:", ->
    parse_test = (parse_fn, test_name, path, expected) -> it test_name, ->
      parsed = parse_fn path

      assert.are.same expected, parsed

    describe "parse_parent returns the logical parent of the path for", ->
      parent_test = (test_name, path, expected) -> parse_test Path\parse_parent, test_name, path, expected

      parent_test "an absolute path",             "/var/log/messages",  "/var/log"
      parent_test "a relative path",              "./var/log/messages", "./var/log"
      parent_test "an implicitly relative path",  "var/log/messages",   "./var/log"

      parent_test "a two-component absolute path",            "/var",   "/"
      parent_test "a two-component relative path",            "./var",  "."
      parent_test "a two-component implicitly relative path", "var",    "."
      parent_test "a two-component relative parent path",     "..",     "."

      -- NOTE: Asking for the parent of any root path is somewhat inane; these
      -- are primarily defined because they mean that the original path can be
      -- reconstructed from the parent and name.
      parent_test "a one-component absolute path",                  "/",  "/"
      parent_test "a one-component relative path",                  "./", "."
      parent_test "a one-component relative path, sans separator",  ".",  "."
      parent_test "a one-component implicitly relative path",       "",   "."

    describe "parse_name returns the last component in the path (root excluded) for", ->
      name_test = (test_name, path, expected) -> parse_test Path\parse_name, test_name, path, expected

      name_test "an absolute path",             "/var/log/messages",  "messages"
      name_test "a relative path",              "./var/log/messages", "messages"
      name_test "an implicitly relative path",  "var/log/messages",   "messages"

      name_test "a two-component absolute path",            "/var",   "var"
      name_test "a two-component relative path",            "./var",  "var"
      name_test "a two-component implicitly relative path", "var",    "var"
      name_test "a two-component relative parent path",     "..",     ".."

      name_test "a one-component absolute path",                  "/",  ""
      name_test "a one-component relative path",                  "./", ""
      name_test "a one-component relative path, sans separator",  ".",  ""
      name_test "a one-component implicitly relative path",       "",   ""

    pending "iterator tests"
