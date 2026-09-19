# Debug Interface Triage

1. Find silkscreen labels: TX RX GND VCC TDI TDO TCK TMS.
2. Match voltage before connecting.
3. Read serial logs only at first.
4. Record the U-Boot interrupt key and environment variables. Do not run saveenv arbitrarily.
5. Extract the image and record its SHA256 hash.
