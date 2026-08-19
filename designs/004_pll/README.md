# 004_pll

GW5A-25の`PLLA`を使い、Dockの50 MHzクロックから100 MHzを生成します。
DONE LEDはPLLのLOCK中に点灯し、READY LEDは生成した100 MHzクロックで作った
約1 Hzのheartbeatを表示します。

```powershell
.\fpga.ps1 sim 004_pll
.\fpga.ps1 build 004_pll
.\fpga.ps1 program 004_pll
```

Icarus VerilogではPLLプリミティブの代わりに同じ100 MHz出力とLOCK遅延を持つ
シミュレーションモデルを使います。Gowin合成時はArora V用`PLLA`を直接使用します。
