# 008_sdram_burst

`b000`から`b007`までの8 wordを1回のSDRAM WRITE commandで送り、1回のREAD
commandで連続受信します。8 beatの値と連続性が正しければREADY LEDが点灯し、
不一致時はDONE LEDが点灯します。
