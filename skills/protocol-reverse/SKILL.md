---
name: protocol-reverse
description: Use for authorized reverse engineering of custom binary protocols, Protobuf/gRPC, WebSocket frames, and PCAP-driven protocol recovery.
---

# Protocol Reverse Engineering

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md` — confirm the authorization and routine-operation boundaries
2. `NOW`: Confirm the task is **protocol/traffic/serialization format** reverse engineering (pure web parameter signing → route to `js-reverse/`)
3. `NOW`: With target network interaction → complete scope through `../scripts/case-init.ps1`. Do not ACT on the target before `auth` is granted
4. `NEXT`: Read `../tool-index.md`. Bootstrap missing tools (tshark/wireshark may need manual installs)
5. `ACT`: Enter workflow Phase 1. Produce a frame layout or message dictionary draft

## Scope of use

- Custom TCP/UDP binary protocols
- Protobuf / gRPC / FlatBuffers / MessagePack
- WebSocket / MQTT / private RPC
- Field and state-machine recovery from PCAP / PCAPNG
- Client-server validation, sequence numbers, encrypted frame headers

## Not this skill

| Case | Go to |
|------|------|
| HTTP parameter signing / JS crypto only | `js-reverse/` |
| TLS certificate issues only | `pentest-tools/` or a browser proxy |
| Deep firmware protocol stack work + emulation | `firmware-pentest/`, then return to this skill |

## Workflow

### Phase 1 — Collection and triage

```text
□ Get samples: PCAP / proxy export / client logs / binaries
□ Mark the direction: C→S / S→C, note handshake, heartbeat, and reconnects
□ Fixed header? Magic bytes? Length field? TLV? Fixed length?
□ Compressed (zlib/gzip/lz4) or encrypted (AES/ChaCha inside the frame)?
□ tshark -r cap.pcap -T fields -e frame.number -e ip.src -e tcp.payload
```

### Phase 2 — Frame layout recovery

```text
□ Align multiple same-type messages, find invariant bytes / incrementing sequence numbers
□ Length field: big-endian/little-endian, with header/without header
□ Checks: CRC16/32, checksum, HMAC position
□ Draw the state machine: Connect → Auth → Ready → Request/Response → Close
□ Tools: Wireshark custom dissector draft / ImHex / 010 Editor templates / Kaitai Struct
```

### Phase 3 — Serialization and encryption

```text
□ Protobuf: recover the .proto (blackboxprotobuf / pbtk / protoc --decode_raw)
□ gRPC: HTTP/2 headers + protobuf body
□ Encryption: find key derivation (client so/dll/JS) → pair with ida-reverse / js-reverse / apk-reverse
□ Replay: only inside the authorized scope, harmless fields before sensitive operations
```

### Phase 4 — Deliverables

```text
MUST produce:
- Message type table (name / opcode / fields)
- At least 1 reproducible decode command or script
- Evidence: raw hex excerpt + decoded result (redacted)
```

## Toolchain

| Tool | Required | Purpose | Bootstrap |
|------|------|------|------|
| tshark / Wireshark | Strongly recommended | PCAP parsing | Manual / winget |
| Python3 | Yes | Decode scripts | System |
| blackboxprotobuf | Optional | Unknown protobuf | pip |
| ImHex / 010 | Optional | Structure templates | Manual |
| IDA / r2 / Ghidra | As needed | Client serialization functions | See the matching skill |

## References

- `references/protocol-workflow.md` — frame layout and Protobuf quick reference
- Related: `../ida-reverse/` `../js-reverse/` `../firmware-pentest/` `../pentest-tools/`

## Routing context

**Upstream**: `MASTER-ROUTING` R21 · `routing.md`  
**Downstream**: client-side algorithms → `ida-reverse`/`js-reverse`, exploit or replay → `pentest-tools`/`api-security`  
**Peers**: `malware-analysis` (C2 protocols), `digital-forensics` (traffic forensics)

## Task completion self-check

- [ ] Is the message layout or state machine recovered (not just pasted hex)?
- [ ] Is there a reproducible decode command?
- [ ] Are scope and redaction rules obeyed?
- [ ] Are field-journal and report Checklist items written back?