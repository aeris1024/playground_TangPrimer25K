# Tang Primer 25K board definition

This board definition targets the Tang Primer 25K core board installed on the
Dock base board.

- FPGA device: `GW5A-LV25MG121NC1/I0`
- FPGA device version: `A`
- Dock oscillator: 27 MHz
- Gowin Programmer device name: `GW5A-25A`
- Gowin Programmer cable: `USB Debugger A` (cable index 4); the CLI auto-detects its JTAG location.
- Clock pin used by `001_blink`: E2
- Dock READY LED pin used by `001_blink`: E8
- E2 is enabled as a regular GPIO by releasing its CPU/SSPI dual-purpose functions.
- E8 is enabled as a regular GPIO by releasing its READY dual-purpose function.

The pin assignments are taken from Sipeed's official Tang Primer 25K example
constraints. Design-specific constraints remain next to each design so that a
design only constrains ports it actually uses.
