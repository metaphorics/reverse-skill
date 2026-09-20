---
name: go-rust-reverse
description: Reverse engineer stripped Go and Rust binaries. Identify runtime features, recover pclntab and module data with redress and GoReSym, analyze panic strings, and recover idiomatic code patterns from decompiled code.
---

# Go / Rust Binary Reverse Engineering

## ACTION REQUIRED（读完后立刻执行）

1. `NOW`: 读取 `../field-journal/precedent-reverse.md`
2. `NOW`: 确认样本为 Go/Rust 编译产物（`file`/字符串/运行时特征）
3. `NEXT`: GoReSym / redress / 相关插件是否可用（首次扫描用 `scripts/go-triage.ps1` / `scripts/go-triage.sh --bin <path>`）
4. `ACT`: 运行时识别 → 符号/元数据恢复 → 业务逻辑

## 适用场景

- 剥离符号的 Go 恶意软件/工具
- Rust 发行二进制、panic 字符串驱动分析
- 与通用 ida/ghidra 互补的语言专用方法

## 工作流

### Identify the runtime

```text
□ Run file, rabin2 -I, and strings for go.buildid / runtime.main (Go) or rust_begin_unwind (Rust)
□ The go-triage.sh / go-triage.ps1 scripts automate this scan with --bin <path>
```

### Go

```text
□ 识别 go.buildid、runtime 符号残留、pclntab
□ 先跑 `redress info <bin>`，再跑 `redress packages --std --vendor <bin>`；有方法集的结构体跑 `redress types struct --methods <bin>`
□ IDA/Ghidra 反编译时跑 `GoReSym -p -t -d <bin> > goresym.json` 并导入；r2 打开时跑 `redress r2` 做 r2pipe 投影
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
| redress（v1.2.85） | Go 包 / 类型 / 源码投影（自举） |
| GoReSym（v3.4.1） | Go 元数据 JSON，供 IDA/Ghidra 导入（自举） |
| IDA/Ghidra + Go/Rust 插件 | 反编译 |
| radare2（6.2.2） | 快速字符串；`redress r2` 管道目标 |
| strings / rabin2 | 分诊 |

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
