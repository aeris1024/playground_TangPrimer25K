# 002_button

Tang Primer 25K Dockの2個のボタンとステータスLEDを確認する実験です。
S1を押している間はREADY LED、S2を押している間はDONE LEDが点灯します。

```powershell
.\fpga.ps1 doctor
.\fpga.ps1 sim 002_button
.\fpga.ps1 build 002_button
.\fpga.ps1 program 002_button
```

リポジトリのルートから順に実行し、最初の失敗で止めてください。

ボタン入力はDock上のプルダウンと合わせて正論理、LED出力も正論理です。
テストベンチは4通りのボタン入力を検証し、機械可読なPASS/FAILを出力します。
