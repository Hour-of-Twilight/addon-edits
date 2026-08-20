#!/usr/bin/env python3
"""Zips every addon listed in addons.yml and writes the addons.json the launcher reads.

Usage: build-addons.py <addons.yml> <output-dir> <release-tag>

The zip layout has to mirror Interface/AddOns, so entries are written as
"<FolderName>/<path inside it>" with nothing above them. The launcher treats each top-level
folder in the zip as an addon folder and refuses anything that would land outside AddOns.
"""

import hashlib
import json
import os
import sys
import zipfile
from datetime import datetime, timezone

import yaml

SKIP_DIRS = {".git", ".github", "__pycache__"}


def sha256_of(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def add_folder(archive, folder):
    for root, dirs, files in os.walk(folder):
        dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
        for name in sorted(files):
            full = os.path.join(root, name)
            archive.write(full, os.path.relpath(full, os.path.dirname(folder) or "."))


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)

    config_path, out_dir, tag = sys.argv[1], sys.argv[2], sys.argv[3]

    with open(config_path, "r", encoding="utf-8") as handle:
        config = yaml.safe_load(handle) or {}

    addons = config.get("addons") or []
    if not addons:
        sys.exit("addons.yml lists no addons.")

    os.makedirs(out_dir, exist_ok=True)
    entries = []
    seen_ids = set()

    for addon in addons:
        addon_id = addon["id"]
        if addon_id in seen_ids:
            sys.exit(f"Duplicate addon id '{addon_id}' in addons.yml.")
        seen_ids.add(addon_id)

        folders = addon["folders"]
        main_folder = addon.get("mainFolder") or folders[0]
        if main_folder not in folders:
            sys.exit(f"{addon_id}: mainFolder '{main_folder}' is not in its folders list.")

        missing = [f for f in folders if not os.path.isdir(f)]
        if missing:
            sys.exit(f"{addon_id}: these folders are not in the repo: {', '.join(missing)}")

        asset = addon.get("asset") or f"{main_folder}.zip"
        zip_path = os.path.join(out_dir, asset)

        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as archive:
            for folder in folders:
                add_folder(archive, folder.rstrip("/"))

        entries.append({
            "id": addon_id,
            "name": addon.get("name") or addon_id,
            "summary": addon.get("summary", ""),
            "website": addon.get("website", ""),
            "asset": asset,
            "size": os.path.getsize(zip_path),
            "sha256": sha256_of(zip_path),
            "mainFolder": main_folder,
            "folders": folders,
        })
        print(f"built {asset}  {entries[-1]['size']} bytes  {entries[-1]['sha256'][:12]}...")

    catalog = {
        "schema": 1,
        "version": tag,
        "generated": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "addons": entries,
    }

    with open(os.path.join(out_dir, "addons.json"), "w", encoding="utf-8") as handle:
        json.dump(catalog, handle, indent=2)
        handle.write("\n")


if __name__ == "__main__":
    main()
