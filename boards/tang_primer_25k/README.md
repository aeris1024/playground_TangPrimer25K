# Tang Primer 25K board definition

This board definition targets the Tang Primer 25K core board installed on the
Dock base board.

- FPGA device: `GW5A-LV25MG121NC1/I0`
- FPGA device version: `A`
- Dock oscillator: 50 MHz
- On-board USB-UART TX pin used by `003_uart_tx`: C3
- Gowin Programmer device name: `GW5A-25A`
- Gowin Programmer cable: `USB Debugger A` (cable index 4); the CLI auto-detects its JTAG location.
- Clock pin used by `001_blink`: E2
- Dock READY LED pin used by `001_blink`: E8
- Dock buttons used by `002_button`: S1=H11, S2=H10
- Dock LEDs used by `002_button`: READY=E8, DONE=D7
- E2 is enabled as a regular GPIO by releasing its CPU/SSPI dual-purpose functions.
- E8 is enabled as a regular GPIO by releasing its READY dual-purpose function.
- D7 is enabled as a regular GPIO by releasing its DONE dual-purpose function.

The pin assignments are taken from Sipeed's official Tang Primer 25K example
constraints. Design-specific constraints remain next to each design so that a
design only constrains ports it actually uses.
