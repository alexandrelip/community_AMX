"""Selective source import and deterministic AMXDENIS desktop candidate builder.

No simulator launch, profile installation, model conversion or source modification.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
REFERENCE = Path("Avionics/Reference/AMX-A1M")
ADAPTERS = Path("Avionics/AMXDENIS")
MODEL = "Shapes/AMX_COCKPIT_REV07_184.edm"
MODEL_HASH = "7C2F1DE3C8AF4F8684C0C892A24EEFA4497C438CB85CAD0D09A177445B1D3342"
CORE_FOLDERS = ("CMFD", "HUD", "UFCP", "EFI", "Indicator")
CORE_FILES = ("devices.lua", "command_defs.lua", "materials.lua", "fonts.lua",
              "functions.lua", "utils.lua", "dump.lua")
SYSTEM_FILES = (
    "avionics_api.lua", "weapon_system_api.lua", "ufcp_api.lua", "coordinate_api.lua",
    "alarm_api.lua", "alarm.lua", "engine_api.lua", "efi.lua", "rdr_api.lua",
    "f5em_common.lua", "sounds_callouts.lua",
)
AMX_FILES = (
    "Systems/electric_system_api.lua", "Systems/host_eicas.lua", "Systems/host_fuel.lua",
    "Systems/host_alarm_sources.lua", "Systems/host_controls.lua", "Systems/host_text.lua",
    "Systems/host_telemetry.lua", "Indicator/host_eicas_indication.lua", "Indicator/host_geometry.lua",
    "CMFD/Indicator/CMFD_EICAS.lua", "EFI/Indicator/EFI.lua",
    "UFCP/host_icp_init.lua", "UFCP/host_icp_page.lua", "sounds_init.lua",
)
# Kept out of executable runtime. The corresponding target files implement explicit
# unavailable/read-only interfaces where a supported page still references a module.
EXCLUDED = {
    "CMFD/Device/tgp_litening.lua", "CMFD/Device/dtc_writer.lua", "CMFD/Device/dtu.lua",
    "CMFD/Device/ldp.lua", "CMFD/Device/hmd.lua", "CMFD/Device/ifr.lua",
    "CMFD/Device/flir_text.lua", "CMFD/Device/tactical_overlay.lua", "CMFD/Device/surv.lua",
    "CMFD/Device/bit.lua",
    "Systems/weapon_system.lua", "Systems/rdr.lua", "Systems/rwr.lua",
    "Systems/avionics.lua", "Systems/F5EM_EW_bridge_consumer.lua",
    "Systems/F5EM_Link_BR2_RX_consumer.lua", "Systems/Link_BR2_Export.lua",
    "Systems/aar_refuel.lua", "Systems/efb.lua", "Systems/autopilot.lua",
}


def safe(path):
    path = Path(path).absolute()
    for part in (path, *path.parents):
        if part.is_symlink() or part.is_junction():
            raise ValueError(f"Linked path refused: {part}")
    path = path.resolve()
    if path == Path(path.anchor) or str(path).startswith("\\\\"):
        raise ValueError("Drive and network roots are not build directories")
    if any(part.casefold() in {"saved games", "windows", "program files", "program files (x86)"}
           for part in path.parts):
        raise ValueError("Build operations refuse simulator profiles and installations")
    return path


def within(root, relative):
    root = safe(root)
    raw = str(relative).replace("\\", "/")
    if raw.startswith("/") or Path(raw).is_absolute() or re.search(r'[<>:"|?*\x00-\x1f]', raw) or any(
        part.casefold() in {"", ".", "..", ".git"} or part.endswith((".", " ")) for part in raw.split("/")
    ):
        raise ValueError(f"Unsafe relative build path: {relative}")
    result = safe(root / raw)
    if not result.is_relative_to(root):
        raise ValueError("Build path escaped its root")
    return result


def sha(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest().upper()


def load(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8", newline="\n") as stream:
        json.dump(value, stream, indent=2, sort_keys=True, ensure_ascii=True, allow_nan=False)
        stream.write("\n")


def copy_verified(source, destination, expected=None):
    digest = sha(source)
    if expected is not None and digest != expected.upper():
        raise ValueError(f"Source identity changed: {source}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    with source.open("rb") as read, destination.open("xb") as write:
        shutil.copyfileobj(read, write)
    if sha(destination) != digest or sha(source) != digest:
        raise ValueError(f"Copy verification failed: {destination}")
    return digest


def permission():
    config = load(ROOT / "Config/AMXDENIS_INTEGRATION.json")
    evidence = load(ROOT / "Doc/Integration/PERMISSIONS.json")
    if config["AircraftType"] != "AMXT_M" or config["PilotSeat"] != 1 or (
        config["PluginId"], config["DeveloperName"]) != ("Embraer AMX", "BR"):
        raise ValueError("Candidate identity is not the authorized original aircraft")
    for flag in ("EnabledInWorkingTree", "NativeFlir", "HelmetDisplay", "NativeRadioProbe",
                 "ExternalResourcesMutable", "FlightModelMutable"):
        if config[flag] is not False:
            raise ValueError(f"Out-of-scope configuration: {flag}")
    if evidence["State"] != "AUTHORIZED_LOCAL" or evidence["Scope"] != "LOCAL_AMXDENIS_M1":
        raise ValueError("Local permission evidence is required")
    required = {"REV07 internal model", "REV07 textures and indicator resources",
                "Adapted F-5EM/A-29 Lua dependencies"}
    if not required.issubset(evidence["Components"]) or not evidence["Statement"]:
        raise ValueError("Permission record does not cover this import")
    if evidence["LicenseCheckBypassAuthorized"] or evidence["IdentityChangesAuthorized"]:
        raise ValueError("Identity or license bypass is never part of this build")
    if sha(ROOT / MODEL) != MODEL_HASH:
        raise ValueError("REV07 changed; do not transfer old bindings")
    return config


def source_selection(source):
    """Enumerated script/resource scope, NOT a directory mirror of the donor mod."""
    selections = {}
    donor = source / "Avionics/F5EM/Cockpit/Scripts"
    canonical = {item.relative_to(source).as_posix().casefold(): item.relative_to(source).as_posix()
                 for item in donor.rglob("*") if item.is_file()}
    for folder in CORE_FOLDERS:
        for item in sorted((donor / folder).rglob("*")):
            if item.is_symlink() or item.is_junction():
                raise ValueError("Linked reference file")
            if item.is_file() and item.suffix.lower() in {".lua", ".dds", ".tga", ".svg", ".png"}:
                relative = item.relative_to(donor).as_posix()
                if relative not in EXCLUDED:
                    selections[item.relative_to(source).as_posix()] = "donor_script_or_indicator_resource"
    for relative in CORE_FILES:
        selections[(Path("Avionics/F5EM/Cockpit/Scripts") / relative).as_posix()] = "donor_common"
    for relative in SYSTEM_FILES:
        item = donor / "Systems" / relative
        if item.is_file():
            selections[item.relative_to(source).as_posix()] = "donor_api"
    # APIs can have literal pure-Lua dependencies. Resolve only existing local scripts;
    # unsafe modules are excluded and replaced by explicit unavailable target adapters.
    pending = list(selections)
    while pending:
        relative = pending.pop()
        if not relative.endswith(".lua"):
            continue
        text = (source / relative).read_text(encoding="utf-8-sig")
        for match in re.finditer(r'["\']([^"\'\r\n]+\.lua)["\']', text):
            name = match[1].replace("\\", "/")
            if name in EXCLUDED or name.startswith(("/", "..")):
                continue
            item = donor / name
            if item.is_file() and item.is_relative_to(donor):
                key = canonical[item.relative_to(source).as_posix().casefold()]
                if key not in selections:
                    selections[key] = "donor_literal_dependency"
                    pending.append(key)
    for name in AMX_FILES:
        selections["Avionics/AMX/Cockpit/Scripts/" + name] = "source_adapted_avionics"
    selections["Avionics/AMX/patches.lua"] = "source_strict_patch_rules"
    for relative in ("LICENSE", "Avionics/F5EM/NOTICE", "Avionics/A29/NOTICE", "Avionics/A29/README.md"):
        selections[relative] = "provenance_notice"
    for relative in ("font_RWR.tga", "font_sheet_F5.tga", "indication_RWR.tga"):
        selections["Avionics/F5EM/Cockpit/IndicationTextures/" + relative] = "indicator_resource"
    # Preserve the original host scripts separately for comparison, never register their
    # external draw-argument animators in the new host.
    for relative in ("Systems/start_panel.lua", "Systems/electric_system.lua", "Systems/hydraulic_system.lua",
                     "command_defs.lua", "clickabledata.lua", "mainpanel_init.lua"):
        selections["Cockpit/scripts/" + relative] = "host_reference_not_executed"
    return selections


def import_sources(snapshot_root, inventory_path, baseline_root):
    permission()
    snapshot_root = safe(snapshot_root)
    snapshot = load(snapshot_root / "snapshot.json")
    verification = load(snapshot_root / "verification.json")
    if (snapshot["Schema"] != "AMXDENIS_SNAPSHOT_1" or
        verification["SnapshotSHA256"] != sha(snapshot_root / "snapshot.json") or
        verification["SourceAndCopyHashesMatch"] is not True or
        safe(snapshot["Roots"]["Target"]) != ROOT):
        raise ValueError("A verified current snapshot is required")
    destination = ROOT / REFERENCE
    if destination.exists():
        raise ValueError("Reference already exists; verify instead of overwriting")
    source = safe(snapshot_root / "Source")
    source_hashes = {row["Path"].replace("\\", "/").casefold(): row["SHA256"] for row in snapshot["Files"]
                     if row["Root"] == "Source"}
    selections = source_selection(source)
    rows = []
    for name, role in sorted(selections.items()):
        item = within(source, name)
        if not item.is_file() or name.casefold() not in source_hashes or sha(item) != source_hashes[name.casefold()]:
            raise ValueError(f"Selected reference is missing or changed: {name}")
        rows.append({"Path": name, "SHA256": source_hashes[name.casefold()], "Bytes": item.stat().st_size, "Role": role})
    geometry = load(inventory_path)
    if geometry["sha256"] != MODEL_HASH or geometry["schema"] != "AMXDENIS_COCKPIT_INVENTORY_1":
        raise ValueError("REV07 inventory identity mismatch")
    baseline_root = safe(baseline_root)
    baseline = load(baseline_root / "snapshot.json")
    proof = load(baseline_root / "verification.json")
    if proof["SnapshotSHA256"] != sha(baseline_root / "snapshot.json") or proof["SourceAndCopyHashesMatch"] is not True:
        raise ValueError("Original snapshot verification is missing")
    original_rows = [row for row in baseline["Files"] if row["Root"] == "Target" and
                     not row["Path"].replace("\\", "/").startswith(".git/")]
    for row in original_rows:
        if sha(within(ROOT, row["Path"])) != row["SHA256"]:
            raise ValueError("Original baseline was changed before integration")
    original_contract = {"Schema": "AMXDENIS_ORIGINAL_1", "SnapshotId": baseline["Id"],
        "SnapshotSHA256": sha(baseline_root / "snapshot.json"),
        "Files": [{"Path": row["Path"].replace("\\", "/"), "SHA256": row["SHA256"]} for row in original_rows],
        "Variants": {"AMX": [6730, 9520, 13000, 2790, 1], "AMX_M": [6730, 9520, 13000, 2790, 1],
                     "AMXT": [7200, 9750, 13000, 2550, 2], "AMXT_M": [7200, 9750, 13000, 2550, 2]},
        "VariantColumns": ["M_empty", "M_nominal", "M_max", "M_fuel_max", "crew_size"],
        "Engines": 1, "Stores": 7, "PhysicsCalibrationClaimed": False}
    write_json(destination / "import-intent.json", {"Schema": "AMXDENIS_SOURCE_IMPORT_INTENT_1", "Files": rows})
    for row in rows:
        copy_verified(within(source, row["Path"]), within(destination, row["Path"]), row["SHA256"])
    write_json(destination / "import-manifest.json", {"Schema": "AMXDENIS_SOURCE_IMPORT_1", "Files": rows,
        "SourceSnapshotId": snapshot["Id"], "SourceSnapshotSHA256": sha(snapshot_root / "snapshot.json"),
        "SourceRevision": snapshot.get("Git", {}).get("Source"), "AuthoritativeTarget": "AMXDENIS",
        "DonorEntryExecuted": False, "ExternalModelsImported": False, "BinaryLibrariesImported": False})
    # Freeze measured records, omitting external absolute texture paths and old approvals.
    write_json(ROOT / "Config/REV07_RECORDS.json", {"Schema": "AMXDENIS_REV07_RECORDS_1", "ModelSHA256": MODEL_HASH,
        "ModelBytes": geometry["bytes"], "Connectors": geometry["connectors"], "NativeValidated": False,
        "InventorySHA256": sha(inventory_path)})
    write_json(ROOT / "Config/AMXDENIS_ORIGINAL.json", original_contract)
    print(f"AMXDENIS_REFERENCE_IMPORTED|files={len(rows)}|external_models=0|native=false")


def lua_literal(value):
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        return '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("\r", "\\r").replace("\n", "\\n") + '"'
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, list):
        return "{" + ",".join(lua_literal(item) for item in value) + "}"
    return "{" + ",".join("[" + lua_literal(key) + "]=" + lua_literal(value[key]) for key in sorted(value)) + "}"


def run_lua(lua, arguments, expected):
    result = subprocess.run([str(lua), *map(str, arguments)], capture_output=True, text=True, errors="replace")
    text = result.stdout + result.stderr
    print(text, end="")
    if result.returncode != 0 or expected not in text or "stack traceback:" in text or "[FAIL]" in text:
        raise ValueError(f"Lua stage failed (exit={result.returncode})")
    return text


def candidate_destination(candidate):
    candidate = safe(candidate)
    output_root = safe(Path(os.environ["LOCALAPPDATA"]) / "AMXDENIS-Integration/Candidates")
    if candidate.parent != output_root or candidate.exists() or candidate.is_relative_to(ROOT) or ROOT.is_relative_to(candidate):
        raise ValueError("A new separate candidate directory is required")
    return candidate


def verify_reference(reference):
    reference = safe(reference)
    imported = load(reference / "import-manifest.json")
    intent = load(reference / "import-intent.json")
    if (imported["Schema"] != "AMXDENIS_SOURCE_IMPORT_1" or
            intent["Schema"] != "AMXDENIS_SOURCE_IMPORT_INTENT_1" or
            imported["Files"] != intent["Files"] or not imported["Files"] or
            any(imported[flag] is not False for flag in
                ("DonorEntryExecuted", "ExternalModelsImported", "BinaryLibrariesImported"))):
        raise ValueError("Source import manifest disagrees with the authorized selection")
    seen = set()
    for row in imported["Files"]:
        name = row["Path"].replace("\\", "/").casefold()
        if name in seen or Path(name).suffix in {".dll", ".exe", ".edm", ".lods", ".miz"}:
            raise ValueError("Duplicate or out-of-scope source reference")
        seen.add(name)
        item = within(reference, row["Path"])
        if sha(item) != row["SHA256"] or item.stat().st_size != row["Bytes"]:
            raise ValueError(f"Immutable reference changed: {row['Path']}")
    return imported


def build(candidate, lua, mechanism_probe=None):
    if mechanism_probe not in (None, "without-mechanimations", "duplicate-canopy"):
        raise ValueError("Unsupported mechanism descriptor probe")
    candidate = candidate_destination(candidate)
    inputs = {}

    def track(relative, expected=None):
        path = within(ROOT, relative)
        digest = sha(path)
        if expected is not None and digest != expected:
            raise ValueError(f"Build input changed: {relative}")
        name = path.relative_to(ROOT).as_posix()
        if name in inputs and inputs[name] != digest:
            raise ValueError(f"Build input changed during assembly: {name}")
        inputs[name] = digest
        return digest

    for name in ("Tools/build_amxdenis.py", "Tools/build_amxdenis.lua", "Config/REV07_RECORDS.json",
                 "Config/AMXDENIS_ORIGINAL.json", "Config/AMXDENIS_TEXTURES.json",
                 "Config/AMXDENIS_INTEGRATION.json", "Doc/Integration/PERMISSIONS.json",
                 "Doc/Integration/Notices/F5EM-NOTICE.txt",
                 "Doc/Integration/Evidence/REV07-user-visual-acceptance.json",
                 (REFERENCE / "import-manifest.json").as_posix(),
                 (REFERENCE / "import-intent.json").as_posix()):
        track(name)
    permission()
    reference = ROOT / REFERENCE
    imported = verify_reference(reference)
    original = load(ROOT / "Config/AMXDENIS_ORIGINAL.json")
    textures = load(ROOT / "Config/AMXDENIS_TEXTURES.json")
    if not textures["Complete"]:
        approval = load(ROOT / "Doc/Integration/Evidence/REV07-user-visual-acceptance.json")
        if approval["Model"]["SHA256"] != MODEL_HASH or approval["Textures"]["ManifestSHA256"] != sha(ROOT / "Config/AMXDENIS_TEXTURES.json") or not approval["Approval"]["UserVisualAppearanceAccepted"]:
            raise ValueError("Incomplete texture set has no matching user-approved visual baseline")
    for row in imported["Files"]:
        track(REFERENCE / row["Path"], row["SHA256"])
    for row in original["Files"]:
        if sha(within(ROOT, row["Path"])) != row["SHA256"]:
            raise ValueError(f"Protected original changed: {row['Path']}")
        if row["Path"] == "entry.lua" or row["Path"].startswith("Entry/") or row["Path"] == "LICENSE":
            track(Path("ci/fixtures/original") / row["Path"], row["SHA256"])
    candidates = {row["Path"] for row in original["Files"]}
    candidates.update((MODEL, "Entry/Views.lua", "Config/AMXDENIS_COCKPIT.lua"))
    for row in textures["Files"]:
        if sha(within(ROOT, row["Path"])) != row["SHA256"]:
            raise ValueError("Local cockpit texture changed")
        candidates.add(row["Path"])
    for row in candidates:
        if not within(ROOT, row).is_file():
            raise ValueError(f"Candidate input absent: {row}")
        track(row)
    lua_hash = sha(lua)
    candidate.mkdir(parents=True)
    for name in sorted(candidates):
        copy_verified(within(ROOT, name), within(candidate, name), inputs[name])
    scripts = candidate / "Avionics/Runtime/Cockpit/Scripts"
    data = {"files": [], "root": ROOT.as_posix(), "candidate": candidate.as_posix(),
            "reference": reference.as_posix(), "scripts": scripts.as_posix() + "/",
            "records": load(ROOT / "Config/REV07_RECORDS.json"),
            "mechanism_probe": mechanism_probe or False}
    for row in imported["Files"]:
        relative = row["Path"]
        prefix = "Avionics/F5EM/Cockpit/"
        if relative.startswith(prefix):
            dest = "Avionics/Runtime/Cockpit/" + relative[len(prefix):]
            if relative.endswith("/devices.lua"):
                dest = dest.removesuffix("devices.lua") + "devices_donor.lua"
            copy_verified(within(reference, relative), within(candidate, dest), row["SHA256"])
    (candidate / "Avionics/Runtime/Cockpit/Textures").mkdir(parents=True, exist_ok=True)
    for name in AMX_FILES:
        origin = "Avionics/AMX/Cockpit/Scripts/" + name
        dest = scripts / name
        if dest.exists():
            dest.unlink()  # Owned, fresh candidate only; immutable reference is never edited.
        copy_verified(within(reference, origin), dest)
    for item in sorted((ROOT / ADAPTERS / "Scripts").rglob("*")):
        if item.is_file():
            track(item.relative_to(ROOT))
            relative = item.relative_to(ROOT / ADAPTERS / "Scripts")
            dest = scripts / relative
            if dest.exists():
                dest.unlink()
            copy_verified(item, dest, inputs[item.relative_to(ROOT).as_posix()])
    for name in ("patches.lua", "controls.lua", "bindings.lua"):
        item = ROOT / ADAPTERS / name
        if not item.is_file():
            raise ValueError(f"Missing target contract: {name}")
        track(item.relative_to(ROOT))
    for item in sorted(scripts.rglob("*.lua")):
        data["files"].append(item.relative_to(scripts).as_posix())
    for kind in ("keyboard", "joystick"):
        (candidate / "Input/AMXT_M" / kind).mkdir(parents=True)
    (candidate / "Doc/Integration").mkdir(parents=True, exist_ok=True)
    for name in ("PERMISSIONS.json", "Notices/F5EM-NOTICE.txt"):
        copy_verified(ROOT / "Doc/Integration" / name, candidate / "Doc/Integration" / name)
    for source, target_name in (("LICENSE", "AMX-A1M-LICENSE.txt"),
                                ("Avionics/A29/NOTICE", "A29-NOTICE.txt"),
                                ("Avionics/A29/README.md", "A29-README.md")):
        copy_verified(reference / source, candidate / "Doc/Integration/Notices" / target_name)
    prepare = candidate / "build-input.lua"
    prepare.write_text("return " + lua_literal(data) + "\n", encoding="utf-8", newline="\n")
    try:
        run_lua(lua, [ROOT / "Tools/build_amxdenis.lua", prepare], "AMXDENIS_RUNTIME_GENERATED")
    finally:
        # Build-time paths do not belong in the runnable artifact.
        prepare.unlink()
    outputs = [{"Path": item.relative_to(candidate).as_posix(), "Bytes": item.stat().st_size, "SHA256": sha(item)}
               for item in sorted(candidate.rglob("*")) if item.is_file()]
    build_id = hashlib.sha256(json.dumps(outputs, sort_keys=True, separators=(",", ":")).encode()).hexdigest().upper()
    for name, digest in inputs.items():
        if sha(within(ROOT, name)) != digest:
            raise ValueError("Source changed during candidate assembly")
    if sha(lua) != lua_hash:
        raise ValueError("Lua toolchain changed during candidate assembly")
    input_rows = [{"Path": name, "SHA256": digest} for name, digest in sorted(inputs.items())]
    input_id = hashlib.sha256(json.dumps(input_rows, sort_keys=True, separators=(",", ":")).encode()).hexdigest().upper()
    write_json(candidate / "candidate-manifest.json", {"Schema": "AMXDENIS_CANDIDATE_1", "BuildId": build_id,
        "AircraftType": "AMXT_M", "PilotSeat": 1, "Stage": "IMPLEMENTADO_NAO_VALIDADO", "Files": outputs,
        "Inputs": input_rows, "InputSetSHA256": input_id, "LuaExecutableSHA256": lua_hash, "NativeValidated": False,
        "ExternalResourcesChanged": False, "FlightModelChanged": False,
        "DescriptorChanged": mechanism_probe is not None,
        "DescriptorProbe": mechanism_probe or "none",
        "ExperimentalOnly": mechanism_probe is not None,
        "MissingLocalTextures": textures["MissingTextures"], "DesktopCandidateOnly": True})
    print(f"AMXDENIS_CANDIDATE_BUILT|files={len(outputs)}|id={build_id}|native=false")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    command = commands.add_parser("import")
    command.add_argument("--snapshot", type=Path, required=True)
    command.add_argument("--inventory", type=Path, required=True)
    command.add_argument("--baseline", type=Path, required=True)
    command = commands.add_parser("build")
    command.add_argument("--candidate", type=Path, required=True)
    command.add_argument("--lua", type=Path, required=True)
    command.add_argument("--mechanism-probe", choices=("without-mechanimations", "duplicate-canopy"))
    options = parser.parse_args()
    if options.command == "import":
        import_sources(options.snapshot, options.inventory, options.baseline)
    else:
        build(options.candidate, options.lua, options.mechanism_probe)


if __name__ == "__main__":
    main()