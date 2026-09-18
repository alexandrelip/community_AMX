import argparse
import contextlib
import hashlib
import importlib.util
import io
import json
import sys
from dataclasses import asdict
from pathlib import Path

sys.dont_write_bytecode = True


def checked_path(path):
    absolute = path.absolute()
    for component in (absolute, *absolute.parents):
        if component.is_symlink() or component.is_junction():
            raise ValueError(f"Linked paths are not allowed: {component}")
    return absolute.resolve()


def load_parser(directory):
    directory = checked_path(directory)
    specification = importlib.util.spec_from_file_location(
        "amxdenis_edm", directory / "__init__.py",
        submodule_search_locations=[str(directory)],
    )
    if specification is None or specification.loader is None:
        raise ValueError("The standalone EDM parser could not be located")
    module = importlib.util.module_from_spec(specification)
    sys.modules[specification.name] = module
    specification.loader.exec_module(module)
    return module


def inspect_model(model_path, parser_directory, expected_sha256, texture_roots):
    model_path = checked_path(model_path)
    original = model_path.read_bytes()
    digest = hashlib.sha256(original).hexdigest().upper()
    if digest != expected_sha256.upper():
        raise ValueError("Cockpit model differs from the approved input hash")
    parser_module = load_parser(parser_directory)

    class StrictParser(parser_module.EDMFileParser):
        def _try_resync_to(self, *arguments, **keywords):
            raise ValueError("Partial/recovered EDM parsing is not accepted")

    diagnostics = io.StringIO()
    with contextlib.redirect_stdout(diagnostics):
        parser = StrictParser(io.BytesIO(original))
        model = parser.parse()
    if diagnostics.getvalue() or parser.r.remaining() != 0:
        raise ValueError("EDM inventory is incomplete: " + diagnostics.getvalue())
    materials = [
        {"index": index, "name": material.name, "shader": material.material_name,
         "textures": [{"slot": texture.index, "name": texture.name}
                      for texture in material.textures]}
        for index, material in enumerate(model.root.materials)
    ]
    connectors = []
    for connector in model.connectors:
        chain = []
        visited = set()
        parent = connector.parent
        while parent >= 0:
            if parent in visited or parent >= len(model.nodes):
                raise ValueError("Invalid connector ancestry")
            visited.add(parent)
            node = model.nodes[parent]
            chain.append({"index": parent, "node": asdict(node)})
            parent = node.parent_idx
        connectors.append({"name": connector.name, "parent": connector.parent,
                           "ancestry": chain})
    images = {}
    for root in texture_roots:
        root = checked_path(root)
        if not root.is_dir():
            raise ValueError(f"Missing texture source directory: {root}")
        for path in sorted(root.rglob("*")):
            if path.is_symlink() or path.is_junction():
                raise ValueError(f"Texture discovery refuses links: {path}")
            if path.is_file() and path.suffix.lower() in {
                ".dds", ".png", ".bmp", ".tga", ".jpg", ".jpeg",
            }:
                images.setdefault(path.stem.casefold(), []).append(path)
    names = sorted({texture["name"] for material in materials
                    for texture in material["textures"]})
    textures = []
    for name in names:
        candidates = images.get(name.casefold(), [])
        textures.append({"name": name, "candidates": [
            {"path": str(path), "bytes": path.stat().st_size,
             "sha256": hashlib.sha256(path.read_bytes()).hexdigest().upper()}
            for path in candidates
        ]})
    if hashlib.sha256(model_path.read_bytes()).hexdigest().upper() != digest:
        raise ValueError("Cockpit changed while being inspected")
    counts = {}
    for connector in connectors:
        counts[connector["name"]] = counts.get(connector["name"], 0) + 1
    return {
        "schema": "AMXDENIS_COCKPIT_INVENTORY_1",
        "evidence": "static_records_only_not_native_acceptance",
        "model": str(model_path), "sha256": digest, "bytes": len(original),
        "edm_version": model.version, "nodes": len(model.nodes),
        "render_nodes": len(model.render_nodes),
        "shell_nodes": len(model.shell_nodes),
        "connectors": connectors, "materials": materials, "textures": textures,
        "duplicate_connectors": {name: count for name, count in counts.items()
                                 if count > 1},
        "missing_textures": [texture["name"] for texture in textures
                             if not texture["candidates"]],
        "parser_files": [
            {"name": name, "sha256": hashlib.sha256(
                (parser_directory / name).read_bytes()).hexdigest().upper()}
            for name in ("__init__.py", "parser.py", "reader.py", "types.py")
        ],
        "native_validated": False, "permissions_validated": False,
    }


def main():
    arguments = argparse.ArgumentParser()
    arguments.add_argument("--model", type=Path, required=True)
    arguments.add_argument("--parser", type=Path, required=True)
    arguments.add_argument("--expected-sha256", required=True)
    arguments.add_argument("--texture-root", type=Path, action="append", default=[])
    arguments.add_argument("--report", type=Path, required=True)
    options = arguments.parse_args()
    report = checked_path(options.report)
    protected = [checked_path(options.model).parent,
                 checked_path(options.parser),
                 *(checked_path(root) for root in options.texture_root)]
    if report.exists() or any(report.is_relative_to(root) for root in protected):
        raise ValueError("Report must be a new file outside input directories")
    result = inspect_model(options.model, options.parser,
                           options.expected_sha256, options.texture_root)
    report.parent.mkdir(parents=True, exist_ok=True)
    with report.open("x", encoding="utf-8", newline="\n") as destination:
        json.dump(result, destination, indent=2, ensure_ascii=True, allow_nan=False)
        destination.write("\n")
    print(json.dumps({
        "report": str(report), "sha256": result["sha256"],
        "connectors": len(result["connectors"]),
        "materials": len(result["materials"]), "textures": len(result["textures"]),
        "duplicate_connectors": result["duplicate_connectors"],
        "missing_textures": result["missing_textures"],
        "native_validated": False,
    }, ensure_ascii=True))


if __name__ == "__main__":
    main()