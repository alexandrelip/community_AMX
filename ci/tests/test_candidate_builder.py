import importlib.util
import json
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("candidate_builder", ROOT / "Tools/build_amxdenis.py")
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class BuilderTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="AMXDENIS-Builder-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def test_path_traversal_rejected(self):
        for path in ("../other", "a/../b", "a//b", ".git/config", ".GiT/config", "x:stream", "x.", "x ", "C:/outside", "/outside"):
            with self.subTest(path=path), self.assertRaises(ValueError):
                builder.within(self.root, path)

    def test_unknown_descriptor_probe_rejected_before_writes(self):
        candidate = self.root / "probe"
        with self.assertRaisesRegex(ValueError, "Unsupported mechanism"):
            builder.build(candidate, self.root / "unused-lua.exe", "replace-flight-model")
        self.assertFalse(candidate.exists())

    def test_installations_and_saved_games_rejected(self):
        for path in ("C:/", "C:/Windows/Temp/x", "D:/Program Files/DCS World/a", "C:/Users/any/Saved Games/DCS/x"):
            with self.subTest(path=path), self.assertRaises(ValueError):
                builder.safe(Path(path))

    def test_safe_relative_path(self):
        # Windows TEMP may use ALEXAN~1 while resolve() expands Alexandre. Both
        # sides of containment and the returned path use the canonical spelling.
        result = builder.within(self.root, "Scripts/Controls/data.lua")
        self.assertEqual(result, (self.root / "Scripts/Controls/data.lua").resolve())
        self.assertTrue(result.is_relative_to(self.root.resolve()))

    def test_copy_keeps_source_and_hash(self):
        source, target = self.root / "source.lua", self.root / "copy.lua"
        source.write_bytes(b"source\r\n")
        digest = builder.sha(source)
        builder.copy_verified(source, target, digest)
        self.assertEqual(builder.sha(source), digest)
        self.assertEqual(builder.sha(target), digest)

    def test_copy_refuses_changed_input_before_writing(self):
        source, target = self.root / "source.lua", self.root / "copy.lua"
        source.write_bytes(b"source")
        with self.assertRaises(ValueError):
            builder.copy_verified(source, target, "0" * 64)
        self.assertFalse(target.exists())

    def test_existing_copy_not_overwritten(self):
        source, target = self.root / "source.lua", self.root / "copy.lua"
        source.write_bytes(b"source")
        target.write_bytes(b"later work")
        with self.assertRaises(FileExistsError):
            builder.copy_verified(source, target)
        self.assertEqual(target.read_bytes(), b"later work")

    def test_existing_json_not_overwritten(self):
        target = self.root / "record.json"
        builder.write_json(target, {"a": 1})
        before = target.read_bytes()
        with self.assertRaises(FileExistsError):
            builder.write_json(target, {"a": 2})
        self.assertEqual(before, target.read_bytes())

    def test_literal_order_and_escaping(self):
        self.assertEqual(builder.lua_literal({"z": 2, "a": 1}), '{["a"]=1,["z"]=2}')
        self.assertEqual(builder.lua_literal('a"b\n'), '"a\\"b\\n"')

    def test_imported_selection_has_no_external_assets(self):
        manifest = builder.verify_reference(ROOT / builder.REFERENCE)
        self.assertFalse(manifest["ExternalModelsImported"])
        self.assertFalse(manifest["BinaryLibrariesImported"])
        for item in manifest["Files"]:
            self.assertNotIn(Path(item["Path"]).suffix.lower(), {".edm", ".lods", ".dll", ".miz"})
            self.assertEqual(builder.sha(ROOT / builder.REFERENCE / item["Path"]), item["SHA256"])

    def reference_fixture(self):
        root = self.root / "reference"
        root.mkdir()
        source = root / "Scripts/controls.lua"
        source.parent.mkdir()
        source.write_bytes(b"return {}\n")
        rows = [{"Path": "Scripts/controls.lua", "Bytes": source.stat().st_size, "SHA256": builder.sha(source)}]
        builder.write_json(root / "import-intent.json", {"Schema": "AMXDENIS_SOURCE_IMPORT_INTENT_1", "Files": rows})
        builder.write_json(root / "import-manifest.json", {"Schema": "AMXDENIS_SOURCE_IMPORT_1", "Files": rows,
            "DonorEntryExecuted": False, "ExternalModelsImported": False, "BinaryLibrariesImported": False})
        return root, source

    def test_changed_immutable_reference_rejected(self):
        root, source = self.reference_fixture()
        builder.verify_reference(root)
        source.write_bytes(b"changed after the frozen manifest\n")
        with self.assertRaisesRegex(ValueError, "Immutable reference changed"):
            builder.verify_reference(root)

    def test_manifest_cannot_silently_change_selection(self):
        root, _ = self.reference_fixture()
        path = root / "import-manifest.json"
        manifest = builder.load(path)
        manifest["Files"] = []
        path.write_text(json.dumps(manifest), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "authorized selection"):
            builder.verify_reference(root)

    def test_reference_cannot_authorize_donor_entry(self):
        root, _ = self.reference_fixture()
        path = root / "import-manifest.json"
        manifest = builder.load(path)
        manifest["DonorEntryExecuted"] = True
        path.write_text(json.dumps(manifest), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "authorized selection"):
            builder.verify_reference(root)

    def test_output_must_be_new_and_inside_candidate_area(self):
        with patch.dict(os.environ, {"LOCALAPPDATA": str(self.root)}):
            allowed = self.root / "AMXDENIS-Integration/Candidates/example"
            self.assertEqual(builder.candidate_destination(allowed), allowed.resolve())
            allowed.mkdir(parents=True)
            with self.assertRaises(ValueError):
                builder.candidate_destination(allowed)
            for path in (ROOT / "candidate", self.root / "source/candidate", allowed / "nested"):
                with self.subTest(path=path), self.assertRaises(ValueError):
                    builder.candidate_destination(path)

    def test_linked_ancestor_rejected_before_resolution(self):
        # Exercise both link-detection branches without requiring Windows symlink privileges.
        for method in ("is_junction", "is_symlink"):
            with self.subTest(method=method), patch.object(Path, method, return_value=True), self.assertRaisesRegex(ValueError, "Linked path refused"):
                builder.safe(self.root / "parent/child")


if __name__ == "__main__":
    unittest.main(verbosity=2)