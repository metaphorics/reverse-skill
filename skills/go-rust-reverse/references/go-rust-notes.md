# Go/Rust Notes



# Go/Rust Tips

Go: First find `runtime.main` / `main.main`. Use pclntab for recovery.  
Rust: First collect `src/` path strings and `Option`/`Result` handling blocks.  
Both: Start with strings. Avoid getting lost in runtime libraries.



## Tool complement

`redress` (goretk, AGPL-3.0, v1.2.85, auto-install) projects packages, types,
and source layout out of a stripped Go binary. `GoReSym` (Mandiant, MIT,
v3.4.1, auto-install) emits function/type JSON for IDA/Ghidra import. The two
complement each other: redress for interactive projection and r2pipe, GoReSym
for decompiler import. Neither replaces the other.



## redress command list

Paraphrased from the upstream redress README (develop branch). All commands
take the target binary as the final argument. Multiple flags combine.

- `redress version <bin>` — print the redress version.
- `redress info <bin>` — summary: OS, architecture, compiler version and
  release date, build ID, GoRoot, main package root, and project/std/vendor
  package counts.
- `redress packages <bin>` — project packages only. Add `--unknown` for
  unclassified packages, `--std` for the standard library, `--vendor` for
  third-party packages, `--filepath` for on-disk source paths.
- `redress types interface <bin>` — recovered interfaces (`--std`/`--vendor`
  widen the filter).
- `redress types struct --methods <bin>` — recovered structs with method sets.
- `redress types all <bin>` — every recovered type.
- `redress source <bin>` — projected source tree layout.
- `redress gomod <bin>` — embedded go.mod information.
- `redress moduledata <bin>` — sections from the moduledata structure.
- `redress r2 <bin>` — r2pipe mode for an open radare2 session.



## GoReSym import flow

1. Run `GoReSym -p -t -d <bin> > goresym.json` (process, types, data tables).
2. Import the JSON into IDA (GoReSym plugin path) or Ghidra (GoReSym script
   path) before decompiling `main.main`.
3. Re-run per binary; the JSON is build-specific and never reused across builds.



## Go triage order

1. Confirm the runtime: `file`, `rabin2 -I`, and strings for `go.buildid` /
   `runtime.main`. The `go-triage.sh` / `go-triage.ps1` scripts automate this
   with `--bin <path>`.
2. Run `redress info <bin>`, then `redress packages --std --vendor <bin>`, then `redress types struct --methods <bin>`.
3. When IDA/Ghidra is the decompiler, generate GoReSym JSON and import it.
4. When r2 is open, use `redress r2 <bin>`.



## Rust notes

- Collect `src/` path strings and `Option`/`Result` handling blocks first.
- `rust_begin_unwind` and panic strings locate crate boundaries; generic
  instantiation inflates code size, so start from string cross-references.
- Tokio state machines resolve through cross-references, not linear reads.
- No goretk equivalent exists for Rust; the panic-string workflow stands.
