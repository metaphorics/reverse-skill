---
name: go-rust-reverse
<<<<<<< ours — scope `description: Use to reverse engineer Go and R...` in preamble `(preamble)` (S, confidence: medium)
// refused_by: statement_fold · collision: `description: Use to reverse engineer Go and Rust binaries with …`
description: Use for reverse engineering stripped Go and Rust binaries including runtime recognition, pclntab/moduel data recovery, panic strings, and idiomatic decompilation recovery.
=======
description: Reverse engineer Go and Rust binaries with symbols removed. Identify runtime features, recover pclntab and module data with redress and GoReSym, analyze panic strings, and recover language-specific code patterns from decompiled code.
>>>>>>> theirs — scope `description: Use to reverse engineer Go and R...`
---

# Go / Rust Binary Reverse Engineering

## ACTION REQUIRED（读完后立刻执行）

1. `NOW`: 读取 `../field-journal/precedent-reverse.md`
2. `NOW`: 确认样本为 Go/Rust 编译产物（`file`/字符串/运行时特征）
3. `NEXT`: GoReSym / 相关插件是否可用
4. `ACT`: 运行时识别 → 符号/元数据恢复 → 业务逻辑

## 适用场景

- 剥离符号的 Go 恶意软件/工具
- Rust 发行二进制、panic 字符串驱动分析
- 与通用 ida/ghidra 互补的语言专用方法

<<<<<<< ours — heading `ACTION REQUIRED (Execute immediately after reading)` (S+F, confidence: low)
// refused_by: modify_delete_guard · collision: none (no common ancestor text)
=======
## ACTION REQUIRED (Execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md`
2. `NOW`: Confirm that the sample was compiled from Go or Rust (use `file`, strings, and runtime features)
3. `NEXT`: Check if redress, GoReSym, and related plugins are available (run `scripts/go-triage.ps1` / `scripts/go-triage.sh --bin <path>` for the first scan)
4. `ACT`: Identify the runtime → recover symbols/metadata → analyze application logic

>>>>>>> theirs — heading `ACTION REQUIRED (Execute immediately after reading)` (S+F, confidence: low)
## 工作流

### Identify the runtime

```text
□ Run file, rabin2 -I, and strings for go.buildid / runtime.main (Go) or rust_begin_unwind (Rust)
□ The go-triage.sh / go-triage.ps1 scripts automate this scan with --bin <path>
```

### Go

```text
□ 识别 go.buildid、runtime 符号残留、pclntab
□ GoReSym / redress / IDA Go 插件恢复函数名
□ 注意 interface、slice、string 结构在反编译中的形态
□ 网络/加密库路径：crypto/* net/http
```

### Rust

```text
□ panic 字符串、rust_begin_unwind、crate 路径暗示
□ 范型实例化导致的代码膨胀；先定位字符串 xref
□ 异步/tokio 状态机需结合交叉引用
```

### 动态

```text
□ 仍可用 Frida；注意 Go 栈与调度
□ 优先日志与配置字符串驱动断点
```

## 工具链

| 工具 | 用途 |
|------|------|
| GoReSym | Go 元数据 |
| IDA/Ghidra + Go/Rust 插件 | 反编译 |
| radare2 | 快速字符串 |
| strings / rabin2 | 分诊 |

<<<<<<< ours — heading `Go` (S+F, confidence: low)
// refused_by: modify_delete_guard · collision: none (no common ancestor text)
=======
### Go

```text
□ Run redress info <bin>, then redress packages --std --vendor <bin>
□ Run redress types struct --methods <bin> for structs with method sets
□ When IDA/Ghidra is the decompiler, run GoReSym -p -t -d <bin> > goresym.json and import it
□ When r2 is open, run redress r2 for r2pipe projection
□ Examine interface, slice, and string structures in decompiled code
□ Examine network/cryptographic library paths: crypto/* net/http
```

>>>>>>> theirs — heading `Go` (S+F, confidence: low)
<<<<<<< ours — heading `Dynamic Analysis` (T+F, confidence: medium)
// refused_by: modify_delete_guard · collision: none (no common ancestor text)
=======
### Dynamic Analysis

```text
□ Frida still applies; examine the Go stack and scheduling
□ First use log and configuration strings to select breakpoints
```

>>>>>>> theirs — heading `Dynamic Analysis` (T+F, confidence: medium)
<<<<<<< ours — heading `Tools` (T+F, confidence: medium)
// refused_by: modify_delete_guard · collision: none (no common ancestor text)
=======
## Tools

| Tool | Version | License | Use |
|------|---------|---------|-----|
| redress | v1.2.85 | AGPL-3.0 | Recover Go packages, types, source projection; auto-install |
| GoReSym | v3.4.1 | MIT | Recover Go metadata JSON for IDA/Ghidra; auto-install |
| IDA/Ghidra + Go/Rust plugins | as installed | — | Decompile code |
| radare2 | 6.2.2 | — | Find strings quickly; redress r2pipe target |
| strings / rabin2 | as installed | — | Make an initial assessment |

>>>>>>> theirs — heading `Tools` (T+F, confidence: medium)
## 参考

- `references/go-rust-notes.md`
- `../reverse-engineering/go-reverse.md` `../ida-reverse/` `../ghidra-reverse/`
- seed: `field-journal/seed-002_go-malware-stripped.md`

## 路由上下文

**上游**: MASTER R33  
**下游**: 恶意样本流程 `malware-analysis`；通用 RE `reverse-engineering`

## 任务完成自检

- [ ] 是否恢复关键函数名或等价映射？
- [ ] 是否标注语言运行时证据？
- [ ] Checklist？
// weave: run 'weave explain skills/go-rust-reverse/SKILL.md' for per-hunk detail, 'weave check' to verify your resolution
