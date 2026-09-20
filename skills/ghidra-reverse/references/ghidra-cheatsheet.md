# Ghidra Quick Reference

| Action | Shortcut / Location (default) |
|------|----------------------|
| Decompile | Double-click the function → Decompile |
| Rename | L |
| Add comment | ; |
| Xrefs | Right-click → References |
| Search strings | Search → For Strings |
| Scripts | Window → Script Manager |

Headless documentation: Ghidra docs → analyzeHeadless README.



## PyGhidra

```bash


# Launch a Python 3 script with the bundled interpreter (Ghidra 12.1.3, JDK 21)
support/pyghidraRun script.py
```

- Install the interpreter wheel from `Ghidra/Features/PyGhidra/pypkg/dist`
  inside the local Ghidra install, never from PyPI.
- Jython is legacy; new automation uses PyGhidra only.
