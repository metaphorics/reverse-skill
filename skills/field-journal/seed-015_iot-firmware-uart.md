# [Seed] IoT router firmware extraction + root shell over UART

## Scenario category
Firmware / IoT security

## Goal summary
Download firmware for a low-end home router from the vendor site, extract SquashFS with binwalk, connect to the device UART, obtain a root shell, and analyze its Web management interface and startup scripts.

## Full execution path

### Part 1: firmware analysis

1. Download the firmware file (vendor site / OpenWRT / a flash dump).
2. Identify the file.
   ```bash
   file firmware.bin
   binwalk firmware.bin                    # LZMA / SquashFS / U-Boot
   binwalk -E firmware.bin                 # Entropy graph for encryption
   ```
3. Extract it.
   ```bash
   binwalk -e firmware.bin
   cd _firmware.bin.extracted/squashfs-root
   ```
4. Check key points with static analysis.
   ```bash
   find . -name 'shadow' -exec cat {} \;          # Default password hash
   find . -name '*.cgi' -o -name 'lighttpd*'      # Web service
   find . -name 'rcS' -o -name 'init.d'           # Startup scripts
   grep -r 'telnetd\|busybox' .                   # Suspected backdoor
   strings $(find . -name 'httpd') | grep -i 'admin\|debug\|backdoor'
   ```
5. Crack `/etc/shadow` offline.
   ```bash
   john --wordlist=rockyou.txt shadow
   ```

### Part 2: hardware UART

1. Open the device and inspect the PCB → find an unused four-pin or six-pin connector, often unsoldered or fitted with pins.
2. Identify the pins with a multimeter.
   - GND (connected to the ground plane)
   - VCC (3.3 V and stable during boot)
   - TX (frequent level changes during boot, output from UART to PC)
   - RX (mostly unchanged during boot)
3. Connect a USB-TTL adapter (CP2102 / FT232).
   - Router TX → USB-TTL RX
   - Router RX → USB-TTL TX
   - Router GND → USB-TTL GND
   - **Do not connect VCC** (the device supplies its own power).
4. Start a serial listener on the host.
   ```bash
   sudo screen /dev/ttyUSB0 115200
   # Or: minicom / picocom
   ```
5. Power on → inspect U-Boot output → wait for Linux to start → usually reach the login prompt.
6. Try default credentials or the recovered shadow password → obtain a root shell.

## Pitfall log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| binwalk produced an empty directory | Some firmware used a non-standard format with a vendor-specific header | Use `dd` to cut slices by offset, or use `unblob` instead of binwalk | 1h |
| binwalk -E showed entropy near 1 | The whole image was encrypted | Find the decryption key used during firmware upgrades, usually hard-coded in an OEM tool | Several hours |
| UART showed no characters | The baud rate was wrong | Try 9600 / 38400 / 57600 / 115200 / 460800 / 921600 | 30min |
| UART showed garbled characters | TX/RX were reversed or voltage levels differed | 1) Swap TX and RX 2) Confirm that USB-TTL uses 3.3 V, not 5 V | 30min |
| A login prompt appeared but no password worked | The image was not cracked and the vendor changed the default password | Interrupt U-Boot with a key → `setenv bootargs ${bootargs} init=/bin/sh` → enter single-user mode | 1.5h |
| U-Boot did not respond to a key interrupt | The vendor disabled the console or changed the prompt | Find `bootdelay` in the firmware. Short the SPI flash physically to force a boot failure and enter the U-Boot prompt | Several hours |
| Root access worked but telnetd did not | The image lacked dropbear/telnetd | Copy a static busybox onto the device from USB | 1h |

## Toolchain findings

- **unblob** identifies more formats than binwalk and does not stop at vendor-specific headers.
- **firmware-mod-kit** is old but still supports unpacking and repacking.
- **firmwalker** scans extracted SquashFS for sensitive clues such as credentials, private keys, URLs, and binary backdoors.
- **EMBA** is a firmware-audit platform. It automates firmwalker, binary CVE scanning, and emulated boot.
- **FirmAE** uses QEMU to boot IoT firmware and analyze its Web interface without the real device.
- **ChirpStack USB-TTL**, **Bus Pirate**, and **Tigard** work. An inexpensive CP2102 is sufficient.

## Key code / commands

Firmware audit flow:

```bash
# 1. Extract
unblob -k firmware.bin -o extracted/

# 2. Run firmwalker
git clone https://github.com/craigz28/firmwalker
./firmwalker.sh extracted/squashfs-root

# 3. Emulate boot, if supported
docker run -it --rm -v $(pwd):/firmware firmae:latest \
  /work/run.sh -d 1 /firmware/firmware.bin

# 4. Scan the emulated Web service with nuclei / nikto / curl
```

Automatically try common UART baud rates:

```bash
for baud in 9600 19200 38400 57600 115200 460800 921600; do
    echo "--- $baud ---"
    timeout 3 sudo cat /dev/ttyUSB0 < <(stty -F /dev/ttyUSB0 $baud cs8 -cstopb -parenb)
done
```

Classic U-Boot single-user bypass:

```text
# Interrupt U-Boot with a key (usually hold Space or press Ctrl+C)
=> setenv bootargs "console=ttyS0,115200 root=/dev/mtdblock2 rootfstype=squashfs init=/bin/sh"
=> saveenv
=> boot
# The shell starts directly without a password
```

## Improvement suggestions for this package

- `reverse-engineering/platforms.md` already includes a firmware section. Split out `references/iot-firmware-cheatsheet.md`.
- Add `reverse-engineering/references/uart-debug.md` with an introduction to UART/JTAG/SWD.
- Add unblob / firmwalker to the bootstrap manifest.

## Reusable patterns / script fragments

**Four phases of IoT security testing**:

```text
Phase 1 — software
  · Download vendor firmware + extract with binwalk/unblob
  · Run firmwalker
  · grep for default credentials / private keys / backdoor strings
  · Emulate boot with QEMU and scan the Web service

Phase 2 — hardware
  · Open the device and find UART/JTAG test points
  · Identify GND/VCC/TX/RX with a multimeter
  · Wire the USB-TTL adapter and confirm 3.3 V levels

Phase 3 — debugging
  · Listen with screen/minicom
  · Interrupt U-Boot and enter its prompt
  · Use init=/bin/sh for single-user access without a password

Phase 4 — exploitation
  · Obtain root → crack /etc/shadow offline
  · Inspect Web management CGI binaries → find command injection / SSRF
  · Inspect UPnP / mDNS / Bluetooth broadcast logic
```

**Default credential quick reference** (common vendors):

```text
admin / admin
admin / password
root / root
root / 1234
support / support
ubnt / ubnt          # Ubiquiti
admin / 1234         # ZyXEL
```

## Evolution actions
- [ ] Split out iot-firmware-cheatsheet.md
- [ ] Create uart-debug.md
- [ ] Add unblob / firmwalker to the bootstrap manifest

## Environment information
- Kali 2026.x (binwalk / unblob / squashfs-tools / firmwalker)
- USB-TTL adapter: CP2102 / FT232 (3.3 V levels)
- Target: ARMv7 / MIPS router (common OpenWRT-derived firmware)

## Redaction requirements
This seed entry is based on public IoT security-testing methods and does not involve a real vendor or model.
