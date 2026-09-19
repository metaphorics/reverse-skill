# Local reproduction

Confirm these items on the page before you return to Node:

- The actual entry function
- The call order
- The parameter sources
- The browser objects that the code needs
- Whether the code depends on time, random numbers, storage, cookie, UA, canvas, crypto

First, create a minimal reproduction. Then add the missing environment components one step at a time. Do not simulate the entire browser at once.