---
name: ghidra-reverse
description: Use for free/open reverse engineering with Ghidra (headless or GUI), including decompile, cross-refs, and optional Ghidra MCP workflows when IDA is unavailable.
---

# Ghidra Reverse Engineering

## ACTION REQUIRED（读完后立刻执行）

1. `NOW`: 读取 `../field-journal/precedent-reverse.md`
2. `NOW`: 确认需要 **Ghidra**（无 IDA / 偏好开源 / 批量 headless）
3. `NEXT`: 读 `../tool-index.md` 查 ghidra / ghidra-mcp 路径
4. `NEXT`: 缺工具 → bootstrap `ghidra-mcp`（若 manifest 支持）或按手动步骤装 Ghidra
5. `ACT`: 导入样本 → 自动分析 → 导出关键函数反编译

## 适用场景

- 无 IDA 许可证时的主逆向入口
- 批量 headless 分析 / CI 中反编译
- Ghidra 脚本（Java/Python Jython/PyGhidra）自动化
- 与 `binary-diff` / `patch-diff-exploit` 的 ghidriff 联动

## 与 IDA 分工

| 需求 | 优先 |
|------|------|
| 已有 IDA MCP 深挖 | `ida-reverse/` |
| 开源 / 批量 / 教学 | **本 skill** |
| 仅 CLI 快速侦察 | `radare2/` |

<<<<<<< ours — heading `Applicable Scenarios` (T+F, confidence: medium)
// refused_by: modify_delete_guard · collision: none (no common ancestor text)
=======
## Applicable Scenarios

- Main reverse engineering entry point when no IDA license is available
- Batch headless analysis / decompilation in CI
- Automation with PyGhidra scripts (Python 3; Jython is legacy, do not start new scripts on it)
- Integration with ghidriff from `binary-diff` / `patch-diff-exploit`

>>>>>>> theirs — heading `Applicable Scenarios` (T+F, confidence: medium)
## 工作流

### 1. 项目与自动分析

```text
□ 新建 Project → Import 文件 → Analyze（默认分析器）
□ 记录语言/编译器识别结果与基址
□ 标记入口、导出表、字符串 xref
```

### 2. 关键函数

```text
□ 从字符串 / 导入 API 反查
□ Decompile 窗口还原算法
□ 重命名函数/变量；写 Plate comment
□ 需要动态时交接 Frida/GDB（reverse-engineering 动态章）
```

### 3. Headless（批量）

```bash
# 示例：analyzeHeadless 路径因安装而异，MUST 从 tool-index 取
analyzeHeadless /path/to/project Proj -import sample.bin -postScript ExportDecomp.py
```

### 4. MCP（若已配置）

```text
□ 确认 ghidra MCP 端口（常见 8765，以 tool-index 为准）
□ 用 MCP 工具拉反编译 / xrefs，禁止猜端口
```

## 工具链

| 工具 | 用途 | 自举 |
|------|------|------|
| Ghidra | 反编译主工具 | 手动 release / 包管理器 |
| ghidra-mcp | AI 桥 | bootstrap 能力名 `ghidra-mcp` |
| ghidriff | 补丁差分 | 见 `patch-diff-exploit` |

<<<<<<< ours — heading `4. MCP (If Configured)` (T+F, confidence: medium)
// refused_by: modify_delete_guard · collision: none (no common ancestor text)
=======
### 4. MCP (If Configured)

```text
□ Confirm the ghidra MCP port from tool-index; do not assume a default port
□ Use MCP tools to retrieve decompilation / xrefs; do not guess the port
```

>>>>>>> theirs — heading `4. MCP (If Configured)` (T+F, confidence: medium)
<<<<<<< ours — heading `Toolchain` (T+F, confidence: medium)
// refused_by: modify_delete_guard · collision: none (no common ancestor text)
=======
## Toolchain

| Tool | Purpose | Bootstrap |
|------|------|------|
| Ghidra 12.1.3 (current PUBLIC; requires 64-bit JDK 21) | Main decompilation tool | Manual release / package manager |
| PyGhidra (bundled with Ghidra) | Python 3 automation via support/pyghidraRun | Ships under Ghidra/Features/PyGhidra; install the wheel from pypkg/dist, never PyPI |
| ghidra-mcp | AI bridge | bootstrap capability name `ghidra-mcp` |
| ghidriff | patch diff | See `patch-diff-exploit` |

>>>>>>> theirs — heading `Toolchain` (T+F, confidence: medium)
## 参考

- `references/ghidra-cheatsheet.md`
- `../ida-reverse/` `../radare2/` `../binary-diff/`

## 路由上下文

**上游**: MASTER R22  
**下游**: 动态验证 → Frida/GDB；利用 → `pwn-chain`  
**同级**: `ida-reverse`（商业深挖）

## 任务完成自检

- [ ] 是否基于真实 Ghidra/tool-index 路径？
- [ ] 是否标注函数地址与重命名？
- [ ] 是否有可复现步骤？
- [ ] Checklist / journal？
// weave: run 'weave explain skills/ghidra-reverse/SKILL.md' for per-hunk detail, 'weave check' to verify your resolution
