# Earthshine To-Dos

## New Module Possibilities
Could probably cover the gamut of typical data structures provided by language
stdlibs, if I wanted to:
- Lists
- Sequences (lists with nilable values)
- Sets
- Immutable versions of the various collection types
- Additions to the string metatable to handle UTF-8 strings, including
  recognition of and iteration by grapheme clusters
- Types for mapping bitfields, byte arrays, and otherwise managing binaries
    - Again, if we had real macro support in Moonscript, could probably emulate
      Erlang's excellent binary destructuring
- Datetimes, although these are kind of a PITA
- Rich File and Path objects

Utility functions and algorithms:
- Higher-level functions
- All the sorts
- De/serialization routines; typically you want completely different properties
  for file vs. wire de/serialization

More abilitious ideas:
- In-memory POSIX-compatible filesystem, for reproducibly mocking
  filesystem-interacting code in a way that is not dependent on *any* actual
  filesystem or files
- Clean native interface to sqlite, to provide a near-native in-memory database
- Argument parsing? There's plenty of options around, of course, but every
  argument parsing module I have ever seen or used, in any language, is awkward
  as hell. Maybe it is just intrinsic to the deceptive complexity of the
  problem domain, but maybe the model just needs re-thinking
- If we get native Moonscript macros, a log library that "lazily" constructs
  the log messages, so that they aren't built if the log message isn't going to
  be printed due to the current log level not being high enough
- A library implementing most aspects of POSIX shell behaviour, including real
  pipes

## MADFA
Performance optimizations from the papers:
- "Pre-sorting": Mentioned using a bucket sort to allocate a "class number" to
  each state, and then only compare states within the same class.
  I've somewhat already done an equivalent optimization by registering states
  in a multi-level index keyed by the same properties they use for their bucket
  sort. This did improve runtime performance significantly, and the increase in
  memory usage was modest: for 5k random English words, ~70s/4200KiB ->
  16s/4650KiB.
  It does not appear that the bucket sort approach would be helpful in my
  usage, given I am focusing entirely on incrementally-constructed automata,
  whereas they were looking at incrementally minimizing existing automata.
- "Remembering only re-entrant states on stack": Irrelevant in my case, as I am
  working with acyclic automata, so I don't need the extra stack book-keeping
  to detect cycles in the first place.
- "Full memoization": Tested a somewhat naive implementation of this...
  decidedly worse. Dramatically increases memory usage, as expected, and the
  initialization overhead of the memoization structures is high enough to slow
  down the algorithm as a whole.
  After some though, less naive implementations wont be beneficial, either,
  again because I am minimizing as I incrementally construct the automata,
  which limits the number of `equiv` calls dramatically, and also means that
  I'll be calling it on state-pairs that have not previously been compared.
