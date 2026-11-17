# 005_bram

1024×16 bitの同期single-port RAMをRTLからBSRAMへ推論させ、起動時に全アドレスへ
アドレス依存パターンを書き込み、同期read/compareを行います。

```powershell
.\fpga.ps1 doctor
.\fpga.ps1 sim 005_bram
.\fpga.ps1 build 005_bram
.\fpga.ps1 program 005_bram
```

リポジトリのルートから順に実行し、最初の失敗で止めてください。

BIST成功時はREADY LED、失敗時はDONE LEDが点灯します。実装レポートではBSRAMが
使用され、RAM配列がLUTへ展開されていないことを確認します。
