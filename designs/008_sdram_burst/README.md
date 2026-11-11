# 008_sdram_burst

`b000`から`b007`までの8 wordを1回の論理WRITE transactionで送り、1回の論理READ
transactionで連続受信します。実機側はSipeed公式例と同じBL1/CAS3を使い、8個の
連続word commandとして25 MHzで転送します。8 wordの値と連続性が正しければREADY LEDが点灯し、
不一致時はDONE LEDが点灯します。

テスト完了後、UART（115200 baud、8-N-1）へ判定と実際に読み戻した8 wordを
1行で出力します。正常時の出力は次のとおりです。

```text
TEST 008_sdram_burst ... PASS read=B000 B001 B002 B003 B004 B005 B006 B007
```

異常時も `FAIL read=...` の形式ですべての実測値を表示します。S1を押して離すと
テストとUART出力を再実行します。
