# AI-Assisted Reverse Engineering

> LLM-Driven Decompilation / Multi-Agent Validation / Neural Semantic Recovery
> Biggest Shift in 2025-2026

## Core Tools and Models

### LLM4Decompile
- First open-source framework to use LLMs for binary-to-source decompilation
- Supports x86/ARM/MIPS multi-architecture
- Input: Assembly Code → Output: C Source Code
- Training data: Million-scale source-assembly pairs

### Decaf (2026)
- **Compiler Feedback Validation**: Send LLM-generated source code to compilation, then compare it with the original binary
- Result: Decompilation rate 26% → 83.9% (ExeBench Real -O2)
- Key insight: The feedback loop works better than a larger model

### Constraint-Guided Multi-Agent (2026)
- Three-level validation pipeline:
  1. Syntax correctness (parsing)
  2. Compilability (GCC)
  3. Behavioral equivalence (LLM-generated test cases)
- 84-97% rerun rate, at only $0.03-0.05 each

### REMEND (2026)
- Focus: Extract mathematical equations from binaries
- 89.8-92.4% accuracy (across 3 ISA × 3 optimization levels × 2 languages)
- Speed: 0.132s/function, with only 12M parameters

### Glaurung
- Open-source Ghidra alternative with a Rust core and Python bindings
- **AI-Native Architecture**: Embed an LLM Agent in each analysis layer
- Evidence artifacts: plain/rich/JSON/JSONL output in multiple formats for LLM consumption
- Supports: ELF/PE/Mach-O, x86/ARM/RISC-V, IOC detection, entropy analysis

## Workflow: AI-Enhanced Binary Analysis

### 1. LLM-Assisted Rapid Reconnaissance

```text
□ Extract strings → LLM semantic classification (URL/keys/paths/protocols)
□ Analyze the import table → LLM infers functionality (encryption = OpenSSL? networking = libcurl?)
□ Disassembly snippets → LLM identifies patterns (cryptographic algorithms, anti-debugging, virtual machine detection)
□ Error messages → LLM infers context ("Invalid license" → location of authorization logic)
```

### 2. Neural Decompilation

```bash
# LLM4Decompile
python llm4decompile.py --binary target.so --arch arm64 --output target.c

# Verify results (recompile + compare)
gcc -O2 -o target_recompiled target.c -fPIC -shared
# → Verify output behavior equivalence
```

### 3. Multi-Agent Validation

```text
Agent 1 (syntax): Check whether the generated C code can parse
  ↓ Failure → Send the error message to the LLM and retry
Agent 2 (compilation): GCC compile → Check warnings/errors
  ↓ Failure → Send the compilation error to the LLM
Agent 3 (behavior): LLM generates input → Run the original and recompiled versions → Compare outputs
  ↓ Inconsistency → Send the difference to the LLM → Iterate and correct
```

### 4. LLM-Assisted Static Analysis

```text
□ Function renaming: Input decompiled pseudocode → LLM suggests semantic names
□ Type recovery: Analyze context → LLM infers struct/class definitions
□ Algorithm identification: Assembly snippets → LLM identifies cryptographic algorithms (AES/TEA/RC4/custom)
□ Protocol reverse engineering: Network packet sequence → LLM infers protocol format
□ Comment generation: Decompiled code → LLM generates Chinese/English comments
```

### 5. macOS/iOS Private Framework Reverse Engineering (MOTIF)

```text
Problem: macOS private frameworks have no documentation, and type information is missing
Solution: LLM analyzes usage patterns → Infers method signatures and parameter types
Result: ObjC signature recovery 15% → 86% (vs static analysis)
```

## LLM Prompt Template

### Function Semantics Analysis

```
You are a reverse engineering expert. Analyze this decompiled function:

[Pseudocode]

1. What does this function do? (one sentence)
2. Suggest a meaningful function name.
3. What are the input parameters and their likely types?
4. What is the return value?
5. What external APIs/functions does it depend on?
6. Any security-relevant operations (crypto, auth, network, file I/O)?
```

### Algorithm Identification

```
Analyze this assembly/disassembly for cryptographic operations:

[Assembly code]

1. Is this a known cryptographic algorithm? (AES/DES/RC4/TEA/ChaCha20/custom?)
2. Identify the key schedule and round structure.
3. What is the key size?
4. Are there any hardcoded constants that identify the algorithm?
```

### Protocol Format Inference

```
Given this network packet sequence, infer the protocol structure:

[hex dump]

1. Identify magic bytes and length fields.
2. Propose a struct definition for the packet header.
3. What field(s) appear to be checksums/CRCs?
4. Is this a known protocol or custom?
```

## Tool Selection

| Scenario | Recommended Tool | Cost |
|------|---------|------|
| Rapid Decompilation | LLM4Decompile | Free (local GPU) |
| High-Precision Decompilation | Constraint-Guided Multi-Agent | ~$0.05/binary |
| Mathematical Function Extraction | REMEND | Free |
| Cross-Platform RE | Glaurung (Rust) | Free and open source |
| LLM Interaction | Claude API / GPT-4 / DeepSeek | ~$0.01-0.10/time |

## Limitations

- **Complex Control Flow**: Virtualized and obfuscated code remains difficult (control-flow flattening, VMProtect)
- **Indirect Calls**: Virtual function tables and function pointers are difficult to recover
- **Inline Functions**: Function boundaries become unclear after compiler inlining
- **Floating-Point Operations**: Semantic recovery for vector instructions needs improvement
- **Context Window**: Large functions (>1000 lines) exceed LLM context limits

Source: Decaf (2026), REMEND (2026), Constraint-Guided Multi-Agent Decompilation (2026), LLM4Decompile, Glaurung
