# Earthshine To-Dos

## MADSA
Performance optimizations from the papers:
- "Pre-sorting": Mentioned using a bucket sort to allocate a "class number" to
  each state, and then only compare states within the same class.
  I've somewhat already done an equivalent optimization by registering states
  in a multi-level index keyed by the same properties they use for their bucket
  sort. This did improve runtime performance significantly, and the increase in
  memory usage was modest: for 5k random English words, ~70s/4200KiB ->
  16s/4650KiB.
  It is not immediately clear to me that the bucket sort approach would be
  helpful in my usage, given I am focusing entirely on
  incrementally-constructed automata, whereas they were looking at
  incrementally minimizing existing automata.
- "Remembering only re-entrant states on stack": Irrelevant in my case, as I am
  working with acyclic automata, so I don't need the extra stack book-keeping
  to detect cycles in the first place.
- "Full memoization": This is likely to be the big gain, at sharp cost in
  memory usage... especially if I want cache invalidation to be O(1).

Further performance optimization ideas to explore, *after* implementing the
ones from the papers I've already looked at:
- Potentially, use bloom filters of the state classes to do quick intersection;
  false positives are possible, so on positives I'll still have to generate
  real intersections, but it should speed things up given that *most* items
  will be definitely-excluded first
    - You can't remove things from bloom filters, so at some point we'd have to
      regenerate them from scratch to maintain efficiency
