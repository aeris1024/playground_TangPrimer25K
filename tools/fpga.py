#!/usr/bin/env python3
"""CLI for the Tang Primer 25K FPGA playground."""

from __future__ import annotations

import argparse
import dataclasses
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tomllib
from typing import Iterable, Mapping, Sequence


ROOT = Path(__file__).resolve().parents[1]
DESIGNS_DIR = ROOT / "designs"
BOARDS_DIR = ROOT / "boards"
BUILD_DIR = ROOT / "build"

DESIGN_KEYS = {"name", "board", "top", "sources", "constraints", "testbench"}
BOARD_KEYS = {"name", "device", "clock_hz", "programmer_board"}


class FpgaError(RuntimeError):
    """Expected user-facing CLI failure."""


@dataclasses.dataclass(frozen=True)
class Board:
    name: str
    device: str
    clock_hz: int
    programmer_board: str
    manifest: Path


@dataclasses.dataclass(frozen=True)
class Design:
    name: str
    board_name: str
    top: str
    sources: tuple[Path, ...]
    constraints: tuple[Path, ...]
    testbench: Path
    manifest: Path


@dataclasses.dataclass(frozen=True)
class ToolSpec:
    label: str
    env_var: str | None
    commands: tuple[str, ...]


TOOLS = {
    "gowin": ToolSpec("Gowin shell", "TANG_GOWIN_SH", ("gw_sh.exe", "gw_sh")),
    "openfpgaloader": ToolSpec(
        "openFPGALoader", "TANG_OPENFPGALOADER", ("openFPGALoader.exe", "openFPGALoader")
    ),
    "iverilog": ToolSpec("Icarus Verilog", "TANG_IVERILOG", ("iverilog.exe", "iverilog")),
    "vvp": ToolSpec("Icarus runtime", None, ("vvp.exe", "vvp")),
}


def _read_toml(path: Path) -> dict[str, object]:
    try:
        with path.open("rb") as stream:
            return tomllib.load(stream)
    except FileNotFoundError as exc:
        raise FpgaError(f"Configuration file not found: {path}") from exc
    except tomllib.TOMLDecodeError as exc:
        raise FpgaError(f"Invalid TOML in {path}: {exc}") from exc


def _required_string(data: Mapping[str, object], key: str, path: Path) -> str:
    value = data.get(key)
    if not isinstance(value, str) or not value.strip():
        raise FpgaError(f"{path}: '{key}' must be a non-empty string")
    return value


def _string_list(data: Mapping[str, object], key: str, path: Path) -> tuple[str, ...]:
    value = data.get(key)
    if not isinstance(value, list) or not value or not all(isinstance(item, str) and item for item in value):
        raise FpgaError(f"{path}: '{key}' must be a non-empty list of strings")
    return tuple(value)


def _reject_unknown(data: Mapping[str, object], allowed: set[str], path: Path) -> None:
    unknown = sorted(set(data) - allowed)
    if unknown:
        raise FpgaError(f"{path}: unknown key(s): {', '.join(unknown)}")


def _resolve_files(base: Path, entries: Iterable[str], manifest: Path) -> tuple[Path, ...]:
    resolved: list[Path] = []
    for entry in entries:
        candidate = (base / entry).resolve()
        try:
            candidate.relative_to(base.resolve())
        except ValueError as exc:
            raise FpgaError(f"{manifest}: path escapes the design directory: {entry}") from exc
        if not candidate.is_file():
            raise FpgaError(f"{manifest}: referenced file not found: {entry}")
        resolved.append(candidate)
    return tuple(resolved)


def load_board(name: str, root: Path = ROOT) -> Board:
    manifest = root / "boards" / name / "board.toml"
    data = _read_toml(manifest)
    _reject_unknown(data, BOARD_KEYS, manifest)
    clock_hz = data.get("clock_hz")
    if not isinstance(clock_hz, int) or isinstance(clock_hz, bool) or clock_hz <= 0:
        raise FpgaError(f"{manifest}: 'clock_hz' must be a positive integer")
    board = Board(
        name=_required_string(data, "name", manifest),
        device=_required_string(data, "device", manifest),
        clock_hz=clock_hz,
        programmer_board=_required_string(data, "programmer_board", manifest),
        manifest=manifest,
    )
    if board.name != name:
        raise FpgaError(f"{manifest}: board name '{board.name}' does not match directory '{name}'")
    return board


