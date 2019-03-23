# Earthshine To-Dos

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
