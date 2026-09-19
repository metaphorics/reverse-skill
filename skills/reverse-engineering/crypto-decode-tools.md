# Encryption and Decryption / Encoding and Decoding Tools Quick Reference

> Reverse engineering and CTF work often involve encrypted, encoded, or hashed data. This document lists the most useful tools by scenario.

---

## Automatic Identification + Decryption (when you do not know which encryption was used)

| Tool | Stars | Use | Link |
|------|-------|------|------|
| **Ciphey** | 18k+ | AI-based automatic identification and decryption (supports 50+ encoding, encryption, and hash types) | https://github.com/Ciphey/Ciphey |
| **CyberChef** | 29k+ | Online/offline encoding and decoding Swiss Army knife (drag-and-drop operations) | https://github.com/gchq/CyberChef |
| **dcode.fr** | — | 900+ online cipher, encoding, and math tools | https://www.dcode.fr/ |

### Using Ciphey

```bash
pip install ciphey
# Automatically detect and decrypt
ciphey -t "ciphertext"
# Read from a file
ciphey -f encrypted.txt
```

Ciphey supports: Base64/32/16, Caesar, Vigenere, XOR, AES (weak keys), Morse, Binary, Hex, URL encoding, HTML entities, hash identification, and more.

### Using CyberChef

```text
Online version: https://gchq.github.io/CyberChef/
Offline version: Download the HTML file from the GitHub Release and open it directly

Common Recipes:
- From Base64 → Decode Base64
- XOR → XOR decryption (you can try keys by brute force)
- AES Decrypt → AES decryption
- Magic → Automatically detect the encoding type
```

---

## Hash Identification and Cracking

| Tool | Use | Link |
|------|------|------|
| **hashID** | Identifies hash types (MD5/SHA/bcrypt and more) | https://github.com/psypanda/hashID |
| **hash-identifier** | Same as above, Python version | https://github.com/blackploit/hash-identifier |
| **haiti** | Modern hash identification tool (more accurate) | `gem install haiti` |
| **Hashcat** | GPU hash cracking | https://hashcat.net/ |
| **John the Ripper** | CPU hash cracking | https://www.openwall.com/john/ |
| **hashes.com** | Online hash lookup (rainbow table) | https://hashes.com/ |

```bash
# Identify the hash type
hashid '5f4dcc3b5aa765d61d8327deb882cf99'
# Output: [+] MD5

# haiti (more accurate)
haiti '5f4dcc3b5aa765d61d8327deb882cf99'

# Crack with Hashcat
hashcat -m 0 hash.txt rockyou.txt  # MD5
hashcat -m 1000 hash.txt rockyou.txt  # NTLM
```

---

## RSA Attacks

| Tool | Use | Link |
|------|------|------|
| **RsaCtfTool** | Automatic RSA attacks (20+ attack methods) | https://github.com/Ganapati/RsaCtfTool |
| **SageMath** | Mathematical calculations (large-number factorization and elliptic curves) | https://www.sagemath.org/ |
| **factordb.com** | Online large-number factorization lookup | http://factordb.com/ |
| **yafu** | Local large-number factorization | https://github.com/bbuhrow/yafu |

```bash
# Automatically attack with RsaCtfTool
python RsaCtfTool.py --publickey pub.pem --private
python RsaCtfTool.py --publickey pub.pem --uncipherfile cipher.txt

# Supported attacks:
# Wiener, Boneh-Durfee, Fermat, Pollard p-1, Williams p+1
# Common modulus, Small q, Hastads, Noveltyprimes, etc.
```

---

## XOR Analysis

| Tool | Use | Link |
|------|------|------|
| **xortool** | XOR key length guess + known-plaintext attack | https://github.com/hellman/xortool |
| **CyberChef XOR** | Visual XOR operation | CyberChef built-in |

```bash
# Guess the XOR key length
xortool encrypted_file
# Decrypt with the guessed key length
xortool -l 4 -c 00 encrypted_file

# Known-plaintext attack (know part of the plaintext)
xortool-xor -f encrypted -s "known_plaintext"
```

---

## Classical Ciphers

| Cipher Type | Tool | Description |
|---------|------|------|
| Caesar | CyberChef / dcode.fr | Brute-force 25 shifts |
| Vigenere | dcode.fr / Ciphey | Guess the key length |
| Substitution | quipqiup.com | Automatic frequency-analysis solution |
| Enigma | dcode.fr | Online simulator |
| Rail Fence | dcode.fr / CyberChef | Rail fence cipher |
| Playfair | dcode.fr | Requires a key |
| Morse | CyberChef | Convert dots and dashes to text |
| Bacon | dcode.fr | Binary steganography |
| ROT13/47 | CyberChef / `tr` | Simple substitution |

