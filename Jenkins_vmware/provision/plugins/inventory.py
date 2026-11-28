#!/usr/bin/env python3
"""Milestone 4: inventory plugin archives without reading Jenkins secrets."""
import hashlib
import json
from pathlib import Path
import sys
import zipfile


def inventory(directory):
    plugins = []
    for archive in sorted(Path(directory).iterdir()):
        if archive.suffix not in (".jpi", ".hpi"):
            continue
        with zipfile.ZipFile(archive) as package:
            manifest = package.read("META-INF/MANIFEST.MF").decode("utf-8")
        unfolded = []
        for line in manifest.splitlines():
            if line.startswith(" "):
                unfolded[-1] += line[1:]
            else:
                unfolded.append(line)
        fields = dict(line.split(": ", 1) for line in unfolded if ": " in line)
        plugins.append({
            "id": fields["Short-Name"],
            "version": fields["Plugin-Version"],
            "required_core": fields.get("Jenkins-Version"),
            "dependencies": fields.get("Plugin-Dependencies", ""),
            "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
            "disabled": Path(str(archive) + ".disabled").exists(),
        })
    return sorted(plugins, key=lambda plugin: plugin["id"])


if __name__ == "__main__":
    print(json.dumps(inventory(sys.argv[1]), indent=2))
