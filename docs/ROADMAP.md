# ロードマップ

学習・検証のための実験候補です。実装予定や提供時期を保証するものではありません。
設計の正規の一覧は各`design.toml`からCLIが取得します。

## 実装済み

「実装済み」はRTLと自己検証testbenchが存在することを示します。
ツールバージョンごとのビルド成功や、すべての環境での実機動作を示すものではありません。

| 設計 | テーマ |
| --- | --- |
| [001_blink](../designs/001_blink/README.md) | クロック、カウンタ、LED |
| [002_button](../designs/002_button/README.md) | ボタン入力、LED出力 |
| [003_uart_tx](../designs/003_uart_tx/README.md) | UART送信 |
| [004_pll](../designs/004_pll/README.md) | PLL、LOCK、クロック生成 |
| [005_bram](../designs/005_bram/README.md) | 同期RAM、BSRAM推論、BIST |
| [006_sdram_init](../designs/006_sdram_init/README.md) | SDRAM初期化、refresh |
| [007_sdram_bist](../designs/007_sdram_bist/README.md) | SDRAM全容量BIST |
| [008_sdram_burst](../designs/008_sdram_burst/README.md) | 8 word transaction、読み戻し値の表示 |
| [009_sdram_uart](../designs/009_sdram_uart/README.md) | BIST結果のUARTレポート |

## 実験候補

- FIFO、SPI、I2S
- DDS、FIR/IIR、FFT
- DMA、softcore
- 実験用Yosys + nextpnr-gowin + Apicula backend（現在のCLIは未対応）

## 継続して改善すること

- 各設計の再現手順と観測方法を揃える
- ツールバージョンと検証範囲を明示して動作報告を蓄積する
- board固有の検証ができるまでFlash書き込みは有効化しない
