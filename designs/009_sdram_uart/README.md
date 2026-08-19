# 009_sdram_uart

`007_sdram_bist`と同じ64 MB全域BISTを実行し、オンボードUSB-UARTへ115200 baud、
8N1で結果を1行送ります。

```text
TEST 009_sdram_uart ... PASS errors=0x00000000 first=0x0000000
```

FAIL時も同じ形式でエラー数と最初のword addressを16進表示します。
