# [Seed] PCAP custom binary protocol reverse engineering

## Scenario category
Packet capture analysis / protocol reverse engineering

## Goal summary
An IoT device or desktop client uses a custom TCP binary protocol, not HTTP. Recover the frame structure, field meanings, and encryption layer, if any, from a PCAP. Then write a local client/server reproduction.

## Full execution path

1. Open the PCAP in Wireshark and collect basic statistics.
   - `Statistics → Conversations`: inspect IP and port pairs.
   - `Statistics → I/O Graphs`: inspect the traffic timing.
2. Find the real application-layer stream and remove standard layers such as TLS.
3. On a TCP stream, select `Follow → TCP Stream`, switch to RAW mode, and export it.
4. Inspect the bytes: do the first few bytes of each frame contain a fixed magic value or length field?
   ```bash
   xxd dump.bin | head -20
   ```
5. Find patterns in hex mode: fixed header, length, TLV, and CRC.
6. Write a Python parser with `struct` and scapy and decode one frame at a time.
7. Cross-check protocol fields in the binary decompilation. Inspect structs around send/recv in IDA / Ghidra.
8. Verify the result: start a local client, send a frame, and compare the server response.

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| Wireshark did not identify the protocol and showed only "Data" | The protocol is private and has no parser | Write a Wireshark Lua dissector or analyze it offline with Python | 30min |
| The frames looked random and all differed | A compression or encryption layer was present | Use entropy analysis (`ent dump.bin`) to test for encryption and find nonce/IV fields | 1h |
| The length field calculation was wrong | The length might be little-endian, big-endian, or include or exclude itself | Collect frames with different lengths and solve the equations | 40min |
| TLS traffic was captured but could not be decrypted | The client did not keep `SSLKEYLOGFILE` | Hook the client process with Frida and capture plaintext from ssl_read/ssl_write | 1.5h |
| The data was correct but the server did not respond | The protocol used an increasing seq/nonce and rejected replay | Determine the seq calculation, usually a previous-frame hash or an increasing counter | 50min |

## Toolchain findings

- **Wireshark Lua Dissector** can make a private protocol visible in Wireshark in fewer than 100 lines.
- With **scapy**, define a `Packet` subclass to write a Python parser.
- **Kaitai Struct** describes protocol structures in YAML and generates parsers in several languages (Python/Java/C++/JS). It suits repeated use.
- **NetworkMiner** is better for "after-the-fact forensics" than Wireshark because it rebuilds files and identifies credentials automatically.
- **ent / binwalk -E** measure entropy. Values above 7.5 usually indicate encryption.

## Key code / commands

Scapy custom protocol example (TLV):

```python
from scapy.all import *

class MyMsg(Packet):
    name = "MyProto"
    fields_desc = [
        StrFixedLenField("magic", b"\xab\xcd", 2),
        ByteField("version", 1),
        ByteField("type", 0),
        LenField("length", None, fmt="H"),     # H = uint16 BE
        XIntField("seq", 0),
        StrLenField("payload", "", length_from=lambda p: p.length - 8),
        XShortField("crc", 0),
    ]

# Parse the PCAP
pkts = rdpcap('dump.pcap')
for p in pkts:
    if TCP in p and p[TCP].dport == 9527 and p.payload:
        msg = MyMsg(bytes(p[TCP].payload))
        msg.show()
```

Kaitai Struct YAML (preferred for long-term projects):

```yaml
# myproto.ksy
meta:
  id: myproto
  endian: be
seq:
  - id: magic
    contents: [0xab, 0xcd]
  - id: version
    type: u1
  - id: type
    type: u1
  - id: length
    type: u2
  - id: seq_no
    type: u4
  - id: payload
    size: length - 8
  - id: crc
    type: u2
```

Entropy analysis:

```bash
binwalk -E dump.bin             # Entropy graph
ent dump.bin                    # Numeric values
```

## Improvement suggestions for this package

- Add a "four-step custom protocol reverse engineering" section to `reverse-engineering/platforms.md`.
- Add `reverse-engineering/references/kaitai-cheatsheet.md` as a quick reference.
- Add scapy (pip) and binwalk to the bootstrap manifest.

## Reusable patterns / script fragments

**Four-step custom protocol reverse engineering**:

```text
1. Inspect timing (I/O graph + Conversations to find session boundaries)
2. Find frame boundaries (magic / length / terminator)
3. Split fields (fixed header, length, payload, checksum)
4. Check encryption (entropy + find nonce + cross-check the binary send function)
```

**A tip for finding frame lengths**:

Export every PSH packet in the stream → inspect the total length of each TCP segment and test whether the length field (positions i, i+1, or i+2) yields the segment length.

## Evolution actions
- [ ] Add a protocol reverse-engineering section to reverse-engineering/platforms.md
- [ ] Add scapy / binwalk to the bootstrap manifest
- [ ] Add a Kaitai Struct quick reference

## Environment information
- Kali / Ubuntu, Wireshark 4.x, Python 3.10+, scapy 2.5
- Target protocol: custom TCP binary protocol (with TLV / length prefix)
- Encryption layer: depends on the case (common options are AES-CTR / ChaCha20)

## Redaction requirements
This seed entry is based on public protocol reverse-engineering methods and does not involve a real product.
