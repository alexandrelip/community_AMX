import hashlib
import importlib.util
import sys
import tempfile
import unittest
from dataclasses import dataclass
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[2] / "Tools" / "Inspect-AMXDENISCockpit.py"
SPEC = importlib.util.spec_from_file_location("cockpit_inventory", SCRIPT)
inventory = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(inventory)


@dataclass
class Node:
    name: str = "fixture"
    parent_idx: int = -1


class InventoryTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="AMXDENIS-Inventory-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.model = self.root / "model.edm"
        self.model.write_bytes(b"inventory fixture, not a real EDM")
        self.digest = hashlib.sha256(self.model.read_bytes()).hexdigest().upper()
        self.parser = self.root / "parser"
        self.parser.mkdir()
        for name in ("__init__.py", "parser.py", "reader.py", "types.py"):
            (self.parser / name).write_text("fixture", encoding="utf-8")
        self.model_data = SimpleNamespace(
            version=10, nodes=[Node()], render_nodes=[], shell_nodes=[],
            connectors=[SimpleNamespace(name="HUD", parent=0), SimpleNamespace(name="HUD", parent=0)],
            root=SimpleNamespace(materials=[SimpleNamespace(
                name="fixture", material_name="def_material",
                textures=[SimpleNamespace(index=0, name="unavailable")])]),
        )

    def inspect(self, *, remaining=0, diagnostic="", recover=False):
        model_data = self.model_data

        class Parser:
            def __init__(self, stream):
                self.r = SimpleNamespace(remaining=lambda: remaining)

            def parse(self):
                if diagnostic:
                    print(diagnostic)
                if recover:
                    self._try_resync_to(("model::RenderNode",))
                return model_data

        with patch.object(inventory, "load_parser", return_value=SimpleNamespace(EDMFileParser=Parser)):
            return inventory.inspect_model(self.model, self.parser, self.digest, [])

    def test_identity_checked_before_loading_parser(self):
        with patch.object(inventory, "load_parser") as loader:
            with self.assertRaisesRegex(ValueError, "approved input hash"):
                inventory.inspect_model(self.model, self.parser, "0" * 64, [])
            loader.assert_not_called()
        self.assertEqual(self.digest, hashlib.sha256(self.model.read_bytes()).hexdigest().upper())

    def test_structured_inventory_does_not_grant_native_or_permission_approval(self):
        result = self.inspect()
        self.assertEqual(result["missing_textures"], ["unavailable"])
        self.assertEqual(result["duplicate_connectors"], {"HUD": 2})
        self.assertFalse(result["native_validated"])
        self.assertFalse(result["permissions_validated"])
        self.assertEqual(len(result["parser_files"]), 4)

    def test_unconsumed_bytes_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "incomplete"):
            self.inspect(remaining=1)

    def test_parser_diagnostic_is_not_silently_accepted(self):
        with self.assertRaisesRegex(ValueError, "incomplete"):
            self.inspect(diagnostic="partial parse")

    def test_parser_recovery_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Partial/recovered"):
            self.inspect(recover=True)

    def test_cyclic_connector_ancestry_is_rejected(self):
        self.model_data.nodes[0].parent_idx = 0
        with self.assertRaisesRegex(ValueError, "ancestry"):
            self.inspect()

    def test_existing_report_is_not_overwritten(self):
        report = self.root / "previous.json"
        report.write_text("preserve", encoding="utf-8")
        arguments = [str(SCRIPT), "--model", str(self.model), "--parser", str(self.parser),
                     "--expected-sha256", self.digest, "--report", str(report)]
        with patch.object(sys, "argv", arguments), patch.object(inventory, "inspect_model") as inspect:
            with self.assertRaisesRegex(ValueError, "new file"):
                inventory.main()
            inspect.assert_not_called()
        self.assertEqual(report.read_text(encoding="utf-8"), "preserve")

    def test_report_cannot_be_written_beside_model(self):
        report = self.root / "new.json"
        arguments = [str(SCRIPT), "--model", str(self.model), "--parser", str(self.parser),
                     "--expected-sha256", self.digest, "--report", str(report)]
        with patch.object(sys, "argv", arguments):
            with self.assertRaisesRegex(ValueError, "outside input"):
                inventory.main()
        self.assertFalse(report.exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)