# Tang Primer 25K FPGA Playground

Tang Primer 25K Core + Dockを、AI AgentからCLI中心で操作するためのWindows向け
FPGA実験リポジトリです。各実験は独立したmanifestを持ち、同じコマンドで
シミュレーション、Gowinビルド、実機書き込みを行います。

番号付きの独立設計で、LED、ボタン、UART、PLL、オンチップBSRAMを
段階的に検証できます。

## 必要なもの

- Windows 10/11
- Python 3.11以上
- Gowin EDA Education 1.9.9 Beta-4以上（ライセンス不要版）
- Gowin Programmer（V1.9.11.03 Educationで動作確認）
- Icarus Verilog（`iverilog`と`vvp`）
- Tang Primer 25K Core + Dock、データ通信対応USB-Cケーブル

外部ツールはこのリポジトリに同梱しません。各公式配布元のライセンスと
インストーラーに従って手動で導入してください。

## Windowsセットアップ

1. Gowin EDA Educationをインストールします。`gw_sh.exe`は通常、Gowinの
   インストール先にある`IDE\bin`へ配置されます。
2. Gowin ProgrammerとIcarus Verilogをインストールします。Gowin Programmerは
   Gowin EDAのインストールツリーにある`Programmer\bin\programmer_cli.exe`を使います。
3. Tang Primer 25K DockをUSBハブを介さずPCへ接続します。
4. PowerShellで次を実行します。

```powershell
.\fpga.ps1 doctor
```

`PATH`を変更したくない場合は、次の環境変数で実行ファイルを直接指定できます。

```powershell
$env:TANG_GOWIN_SH = 'C:\path\to\Gowin\IDE\bin\gw_sh.exe'
$env:TANG_GOWIN_PROGRAMMER = 'C:\path\to\Gowin\Programmer\bin\programmer_cli.exe'
$env:TANG_IVERILOG = 'C:\path\to\iverilog.exe'
```

`vvp.exe`は`iverilog.exe`と同じディレクトリ、または`PATH`から探索します。

## 基本操作

```powershell
.\fpga.ps1 list
.\fpga.ps1 sim 001_blink
.\fpga.ps1 build 001_blink
.\fpga.ps1 program 001_blink
.\fpga.ps1 clean 001_blink
```

ボタン入力の実験は設計名を`002_button`へ置き換えて同じ順序で実行します。
書き込み後は、S1がREADY LED、S2がDONE LEDを押している間だけ点灯させます。

実装済み設計は次のとおりです。

- `001_blink`: READY LEDを約1 Hzで点滅
- `002_button`: S1/S2をREADY/DONE LEDへ反映
- `003_uart_tx`: オンボードUSB-UARTへ115200 baudで周期送信
- `004_pll`: 50 MHzから100 MHzを生成しLOCKとheartbeatを表示
- `005_bram`: 1024×16 bit BSRAMの起動時write/read BIST

`program`はGowin純正`programmer_cli.exe`を使い、電源断で消えるSRAMへ
`--device GW5A-25A --run 2`で書き込みます。不揮発Flash書き込みは誤操作を避けるため、
現在のCLIでは無効です。

`program`は自動でbuildしません。`build/001_blink/001_blink.fs`が存在しない場合は
エラーになり、先に実行すべきbuildコマンドを表示します。

## ディレクトリ構成

```text
boards/                  ボード固有のデバイス・クロック・programmer定義
common/                  複数の実験で再利用するRTLとシミュレーション部品
designs/<name>/          独立した実験、design.toml、RTL、制約、testbench
tools/fpga.py            Python標準ライブラリだけで実装したCLI
tests/                   CLIの単体テスト
build/                   追跡しない生成物
fpga.ps1                 PowerShell用の正式な入口
```

設計manifestの公開スキーマは次のとおりです。未知のキー、存在しないファイル、
ディレクトリ外を指すパスは処理開始前に拒否されます。

```toml
name = "001_blink"
board = "tang_primer_25k"
top = "top"
sources = ["rtl/top.sv"]
constraints = ["constraints/blink.cst", "constraints/blink.sdc"]
testbench = "sim/tb_top.sv"
```

## テスト

CLI自体のテストには外部パッケージを使いません。

```powershell
python -m unittest discover -s tests -v
```

実機を含む推奨検証順序は`doctor`、`sim`、`build`、`program`です。
書き込み後に内蔵LEDが約1 Hzで点滅すれば初期マイルストーン完了です。

## トラブルシュート

- `MISSING`: 対象ツールを`PATH`へ追加するか、上記の`TANG_*`環境変数を設定します。
- `Gowin shell FAIL`と`License verification failed`: Standard版Gowin EDAにはライセンスが
  必要です。ライセンス不要のEducation版へ入れ替えるか、Standard版のライセンスを設定します。
- JTAGデバイスを検出できない: USBハブを外し、データ対応ケーブル、Dockの電源、
  オンボードデバッガのファームウェアを確認します。
- Gowin Programmerがデバイスを検出できない: DockをUSBハブなしで接続し、電源、
  データ対応USBケーブル、Gowin付属FTDIドライバを確認します。`programmer_cli.exe --scan`
  を直接実行しても切り分けできます。
- Gowin build後に`.fs`が見つからない: `build/<design>/build.log`と生成された
  Gowinプロジェクトを確認し、デバイス型番とtop moduleが正しいことを確認します。
- Flash書き込みは初期動作確認には不要で、現在は未対応です。まずSRAM書き込みで確認してください。

## ロードマップ

1. 基盤と`001_blink`（完了）
2. `002_button`、`003_uart_tx`、`004_pll`、`005_bram`（実装済み）
3. `006_sdram_init`、`007_sdram_bist`、`008_sdram_burst`、`009_sdram_uart`
4. FIFO、SPI、I2S、DDS、FIR/IIR、FFT、DMA、softcore
5. 実験用のYosys + nextpnr-gowin + Apicula backend

## 参考資料

- [Sipeed Tang Primer 25K](https://wiki.sipeed.com/hardware/en/tang/tang-primer-25k/primer-25k.html)
- [Sipeed Tang Primer 25K examples](https://github.com/sipeed/TangPrimer-25K-example)
- [Gowin Software Tcl Commands](https://www.gowinsemi.com/upload/database_doc/3262/document/68b8a001a6a92.pdf)
- [Gowin Programmer User Guide](https://cdn.gowinsemi.com.cn/SUG502E.pdf)
