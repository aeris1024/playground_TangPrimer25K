# 009_sdram_uart

`007_sdram_bist`と同じ25 MHz、BL1/CAS3 backendで64 MB全域BISTを実行し、
オンボードUSB-UARTへ115200 baud、8N1で結果を1行送ります。

```text
TEST 009_sdram_uart ... PASS errors=0x00000000 first=0x0000000
```

FAIL時も同じ形式でエラー数と最初のword addressを16進表示します。

## 実行と確認

Core + DockにSipeed Tang 40-pin SDRAMモジュールV1.2が必要です。
モジュールの着脱は電源を切って行ってください。リポジトリのルートから
以下の順で実行し、最初の失敗で止めてください。

```powershell
.\fpga.ps1 doctor
.\fpga.ps1 sim 009_sdram_uart
.\fpga.ps1 build 009_sdram_uart
.\fpga.ps1 program 009_sdram_uart
```

BISTはSDRAM内のデータを上書きします。programmerが正常終了した後、
オンボードUSB-UARTのCOMポートを115200 baud、8 data bits、no parity、1 stop bitで開き、
上記PASS行を確認します。S1でBISTとUART報告を再実行できます。
testbenchはアドレス範囲を縮小したBISTとUART報告を自己検証するため、
実機64 MB全域の検証とは異なります。