def load_design(manifest: Path, root: Path = ROOT) -> Design:
    data = _read_toml(manifest)
    _reject_unknown(data, DESIGN_KEYS, manifest)
    base = manifest.parent.resolve()
    sources = _resolve_files(base, _string_list(data, "sources", manifest), manifest)
    constraints = _resolve_files(base, _string_list(data, "constraints", manifest), manifest)
    testbench_entry = _required_string(data, "testbench", manifest)
    testbench = _resolve_files(base, (testbench_entry,), manifest)[0]
    design = Design(
        name=_required_string(data, "name", manifest),
        board_name=_required_string(data, "board", manifest),
        top=_required_string(data, "top", manifest),
        sources=sources,
        constraints=constraints,
        testbench=testbench,
        manifest=manifest,
    )
    if design.name != manifest.parent.name:
        raise FpgaError(
            f"{manifest}: design name '{design.name}' does not match directory '{manifest.parent.name}'"
        )
    load_board(design.board_name, root)
    return design


def discover_designs(root: Path = ROOT) -> dict[str, Design]:
    manifests = sorted((root / "designs").glob("*/design.toml"))
    designs: dict[str, Design] = {}
    for manifest in manifests:
        design = load_design(manifest, root)
        if design.name in designs:
            raise FpgaError(f"Duplicate design name '{design.name}' in {manifest}")
        designs[design.name] = design
    return designs


def get_design(name: str, root: Path = ROOT) -> Design:
    designs = discover_designs(root)
    try:
        return designs[name]
    except KeyError as exc:
        choices = ", ".join(designs) if designs else "none"
        raise FpgaError(f"Unknown design '{name}'. Available designs: {choices}") from exc


def _existing_executable(value: str | os.PathLike[str]) -> Path | None:
    candidate = Path(value).expanduser()
    if candidate.is_file():
        return candidate.resolve()
    found = shutil.which(str(value))
    return Path(found).resolve() if found else None


def _gowin_fallbacks() -> Iterable[Path]:
    roots = (Path("C:/Gowin"), Path("C:/Program Files/Gowin"), Path("C:/Program Files (x86)/Gowin"))
    for root in roots:
        if root.is_dir():
            yield from sorted(root.glob("**/IDE/bin/gw_sh.exe"), reverse=True)


def resolve_tool(key: str, environ: Mapping[str, str] | None = None) -> Path | None:
    environ = os.environ if environ is None else environ
    spec = TOOLS[key]
    if spec.env_var and environ.get(spec.env_var):
        return _existing_executable(environ[spec.env_var])
    for command in spec.commands:
        resolved = _existing_executable(command)
        if resolved:
            return resolved
    if key == "gowin":
        return next((path.resolve() for path in _gowin_fallbacks() if path.is_file()), None)
    if key == "vvp":
        iverilog = resolve_tool("iverilog", environ)
        if iverilog:
            sibling = iverilog.with_name("vvp.exe" if os.name == "nt" else "vvp")
            if sibling.is_file():
                return sibling.resolve()
    return None


def require_tool(key: str) -> Path:
    path = resolve_tool(key)
    if path:
        return path
    spec = TOOLS[key]
    hint = f" Set {spec.env_var} or add it to PATH." if spec.env_var else " Add it to PATH."
    raise FpgaError(f"{spec.label} was not found.{hint} Run '.\\fpga.ps1 doctor' for details.")


def tcl_quote(path: Path | str) -> str:
    text = str(path).replace("\\", "/").replace("}", "\\}")
    return "{" + text + "}"


def generate_gowin_tcl(design: Design, board: Board, output_dir: Path) -> str:
    project_dir = output_dir / "gowin_project"
    lines = [
        "# Generated by tools/fpga.py; do not edit.",
        f"create_project -name {design.name} -dir {tcl_quote(project_dir)} -pn {tcl_quote(board.device)}",
    ]
    for source in design.sources:
        lines.append(f"import_files -file {tcl_quote(source)}")
    for constraint in design.constraints:
        lines.append(f"import_files -file {tcl_quote(constraint)}")
    lines.extend(
        [
            f"set_option -top_module {tcl_quote(design.top)}",
            "set_option -verilog_std sysv2017",
            "run all",
        ]
    )
    return "\n".join(lines) + "\n"


