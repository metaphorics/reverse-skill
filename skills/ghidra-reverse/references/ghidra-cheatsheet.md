# Ghidra 速查

| 动作 | 快捷键 / 位置（默认） |
|------|----------------------|
| 反编译 | 双击函数 → Decompile |
| 重命名 | L |
| 添加注释 | ; |
| Xrefs | 右键 → References |
| 搜索字符串 | Search → For Strings |
| 脚本 | Window → Script Manager |

Headless 文档：Ghidra docs → analyzeHeadless README。

<<<<<<< ours — heading `Ghidra Quick Reference` (S+F, confidence: low)
// refused_by: modify_delete_guard · collision: none (no common ancestor text)
=======
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

>>>>>>> theirs — heading `Ghidra Quick Reference` (S+F, confidence: low)

## PyGhidra

```bash

# Launch a Python 3 script with the bundled interpreter (Ghidra 12.1.3, JDK 21)
support/pyghidraRun script.py
```

- Install the interpreter wheel from `Ghidra/Features/PyGhidra/pypkg/dist`
  inside the local Ghidra install, never from PyPI.
- Jython is legacy; new automation uses PyGhidra only.
// weave: run 'weave explain skills/ghidra-reverse/references/ghidra-cheatsheet.md' for per-hunk detail, 'weave check' to verify your resolution
