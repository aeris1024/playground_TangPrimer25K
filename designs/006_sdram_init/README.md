# 006_sdram_init

Tang 40-pin SDRAMモジュールの2チップに対し、200 us待機、全bank precharge、
8回auto-refresh、BL1/CAS3のmode register設定を50 MHzで順に実行します。初期化完了後は
READY/DONE LEDが点灯します。S1を押すとコントローラを再初期化します。
