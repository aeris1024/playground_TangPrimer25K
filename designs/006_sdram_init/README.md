# 006_sdram_init

Tang 40-pin SDRAMモジュールの2チップに対し、200 us待機、全bank precharge、
8回auto-refresh、BL1/CAS3のmode register設定を50 MHzで順に実行します。初期化完了後は
READY/DONE LEDが点灯します。S1を押すとコントローラを再初期化します。

## 実行と確認

Core + DockにSipeed Tang 40-pin SDRAMモジュールV1.2が必要です。
モジュールの着脱は電源を切って行ってください。リポジトリのルートから
以下の順で実行し、最初の失敗で止めてください。

```powershell
.\fpga.ps1 doctor
.\fpga.ps1 sim 006_sdram_init
.\fpga.ps1 build 006_sdram_init
.\fpga.ps1 program 006_sdram_init
```

programmerが正常終了した後、READY/DONE LEDの点灯を確認します。
この実験は初期化とrefreshが対象で、データのwrite/read検証は`007`以降で行います。
testbenchは待機期間を短縮し、初期化とrefreshをSDRAM動作モデルで自己検証します。
