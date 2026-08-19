# 006_sdram_init

Tang 40-pin SDRAMモジュールの2チップに対し、200 us待機、全bank precharge、
8回auto-refresh、BL8/CAS 2のmode register設定を順に実行します。READY LEDが
点灯すれば初期化完了です。S1を押すとコントローラを再初期化します。
