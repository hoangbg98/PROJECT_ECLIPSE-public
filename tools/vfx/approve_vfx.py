"""Copy an owner-approved VFX review set into the character VFX folder.

Usage:
  python -I tools/vfx/approve_vfx.py char_fire_01 ultimate

This tool never edits frames_manifest.json or the asset-license log. Those
project records are handled after the Godot preview is approved.
"""
import argparse
import filecmp
import json
import os
import shutil
import sys
import tempfile
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
META_KEYS = ("tool", "model", "prompt", "refs", "date", "layers")


def fail(message):
    print("VFX approval stopped:", message)
    return 1


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("character_id")
    parser.add_argument("skill_key")
    args = parser.parse_args(argv)

    review = ROOT / "art_review" / args.character_id / f"{args.skill_key}_vfx"
    target = ROOT / "assets" / "characters" / args.character_id / "vfx"
    meta_path = review / "meta.json"
    if not meta_path.is_file():
        return fail(f"missing {meta_path}")
    try:
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        return fail(f"invalid meta.json: {error}")
    missing = [key for key in META_KEYS if not meta.get(key)]
    if missing:
        return fail("meta.json missing: " + ", ".join(missing))
    layers = meta["layers"]
    if not isinstance(layers, dict) or not layers:
        return fail("meta.json layers must be a non-empty object")

    copies = []
    for layer, count in layers.items():
        if not isinstance(count, int) or count < 1:
            return fail(f"invalid frame count for {layer}")
        source_dir = review / layer
        files = sorted(source_dir.glob(f"{layer}_*.png"))
        expected_names = [f"{layer}_{index:03d}.png" for index in range(count)]
        if [path.name for path in files] != expected_names:
            return fail(f"{layer}: expected {count} numbered PNG frames starting at 000")
        dimensions = set()
        for path in files:
            try:
                with Image.open(path) as image:
                    if image.format != "PNG" or image.mode != "RGBA":
                        return fail(f"{path.name}: expected an RGBA PNG")
                    alpha = image.getchannel("A")
                    if alpha.getextrema() == (255, 255):
                        return fail(f"{path.name}: no transparent pixels")
                    if alpha.getextrema() == (0, 0):
                        return fail(f"{path.name}: frame is fully transparent")
                    rgba = image.convert("RGBA")
                    for pixel in rgba.get_flattened_data():
                        if pixel[3] > 0 and pixel[:3] == (255, 0, 255):
                            return fail(f"{path.name}: opaque #FF00FF remains")
                    dimensions.add(image.size)
            except (OSError, ValueError) as error:
                return fail(f"cannot read {path.name}: {error}")
            target_name = f"{args.character_id}_vfx_{args.skill_key}_{layer}_{path.stem.rsplit('_', 1)[1]}.png"
            copies.append((path, target / target_name))
        if len(dimensions) != 1:
            return fail(f"{layer}: frames do not share one canvas size")

    conflicts = [
        destination.name
        for source, destination in copies
        if destination.exists() and not filecmp.cmp(source, destination, shallow=False)
    ]
    if conflicts:
        return fail("refusing to overwrite: " + ", ".join(conflicts))
    copies = [(source, destination) for source, destination in copies if not destination.exists()]
    if not copies:
        print(f"Approved VFX assets already match review set in {target}")
        return 0

    target.mkdir(parents=True, exist_ok=True)
    staging = Path(tempfile.mkdtemp(prefix=".approve_vfx_", dir=target))
    try:
        for source, destination in copies:
            shutil.copy2(source, staging / destination.name)
        for _, destination in copies:
            os.rename(staging / destination.name, destination)
    except OSError as error:
        for _, destination in copies:
            if destination.exists():
                destination.unlink()
        return fail(f"copy failed: {error}")
    finally:
        shutil.rmtree(staging, ignore_errors=True)

    print(f"Approved {len(copies)} VFX frames across {len(layers)} layers to {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
