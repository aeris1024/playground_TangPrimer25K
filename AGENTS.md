# Agent instructions

This repository is a hardware playground for the Tang Primer 25K. Keep each
experiment self-contained under `designs/<name>` and use `design.toml` as the
only public design-discovery interface.

## Required workflow

Run commands in this order and stop on the first failure:

```powershell
.\fpga.ps1 doctor
.\fpga.ps1 sim <design>
.\fpga.ps1 build <design>
.\fpga.ps1 program <design>
```

- Prefer CLI output and logs over driving the Gowin GUI.
- Never use `program --flash` unless the user explicitly requests persistent
  programming. Normal validation uses volatile SRAM.
- Do not claim hardware success without a successful programmer exit and a
  user-observed LED/UART/result signal.
- Treat missing external tools or disconnected hardware as an environment
  failure, not an RTL failure.
- Generated files belong under `build/` and must not be committed.
- Only promote RTL into `common/` after at least two designs use it.
- Add a self-checking testbench and machine-readable PASS/FAIL output for every
  design where simulation is meaningful.
- Update `README.md` and the roadmap when adding a numbered design.

Run the CLI unit tests after changing manifests or tooling:

```powershell
python -m unittest discover -s tests -v
```
