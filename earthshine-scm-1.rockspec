-- TODO This is not a functional rockspec; I'll set one up at some point
package = "earthshine"
version = "scm-1"
source = {
  url = "git://github.com/Shados/earthshine",
  branch = "master",
}
description = {
  summary = "A library of random things I had a need for",
  homepage = "https://github.com/Shados/earthshine",
  license = "MIT",
}
dependencies = {
  "lua == 5.1",
}
build_dependencies = {
  "moonscript >= 0.5.0",
}
build = {
  type = "make",

  install_variables = {
    LUA_LIBDIR="$(LUADIR)",
    PREFIX="$(PREFIX)",
  },

  copy_directories = {
    "test",
  },
}
rockspec_format = "3.0"
