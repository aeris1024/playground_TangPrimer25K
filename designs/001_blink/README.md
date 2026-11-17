# 001_blink

The first hardware smoke test for the Tang Primer 25K Dock. The 50 MHz input
clock drives a counter that toggles the READY LED every 25,000,000 cycles,
giving a complete on/off cycle of approximately one second.

```powershell
.\fpga.ps1 doctor
.\fpga.ps1 sim 001_blink
.\fpga.ps1 build 001_blink
.\fpga.ps1 program 001_blink
```

Run from the repository root in this order and stop at the first failure.
After programming exits successfully, observe the READY LED blinking to confirm
hardware operation.

The testbench overrides the counter period, verifies at least four output
transitions, and prints a machine-readable PASS or FAIL line.
