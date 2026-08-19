from __future__ import annotations

import importlib.util
import os
from pathlib import Path
import stat
import sys
import tempfile
import unittest


MODULE_PATH = Path(__file__).resolve().parents[1] / "tools" / "fpga.py"
SPEC = importlib.util.spec_from_file_location("fpga_cli", MODULE_PATH)
assert SPEC and SPEC.loader
fpga = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = fpga
SPEC.loader.exec_module(fpga)


class FpgaCliTests(unittest.TestCase):
    def make_project(self, root: Path, *, extra_design_key: str = "") -> None:
        board_dir = root / "boards" / "test_board"
        design_dir = root / "designs" / "001_test"
        (design_dir / "rtl").mkdir(parents=True)
        (design_dir / "constraints").mkdir()
        (design_dir / "sim").mkdir()
        board_dir.mkdir(parents=True)
        (board_dir / "board.toml").write_text(
            'name = "test_board"\ndevice = "TEST-PART"\ndevice_version = "A"\n'
            'clock_hz = 100\nprogrammer_device = "TEST-DEVICE"\n'
            'programmer_cable = "USB Debugger A"\nprogrammer_cable_index = 4\n'
            'use_sspi_as_gpio = false\nuse_cpu_as_gpio = false\n',
            encoding="utf-8",
        )
        (design_dir / "rtl" / "top.sv").write_text("module top; endmodule\n", encoding="utf-8")
        (design_dir / "constraints" / "top.cst").write_text("// test\n", encoding="utf-8")
        (design_dir / "sim" / "tb.sv").write_text("module tb; endmodule\n", encoding="utf-8")
        (design_dir / "design.toml").write_text(
            'name = "001_test"\nboard = "test_board"\ntop = "top"\n'
            'sources = ["rtl/top.sv"]\nconstraints = ["constraints/top.cst"]\n'
            f'testbench = "sim/tb.sv"\n{extra_design_key}',
            encoding="utf-8",
        )

    def test_repository_manifest_loads(self) -> None:
        designs = fpga.discover_designs(MODULE_PATH.parents[1])
        self.assertIn("001_blink", designs)
        self.assertEqual(designs["001_blink"].top, "top")

    def test_unknown_manifest_key_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_project(root, extra_design_key='unexpected = true\n')
            with self.assertRaisesRegex(fpga.FpgaError, "unknown key"):
                fpga.discover_designs(root)

    def test_missing_referenced_file_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.make_project(root)
            (root / "designs" / "001_test" / "rtl" / "top.sv").unlink()
            with self.assertRaisesRegex(fpga.FpgaError, "referenced file not found"):
                fpga.discover_designs(root)

    def test_environment_tool_override_has_priority(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            executable = Path(directory) / "custom-gw_sh.exe"
            executable.touch()
            resolved = fpga.resolve_tool("gowin", {"TANG_GOWIN_SH": str(executable), "PATH": ""})
            self.assertEqual(resolved, executable.resolve())

    def test_tcl_quote_normalizes_windows_paths(self) -> None:
        self.assertEqual(fpga.tcl_quote(r"C:\Program Files\Gowin\file.sv"), "{C:/Program Files/Gowin/file.sv}")

    def test_generated_tcl_contains_sources_and_device(self) -> None:
        design = fpga.get_design("001_blink")
        board = fpga.load_board(design.board_name)
        text = fpga.generate_gowin_tcl(design, board, Path("C:/build folder"))
        self.assertIn(board.device, text)
        self.assertIn("-device_version {A}", text)
        self.assertIn("set_option -use_sspi_as_gpio 1", text)
        self.assertIn("set_option -use_cpu_as_gpio 1", text)
        self.assertIn("import_files -file", text)
        self.assertIn("run all", text)
        self.assertIn("{C:/build folder/gowin_project}", text)

    def test_program_command_uses_gowin_sram_mode(self) -> None:
        board = fpga.load_board("tang_primer_25k")
        command = fpga.program_command(
            Path("programmer_cli.exe"), board, Path("blink.fs"), "201745"
        )
        self.assertEqual(
            command,
            [
                "programmer_cli.exe",
                "--device",
                "GW5A-25A",
                "--run",
                "2",
                "--fsFile",
                "blink.fs",
                "--cable-index",
                "4",
                "--location",
                "201745",
            ],
        )

    def test_programmer_locations_are_filtered_and_sorted(self) -> None:
        output = (
            " Cable found:  USB Debugger A/0/201746/null (USB location:201746)\n"
            " Cable found:  Other Cable/0/10/null (USB location:10)\n"
            " Cable found:  USB Debugger A/1/201745/null (USB location:201745)\n"
        )
        self.assertEqual(
            fpga._parse_programmer_locations(output, "USB Debugger A"),
            ["201745", "201746"],
        )

    def test_targeted_clean_preserves_other_designs(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            build = Path(directory) / "build"
            first = build / "001_first"
            second = build / "002_second"
            first.mkdir(parents=True)
            second.mkdir()
            (first / "result.fs").touch()
            (second / "result.fs").touch()
            os.chmod(first / "result.fs", stat.S_IREAD)
            removed = fpga.clean_outputs(build, "001_first", False)
            self.assertEqual(removed, [first.resolve()])
            self.assertFalse(first.exists())
            self.assertTrue(second.exists())

    def test_clean_all_recreates_build_marker(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            build = Path(directory) / "build"
            (build / "001_first").mkdir(parents=True)
            fpga.clean_outputs(build, None, True)
            self.assertTrue((build / ".gitkeep").is_file())


if __name__ == "__main__":
    unittest.main()
