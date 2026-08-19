# 003_uart_tx

DockのオンボードUSB-UARTへ、115200 baud・8N1で`FPGA UART TX\r\n`を
約1秒ごとに送信します。PC側ではGowin USB DebuggerのCOMポートを115200 baud、
8 data bits、no parity、1 stop bitで開きます。

```powershell
.\fpga.ps1 sim 003_uart_tx
.\fpga.ps1 build 003_uart_tx
.\fpga.ps1 program 003_uart_tx
```

テストベンチはクロックとbaud rateを短縮し、UARTフレームを復号してメッセージ、
start bit、stop bitを自己検証します。
