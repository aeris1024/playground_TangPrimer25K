# 007_sdram_bist

固定値4種、walking-one 16種、word address由来パターンの順でwrite/read/compareを
実行します。既定の`TOTAL_BURSTS=4194304`は8 word単位で64 MB全域です。実機で
確認済みの25 MHz、BL1/CAS3 backendを使用します。READY LEDはPASS、DONE LEDは
FAILを示します。S1で再実行できます。
