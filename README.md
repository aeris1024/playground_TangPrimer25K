# Tang Primer 25K FPGA Playground

Tang Primer 25K Core + Dockで、LEDから外付けSDRAMまで段階的に学ぶ
Windows向けFPGA実験リポジトリです。PowerShellからCLI中心で操作でき、
各実験は独立したmanifestを持ち、同じコマンドで
シミュレーション、Gowinビルド、実機書き込みを行います。

番号付きの独立設計で、LED、ボタン、UART、PLL、オンチップBSRAM、外付けSDRAMを
段階的に検証できます。

学習・実験用のプロジェクトです。各設計の実装とテストベンチを公開していますが、
すべてのボード・ツールバージョンでの動作を保証するものではありません。
Sipeed / Gowinの公式プロジェクトではありません。

- [実験一覧](#実験一覧) / [セットアップ](#windowsセットアップ) / [トラブルシュート](#トラブルシュート)
- [開発・貢献ガイド](CONTRIBUTING.md) / [ロードマップ](docs/ROADMAP.md)
- [ライセンス](LICENSE) / [外部ツール・参考元](THIRD_PARTY_NOTICES.md)

## 必要なもの

- Windows 10/11
- Python 3.11以上
- Gowin EDA Education（既存の開発環境: 1.9.9 Beta-4）
- Gowin Programmer（既存の開発環境: V1.9.11.03 Education）
- Icarus Verilog（`iverilog`と`vvp`）
- Tang Primer 25K Core + Dock、データ通信対応USB-Cケーブル
- `006`以降ではSipeed Tang 40-pin SDRAMモジュールV1.2

外部ツールはこのリポジトリに同梱しません。各公式配布元のライセンスと
インストーラーに従って手動で導入してください。
上記バージョンは開発時の記録です。別バージョンを利用する場合は`doctor`と各検証で
互換性を確認してください。CLIとその単体テストはPython標準ライブラリのみを使います。

## Windowsセットアップ

1. このリポジトリをcloneまたはZIPで取得し、PowerShellでルートディレクトリを開きます。
2. Python 3.11以上をインストールし、`python --version`が成功することを確認します。
3. Gowin EDA Educationをインストールします。`gw_sh.exe`は通常、Gowinの
   インストール先にある`IDE\bin`へ配置されます。
4. Gowin ProgrammerとIcarus Verilogをインストールします。Gowin Programmerは
   Gowin EDAのインストールツリーにある`Programmer\bin\programmer_cli.exe`を使います。
5. Tang Primer 25K DockをUSBハブを介さずPCへ接続します。
6. PowerShellで次を実行します。

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
.\fpga.ps1 doctor
.\fpga.ps1 sim 001_blink
.\fpga.ps1 build 001_blink
.\fpga.ps1 program 001_blink
```

上記はコマンドの実行順です。各コマンドの終了コードを確認し、失敗したらそこで止めて
原因を解消してください。`doctor`はツールの起動に加え、接続されたJTAGデバイスも調べます。
`program`成功後、READY LEDの約1 Hzの点滅を目で確認して実機確認完了とします。
生成物の削除には`.\fpga.ps1 clean 001_blink`を使います。

ボタン入力の実験は設計名を`002_button`へ置き換えて同じ順序で実行します。
書き込み後は、S1がREADY LED、S2がDONE LEDを押している間だけ点灯させます。
DockのREADY/DONE LEDはactive-highで、FPGA出力が`1`のとき点灯します。

## 実験一覧

設計名はCLIの`.\fpga.ps1 list`で確認できます。公開の設計探索入口は
各ディレクトリの`design.toml`です。各リンクに動作・観測方法をまとめています。

| 設計 | 内容 | 追加ハードウェア |
| --- | --- | --- |
| [001_blink](designs/001_blink/README.md) | READY LEDを約1 Hzで点滅 | なし |
| [002_button](designs/002_button/README.md) | S1/S2をREADY/DONE LEDへ反映 | なし |
| [003_uart_tx](designs/003_uart_tx/README.md) | USB-UARTへ115200 baudで周期送信 | なし |
| [004_pll](designs/004_pll/README.md) | 50 MHzから100 MHzを生成しLOCKとheartbeatを表示 | なし |
| [005_bram](designs/005_bram/README.md) | 1024×16 bit BSRAMの起動時write/read BIST | なし |
| [006_sdram_init](designs/006_sdram_init/README.md) | 2個の32 MB SDRAMを初期化し定期refreshを開始 | SDRAMモジュール |
| [007_sdram_bist](designs/007_sdram_bist/README.md) | 固定値・walking-one・address patternで64 MB全域BIST | SDRAMモジュール |
| [008_sdram_burst](designs/008_sdram_burst/README.md) | 8 word連続write/readとUARTによる実測値表示 | SDRAMモジュール |
| [009_sdram_uart](designs/009_sdram_uart/README.md) | 全域BIST結果を機械可読なUART行で送信 | SDRAMモジュール |

### SDRAM設計について

SDRAM設計は16-bit data bus、CAS latency 3、burst length 1で動作します。
`006_sdram_init`は50 MHz、`007_sdram_bist`・`008_sdram_burst`・`009_sdram_uart`は
25 MHzを使います。データ転送は8個の連続word commandを1回の論理transactionとして扱います。
`sdram_cs`は通常のactive-low chip-selectではなく、モジュール上の2個のSDRAMを
選択する信号です。S1を押すと初期化から再実行します。007と009の既定BIST範囲は
`4194304 burst × 8 word × 2 byte = 64 MB`です。

009のUART出力例は次のとおりです。

```text
TEST 009_sdram_uart ... PASS errors=0x00000000 first=0x0000000
```

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
docs/                    ロードマップと公開前チェック
build/                   追跡しない生成物
fpga.ps1                 PowerShell用の正式な入口
```

設計manifestの公開スキーマは次のとおりです。未知のキー、存在しないファイル、
設計ディレクトリまたは`common/`以外を指すパスは処理開始前に拒否されます。

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
CLIの単体テスト、RTLシミュレーション、Gowinビルド、実機観測は別の検証です。
単体テストやシミュレーションのPASSだけでは実機動作を確認したことにはなりません。
PLLシミュレーションは動作モデル、SDRAMシミュレーションは範囲を縮小したモデルを使い、
実デバイスの電気特性や全容量の実機テストを代替しません。

## トラブルシュート

- `MISSING`: 対象ツールを`PATH`へ追加するか、上記の`TANG_*`環境変数を設定します。
- `python.exe`が起動しない: `python --version`と`Get-Command python`を確認します。
  Windowsのアプリ実行エイリアスが選択される場合は、実際のPythonのインストール先を
  `PATH`で優先してください。`py -3 --version`が使える場合は、
  `py -3 tools/fpga.py doctor`でも診断できます。
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

`001`〜`009`は実装済みです。今後の実験候補と検証方針は
[ロードマップ](docs/ROADMAP.md)を参照してください。

## ライセンスと貢献

本リポジトリのコード・ドキュメントは[MIT License](LICENSE)で公開します。
外部ツール・デバイスライブラリ・参考元の権利と利用条件はそれぞれの提供元に帰属します。
詳細は[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)を参照してください。

不具合報告や実験の追加は歓迎します。[CONTRIBUTING.md](CONTRIBUTING.md)に
検証手順、設計の追加方法、ログを共有する際の注意をまとめています。
メンテナー向けの[公開前チェック](docs/PUBLISHING.md)も用意しています。

## 参考資料

- [Sipeed Tang Primer 25K](https://wiki.sipeed.com/hardware/en/tang/tang-primer-25k/primer-25k.html)
- [Sipeed Tang Primer 25K examples](https://github.com/sipeed/TangPrimer-25K-example)
- [Sipeed Tang 40-pin SDRAM module](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html)
- [ZiyangYE / LicheeTang25k_SDRAM](https://github.com/ZiyangYE/LicheeTang25k_SDRAM)
- [Gowin Software Tcl Commands](https://www.gowinsemi.com/upload/database_doc/3262/document/68b8a001a6a92.pdf)
- [Gowin Programmer User Guide](https://cdn.gowinsemi.com.cn/SUG502E.pdf)
