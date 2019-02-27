## MAFSA

Hashing:
   Similarly, hashing can be used to provide an efficient method of determining
   the state equivalence classes.

- Actually implementing this would complicate the code, because I believe it
  would mean that updating of the state hashes could no longer be confined to
  the states themselves. This is because you would potentially need to update
  the hash of a state whenever any of its descendents change.
- I think this is still possible to do, because the way states are modified is
  already bottom-up, so you could update the hashes as you go, it's just a bit
  more brittle.
- As such, I think this is best left as a performance optimization for
  **after** I've already got a full, robust test suite.
- I should also investigate at the same time the work required to absolutely
  minimize the number of hash updates.
- Once this is done, I should re-implement the Register class to work using a
  shadow table on the hash of the states.

### Register
- Add a boolean to toggle optimized behaviour for sorted mafsa:
    - If on, then instead of comparing right languages, compare table
      references directly
    - A finished-sorted mafsa should disable this again? Or actually, only
      disable it when adding via non-sorted words -- this way we can do cheap
      equivalence comparisons between sorted mafsas, if that is ever wanted