---

## Encoding Identification and Conversion

| Encoding | Identification Feature | Decoding Method |
|------|---------|---------|
| Base64 | Ending `=` or `==`, character set A-Za-z0-9+/ | `base64 -d` / CyberChef |
| Base32 | Uppercase letters + 2-7, ending `=` | CyberChef |
| Base58 | No 0/O/I/l, common in short identifier encoding | CyberChef |
| Hex | Only 0-9a-f, even length | `xxd -r -p` / CyberChef |
| URL encoding | `%XX` format | `urldecode` / CyberChef |
| HTML entities | `&#XX;` or `&amp;` format | CyberChef |
| Unicode escape | `\uXXXX` format | Python `decode('unicode_escape')` |
| JWT | `xxxxx.yyyyy.zzzzz` (three Base64URL segments) | jwt.io / CyberChef |
| Brainfuck | Only the eight characters `><+-.,[]` | Online interpreter |
| Ook! | Only `Ook.` `Ook!` `Ook?` | Online interpreter |

---

## Encryption Identification in Reverse Engineering

### Identify Algorithms by Constants

| Constant/Feature | Algorithm |
|-----------|------|
| `0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476` | MD5 |
| `0x6A09E667, 0xBB67AE85, 0x3C6EF372` | SHA-256 |
| `0x63, 0x7C, 0x77, 0x7B` (start of the S-Box) | AES |
| `0x243F6A88` (hexadecimal value of pi) | Blowfish |
| `0xB7E15163, 0x9E3779B9` | RC5/RC6/TEA |
| `0x61707865` ("expa") | ChaCha20/Salsa20 |
| `0xC6EF3720` | XTEA |

### Identify Algorithms by Behavior

| Behavior | Possible Algorithm |
|---------|-----------|
| 256-byte lookup table + swap operation | RC4 |
| 16-byte blocks + multiple rounds of permutation | AES |
| Feistel structure (swap left and right) | DES/Blowfish/TEA |
| Large-number multiplication/modular exponentiation | RSA |
| Elliptic-curve point operations | ECDSA/ECDH |
| Fixed 64-round loop | TEA/XTEA |
| 32 rounds + delta constant | XTEA |

---

## Automated Cryptanalysis

| Tool | Purpose | Link |
|------|------|------|
| **FeatherDuster** | Automated cryptanalysis framework | https://github.com/nccgroup/featherduster |
| **PkCrack** | ZIP known-plaintext attack | https://www.unix-ag.uni-kl.de/~conrad/krypto/pkcrack.html |
| **bkcrack** | ZIP known-plaintext attack (modern version) | https://github.com/kimci86/bkcrack |
| **z3** | SMT solver (constraint solving) | https://github.com/Z3Prover/z3 |
| **angr** | Symbolic execution (automated input solving) | https://angr.io/ |

---

## Quick Decision Tree

```text
Obtain a piece of unknown data:

1. Check the length and character set
   - Only hex characters → possibly hex encoding or a hash
   - Ends with = → Base64
   - Three dot-separated segments → JWT
   - 32/40/64 hex characters → hash (MD5/SHA1/SHA256)

2. Use Ciphey to try automatically
   ciphey -t "data"

3. If Ciphey fails → use CyberChef Magic mode

4. If it is a hash → identify the type with hashID → crack it with Hashcat/John

5. If it is RSA → use RsaCtfTool to attack it automatically

6. If it is XOR → use xortool to analyze the key

7. If it is traditional ZIP encryption → prioritize `bkcrack` known-plaintext attack; do not start with password brute force without evidence

8. If it is custom encryption → reverse-engineer the algorithm with IDA/Ghidra → write a decryption script
```

---

## Online Resources

| Resource | Link | Use |
|------|------|------|
| CyberChef | https://gchq.github.io/CyberChef/ | General Encoding and Decoding |
| dcode.fr | https://www.dcode.fr/ | 900+ Cipher Tools |
| quipqiup | https://quipqiup.com/ | Automatic Substitution Cipher Solver |
| factordb | http://factordb.com/ | RSA Large Integer Factorization |
| jwt.io | https://jwt.io/ | JWT Decoding and Verification |
| hashes.com | https://hashes.com/ | Hash Lookup |
| crackstation | https://crackstation.net/ | Online Hash Cracking |
