# CTF Resource Quick Reference

> Selected from [awesome-ctf-resources](https://github.com/devploit/awesome-ctf-resources) and [awesome-ctf](https://github.com/apsdehal/awesome-ctf)
> Grouped by CTF challenge type. Includes only the most useful tools and resources.

---

## General Frameworks

| Tool | Purpose | Link |
|------|------|------|
| Pwntools | Exploit development framework (Python) | https://github.com/Gallopsled/pwntools |
| ctf-tools | One-click CTF tool installation | https://github.com/zardus/ctf-tools |
| Ciphey | AI-assisted decryption | https://github.com/ciphey/ciphey |
| CyberChef | Online encoding, decoding, and cryptography | https://gchq.github.io/CyberChef/ |

---

## Web Challenges

### Tools
| Tool | Purpose |
|------|------|
| Burp Suite | HTTP interception, replay, and scanning |
| SQLMap | SQL injection |
| XSStrike | XSS detection |
| dirsearch | Directory discovery |
| JWT_Tool | JWT attacks |
| SSRFmap | SSRF exploitation |

### Common Challenge Topics
- SQL injection (UNION-based, blind injection, time-based blind injection, stacked queries)
- XSS (reflected, stored, DOM)
- SSRF (internal-network probing, cloud metadata)
- File upload (extension, MIME, and content-filter bypass)
- Deserialization (PHP/Java/Python pickle)
- Template injection (SSTI)
- JWT forgery / key confusion

### Payload References
- https://github.com/swisskyrepo/PayloadsAllTheThings
- https://book.hacktricks.wiki/

---

## Reverse Engineering Challenges

### Tools
| Tool | Purpose |
|------|------|
| IDA Pro / Ghidra | Decompilation |
| radare2 / r2 | CLI analysis |
| angr | Symbolic execution |
| Frida | Dynamic hooking |
| GDB + pwndbg | Debugging |
| uncompyle6 | Python decompilation |
| jadx | Android decompilation |
| dnSpy | .NET decompilation |

### Common Challenge Topics
- Algorithm recovery (encryption, encoding, custom algorithms)
- Anti-debugging / anti-VM bypass
- Packers / obfuscation (UPX/VMProtect/OLLVM)
- Symbolic execution constraint solving
- Dynamic hook bypass
- Go/Rust reverse engineering (symbol recovery)

---

## Pwn Challenges

### Tools
| Tool | Purpose |
|------|------|
| Pwntools | Exploit development |
| GDB + pwndbg/GEF | Debugging |
| ROPgadget | ROP chain construction |
| one_gadget | libc one-shot |
| checksec | Protection checks |
| LibcSearcher | libc version identification |

### Common Challenge Topics
- Stack overflow (ret2text/ret2libc/ret2shellcode/ROP)
- Heap exploitation (UAF/double free/tcache/fastbin)
- Format-string vulnerabilities (arbitrary read/write)
- Integer overflow
- Kernel Pwn (privilege escalation / race conditions)
- Sandbox escape (seccomp bypass)

### Common Payload Pattern
```python
# ret2libc 模板
from pwn import *
elf = ELF('./vuln')
libc = ELF('./libc.so.6')
p = process('./vuln')
# leak libc base → calculate system/binsh → overwrite ret
```

---

## Crypto Challenges

### Tools
| Tool | Purpose |
|------|------|
| SageMath | Mathematical calculations |
| RsaCtfTool | Automated RSA attacks |
| hashcat/john | Hash cracking |
| CyberChef | Encoding and decoding |
| z3 (SMT solver) | Constraint solving |

### Common Challenge Topics
- RSA (small public exponent/common modulus/Wiener/Coppersmith)
- AES (ECB/CBC padding oracle/bit flipping)
- Classical ciphers (Caesar/Vigenere/transposition)
- Hash length-extension attacks
- Elliptic curves (ECDSA nonce reuse)
- Lattice cryptography (LLL/CVP)

---

## Forensics Challenges

### Tools
| Tool | Purpose |
|------|------|
| Volatility | Memory forensics |
| Autopsy/Sleuth Kit | Disk forensics |
| Wireshark | Traffic analysis |
| binwalk | Firmware/file extraction |
| foremost | File recovery |
| exiftool | Metadata extraction |

### Common Challenge Topics
- Memory dump analysis (processes/passwords/malware)
- PCAP traffic analysis (HTTP/DNS/TCP reassembly)
- File-system analysis (deleted-file recovery/hidden partitions)
- Log analysis (Web/system logs)
- Disk-image analysis

---

## Misc/Stego Challenges

### Tools
| Tool | Purpose |
|------|------|
| StegSolve | Image steganography analysis |
| zsteg | PNG/BMP steganography |
| steghide | JPEG steganography |
| Audacity | Audio analysis |
| strings/xxd | Basic analysis |
| file/binwalk | File-type identification |

### Common Challenge Topics
- LSB steganography (image least significant bits)
- File-header repair/concatenation
- QR codes/barcodes
- Audio spectrogram steganography
- ZIP pseudo-encryption/known-plaintext attack
- Encoding identification (Base64/Hex/Morse/Braille)

---

## Online Platforms

| Platform | Features | Link |
|------|------|------|
| CTFTime | Competition calendar + writeups | https://ctftime.org/ |
| HackTheBox | Hands-on targets | https://www.hackthebox.com/ |
| TryHackMe | Guided learning | https://tryhackme.com/ |
| PicoCTF | Beginner-friendly | https://picoctf.org/ |
| pwnable.kr | Pwn challenges | http://pwnable.kr/ |
| cryptopals | Crypto challenges | https://cryptopals.com/ |
| OverTheWire | War-themed challenges | https://overthewire.org/ |
| Root-Me | General challenges | https://www.root-me.org/ |

---

## Writeup Resources

| Resource | Link |
|------|------|
| CTFTime Writeups | https://ctftime.org/writeups |
| 0xdf hacks stuff | https://0xdf.gitlab.io/ |
| LiveOverflow (YouTube) | https://www.youtube.com/c/LiveOverflow |
| John Hammond (YouTube) | https://www.youtube.com/c/JohnHammond010 |
| IppSec (HTB walkthrough) | https://www.youtube.com/c/ippsec |
