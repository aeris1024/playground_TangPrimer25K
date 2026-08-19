# 007_sdram_bist

固定値4種、walking-one 16種、word address由来パターンの順でwrite/read/compareを
実行します。既定の`TOTAL_BURSTS=4194304`はBL8で64 MB全域です。READY LEDはPASS、
DONE LEDはFAILを示します。S1で再実行できます。
