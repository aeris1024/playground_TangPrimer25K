# 002_button

Tang Primer 25K Dockの2個のボタンとステータスLEDを確認する実験です。
S1を押している間はREADY LED、S2を押している間はDONE LEDが点灯します。

```powershell
.\fpga.ps1 sim 002_button
.\fpga.ps1 build 002_button
.\fpga.ps1 program 002_button
```

ボタン入力はDock上のプルダウンと合わせて正論理、LED出力は負論理です。
テストベンチは4通りのボタン入力を検証し、機械可読なPASS/FAILを出力します。
