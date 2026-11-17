# 外部ツール・参考元

このリポジトリの[MIT License](LICENSE)は、外部ツール、デバイスライブラリ、
ハードウェア設計資料や参考元のコードを再ライセンスするものではありません。

## 別途インストールするツール

- Gowin EDA / Gowin Programmer: Gowinの配布条件に従って取得・使用してください。
  インストーラー、ライセンスファイル、ベンダーのデバイスライブラリは同梱しません。
  `004_pll`の合成は、インストール済みGowin環境の`PLLA`プリミティブを使用します。
- Icarus Verilog: `iverilog`と`vvp`を別途インストールします。
  本リポジトリには実行ファイルを同梱しません。
- Python: 3.11以上を別途インストールします。追加のPythonパッケージは不要です。

## ハードウェア・実装上の参考資料

| 参考元 | このプロジェクトでの参照箇所 |
| --- | --- |
| [Sipeed Tang Primer 25K](https://wiki.sipeed.com/hardware/en/tang/tang-primer-25k/primer-25k.html) | Core / Dockの構成とセットアップ |
| [Sipeed TangPrimer-25K-example](https://github.com/sipeed/TangPrimer-25K-example) | ボードのピン割り当て・制約 |
| [Sipeed Tang PMOD](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html) | Tang 40-pin SDRAMモジュール |
| [ZiyangYE/LicheeTang25k_SDRAM](https://github.com/ZiyangYE/LicheeTang25k_SDRAM) | SDRAMのBL1/CAS3構成・動作方式の参考 |
| [Gowin Software Tcl Commands](https://www.gowinsemi.com/upload/database_doc/3262/document/68b8a001a6a92.pdf) | CLIで生成するビルドTcl |
| [Gowin Programmer User Guide](https://cdn.gowinsemi.com.cn/SUG502E.pdf) | SRAM書き込みの操作 |

上記は参考資料の一覧です。リンク先の内容全体を本リポジトリに含めるものではありません。
外部コードをコピー・改変して追加する際は、参考リンクだけで済ませず、
そのコードに適用されるライセンスと著作権表示を確認し、必要な通知を同梱してください。

Tang Primer、Gowin等の製品名・商標は各権利者に帰属します。
このプロジェクトは各社の公式提供・認定を示すものではありません。