def program_command(executable: Path, board: Board, bitstream: Path, flash: bool) -> list[str]:
    command = [str(executable), "-b", board.programmer_board]
    if flash:
        command.append("-f")
    command.append(str(bitstream))
    return command


def _run(command: Sequence[str], cwd: Path, log: Path | None = None, timeout: int | None = None) -> int:
    try:
        result = subprocess.run(
            list(command), cwd=cwd, text=True, capture_output=True, timeout=timeout, check=False
        )
    except subprocess.TimeoutExpired as exc:
        raise FpgaError(f"Command timed out after {timeout} seconds: {command[0]}") from exc
    output = (result.stdout or "") + (result.stderr or "")
    if log:
        log.parent.mkdir(parents=True, exist_ok=True)
        log.write_text(output, encoding="utf-8", errors="replace")
    if output:
        print(output, end="" if output.endswith("\n") else "\n")
    return result.returncode


def command_list(_: argparse.Namespace) -> int:
    designs = discover_designs()
    if not designs:
        print("No designs found.")
        return 0
    for design in designs.values():
        print(f"{design.name}\tboard={design.board_name}\ttop={design.top}")
    return 0


def _version(path: Path, arguments: Sequence[str]) -> str:
    try:
        result = subprocess.run(
            [str(path), *arguments], text=True, capture_output=True, timeout=10, check=False
        )
    except (OSError, subprocess.TimeoutExpired):
        return "version unavailable"
    output = ((result.stdout or "") + (result.stderr or "")).strip().splitlines()
    return output[0] if output else "version unavailable"


def command_doctor(_: argparse.Namespace) -> int:
    board = load_board("tang_primer_25k")
    print(f"Python\tOK\t{sys.version.split()[0]}\t{Path(sys.executable).resolve()}")
    print(f"Board\tOK\t{board.device}\tclock={board.clock_hz} Hz")
    missing = False
    resolved: dict[str, Path] = {}
    version_args = {"gowin": ("-version",), "openfpgaloader": ("--version",), "iverilog": ("-V",), "vvp": ("-V",)}
    for key in ("gowin", "openfpgaloader", "iverilog", "vvp"):
        path = resolve_tool(key)
        if path:
            resolved[key] = path
            print(f"{TOOLS[key].label}\tOK\t{path}\t{_version(path, version_args[key])}")
        else:
            missing = True
            env_hint = f" ({TOOLS[key].env_var})" if TOOLS[key].env_var else ""
            print(f"{TOOLS[key].label}\tMISSING\tinstall it or configure PATH{env_hint}")

    loader = resolved.get("openfpgaloader")
    if loader:
        print(f"Hardware\tCHECK\tprobing {board.programmer_board}...")
        result = _run(
            [str(loader), "-b", board.programmer_board, "--detect"], ROOT, timeout=15
        )
        if result != 0:
            print("Hardware\tFAIL\tconnect the Dock directly by USB and check its driver/firmware")
            missing = True
        else:
            print("Hardware\tOK\tJTAG device detected")
    else:
        print("Hardware\tSKIP\topenFPGALoader is unavailable")
    return 1 if missing else 0


def command_sim(args: argparse.Namespace) -> int:
    design = get_design(args.design)
    iverilog = require_tool("iverilog")
    vvp = require_tool("vvp")
    output_dir = BUILD_DIR / design.name / "sim"
    output_dir.mkdir(parents=True, exist_ok=True)
    executable = output_dir / "simulation.vvp"
    compile_command = [str(iverilog), "-g2012", "-o", str(executable)]
    compile_command.extend(str(path) for path in design.sources)
    compile_command.append(str(design.testbench))
    if _run(compile_command, ROOT, output_dir / "compile.log") != 0:
        raise FpgaError(f"Simulation compile failed; see {output_dir / 'compile.log'}")
    if _run([str(vvp), str(executable)], ROOT, output_dir / "run.log") != 0:
        raise FpgaError(f"Simulation failed; see {output_dir / 'run.log'}")
    return 0


