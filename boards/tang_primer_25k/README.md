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
- Tang 40-pin SDRAM: shared 16-bit bus, two 32 MB devices, 64 MB total
- SDRAM DQ12/DQ13 use the FPGA's I2C dual-purpose pins.
- E2 is enabled as a regular GPIO by releasing its CPU/SSPI dual-purpose functions.
- E8 is enabled as a regular GPIO by releasing its READY dual-purpose function.
- D7 is enabled as a regular GPIO by releasing its DONE dual-purpose function.
- B2/C2 are enabled as regular GPIOs by releasing their I2C dual-purpose function.

The pin assignments are taken from Sipeed's official Tang Primer 25K example
constraints. The common SDRAM constraint is shared by designs 006 through 009;
other design-specific constraints remain next to each design.
