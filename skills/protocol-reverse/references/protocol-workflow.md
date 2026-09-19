# Protocol reverse quick reference

> Applies to: `protocol-reverse` skill · 2026-07-18

## Common layout patterns

| Pattern | Trait | Hint |
|------|------|------|
| Fixed header + body | First 2/4 bytes give the length | Check whether the length includes the header |
| Magic bytes | Fixed `0xDEAD` and similar | Helps stream resync |
| TLV | Repeating type-length-value | The type enum is the message dictionary |
| Protobuf | Field numbers as varints | `protoc --decode_raw` |
| Encrypted frames | High entropy, no plaintext URLs | First search near the nonce/IV |

## Minimal Python skeleton

```python
import struct
def parse_frame(buf: bytes):
    magic, length, msg_type = struct.unpack_from(">IHI", buf, 0)
    body = buf[10:10+length]
    return {"magic": magic, "type": msg_type, "body": body}
```

## Extract TCP payload from PCAP

```bash
tshark -r cap.pcap -Y "tcp.port==4433" -T fields -e tcp.payload | head
```