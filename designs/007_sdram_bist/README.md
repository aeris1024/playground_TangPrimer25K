# 007_sdram_bist

固定値4種、walking-one 16種、word address由来パターンの順でwrite/read/compareを
実行します。既定の`TOTAL_BURSTS=4194304`は8 word単位で64 MB全域です。
25 MHz、BL1/CAS3 backendを使用します。READY LEDはPASS、DONE LEDは
FAILを示します。S1で再実行できます。

## 実行と確認

Core + DockにSipeed Tang 40-pin SDRAMモジュールV1.2が必要です。
モジュールの着脱は電源を切って行ってください。リポジトリのルートから
以下の順で実行し、最初の失敗で止めてください。

```powershell
.\fpga.ps1 doctor
.\fpga.ps1 sim 007_sdram_bist
.\fpga.ps1 build 007_sdram_bist
.\fpga.ps1 program 007_sdram_bist
```

BISTはSDRAM内のデータを上書きします。programmerが正常終了した後、
BISTの完了を待ち、READY LEDの点灯とDONE LEDの消灯を確認します。
testbenchはアドレス範囲を縮小して自己検証するため、実機64 MB全域の検証とは異なります。