def command_build(args: argparse.Namespace) -> int:
    design = get_design(args.design)
    board = load_board(design.board_name)
    gowin = require_tool("gowin")
    output_dir = BUILD_DIR / design.name
    output_dir.mkdir(parents=True, exist_ok=True)
    script = output_dir / "build.tcl"
    script.write_text(generate_gowin_tcl(design, board, output_dir), encoding="utf-8")
    log = output_dir / "build.log"
    if _run([str(gowin), str(script)], output_dir, log) != 0:
        raise FpgaError(f"Gowin build failed; see {log}")

    stable_bitstream = output_dir / f"{design.name}.fs"
    candidates = [path for path in output_dir.rglob("*.fs") if path != stable_bitstream]
    if not candidates:
        raise FpgaError(f"Gowin completed but produced no .fs bitstream; see {log}")
    generated = max(candidates, key=lambda path: path.stat().st_mtime_ns)
    shutil.copy2(generated, stable_bitstream)
    print(f"BITSTREAM\t{stable_bitstream}")
    print(f"BUILD LOG\t{log}")
    return 0


def command_program(args: argparse.Namespace) -> int:
    design = get_design(args.design)
    board = load_board(design.board_name)
    bitstream = BUILD_DIR / design.name / f"{design.name}.fs"
    if not bitstream.is_file():
        raise FpgaError(
            f"Bitstream not found: {bitstream}. Run '.\\fpga.ps1 build {design.name}' first."
        )
    loader = require_tool("openfpgaloader")
    mode = "FLASH" if args.flash else "SRAM"
    print(f"PROGRAM MODE\t{mode}")
    log = BUILD_DIR / design.name / "program.log"
    result = _run(program_command(loader, board, bitstream, args.flash), ROOT, log)
    if result != 0:
        raise FpgaError(
            f"Programming failed; see {log}. Check the USB cable, Dock firmware, and Windows driver."
        )
    return 0


def clean_outputs(build_dir: Path, design_name: str | None, clean_all: bool) -> list[Path]:
    build_root = build_dir.resolve()
    targets = [build_root] if clean_all else [build_root / str(design_name)]
    removed: list[Path] = []
    for target in targets:
        resolved = target.resolve()
        if not clean_all:
            try:
                resolved.relative_to(build_root)
            except ValueError as exc:
                raise FpgaError(f"Refusing to clean outside build directory: {resolved}") from exc
            if resolved == build_root:
                raise FpgaError("Refusing to remove the build root without --all")
        if resolved.exists():
            shutil.rmtree(resolved)
            removed.append(resolved)
    if clean_all:
        build_root.mkdir(parents=True, exist_ok=True)
        (build_root / ".gitkeep").touch()
    return removed


def command_clean(args: argparse.Namespace) -> int:
    if args.all:
        if args.design:
            raise FpgaError("Specify either a design or --all, not both")
    elif not args.design:
        raise FpgaError("Specify a design or use --all")
    elif args.design not in discover_designs():
        raise FpgaError(f"Unknown design '{args.design}'")
    removed = clean_outputs(BUILD_DIR, args.design, args.all)
    if removed:
        for path in removed:
            print(f"REMOVED\t{path}")
    else:
        print("Nothing to clean.")
    return 0


def make_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    list_parser = subparsers.add_parser("list", help="list available designs")
    list_parser.set_defaults(handler=command_list)

    doctor_parser = subparsers.add_parser("doctor", help="diagnose tools and connected hardware")
    doctor_parser.set_defaults(handler=command_doctor)

    for name, help_text, handler in (
        ("sim", "simulate a design with Icarus Verilog", command_sim),
        ("build", "build a design with Gowin EDA", command_build),
    ):
        command_parser = subparsers.add_parser(name, help=help_text)
        command_parser.add_argument("design")
        command_parser.set_defaults(handler=handler)

    program_parser = subparsers.add_parser("program", help="program a generated bitstream")
    program_parser.add_argument("design")
    program_parser.add_argument(
        "--flash", action="store_true", help="write non-volatile flash instead of volatile SRAM"
    )
    program_parser.set_defaults(handler=command_program)

    clean_parser = subparsers.add_parser("clean", help="remove generated build files")
    clean_parser.add_argument("design", nargs="?")
    clean_parser.add_argument("--all", action="store_true", help="remove all generated build files")
    clean_parser.set_defaults(handler=command_clean)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = make_parser()
    args = parser.parse_args(argv)
    try:
        return int(args.handler(args))
    except FpgaError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("ERROR: interrupted", file=sys.stderr)
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
