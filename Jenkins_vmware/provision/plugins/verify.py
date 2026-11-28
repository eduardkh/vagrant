#!/usr/bin/env python3
"""Milestone 4: plan archive changes and verify locked bytes/runtime state."""
import json
from pathlib import Path
import sys

from inventory import inventory


def main():
    mode, target, lock_path = sys.argv[1:]
    expected = json.loads(Path(lock_path).read_text())
    if mode == "runtime":
        report = json.loads(Path(target).read_text())
        actual = {plugin["id"]: plugin for plugin in report["plugins"]}
        errors = [plugin["id"] for plugin in expected
                  if plugin["id"] not in actual
                  or actual[plugin["id"]]["version"] != plugin["version"]
                  or not actual[plugin["id"]]["active"]]
        if report["failed"] or errors:
            raise SystemExit("Plugin load failures: " + str(report["failed"] + errors))
        if report["locale"] != {"language": "en", "ignoreBrowser": True, "allowUserPreferences": False}:
            raise SystemExit("English locale configuration did not load")
        print("All %s locked plugins active; Jenkins locale is English" % len(expected))
        return
    actual = {plugin["id"]: plugin for plugin in inventory(target)}
    changes = [plugin for plugin in expected if plugin["id"] not in actual
               or actual[plugin["id"]]["sha256"] != plugin["sha256"]
               or actual[plugin["id"]]["version"] != plugin["version"]]
    if mode == "plan":
        print(json.dumps(changes))
        return
    disabled = [plugin["id"] for plugin in expected
                if actual.get(plugin["id"], {}).get("disabled")]
    if changes or disabled:
        raise SystemExit("Locked plugin verification failed: " + str([p["id"] for p in changes] + disabled))
    print("Verified %s plugin versions and SHA-256 hashes" % len(expected))


if __name__ == "__main__":
    main()
