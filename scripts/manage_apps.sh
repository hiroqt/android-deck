#!/usr/bin/env bash
set -euo pipefail

PROFILE_FILE="$HOME/.macdeck/profile.json"
mkdir -p "$HOME/.macdeck"

# Python script to manage ~/.macdeck/profile.json
python3 - "$@" << 'EOF'
import sys
import json
import os
import subprocess
from pathlib import Path

PROFILE_PATH = Path.home() / ".macdeck" / "profile.json"

def scan_installed_apps():
    search_dirs = [
        "/Applications",
        "/System/Applications",
        "/System/Applications/Utilities"
    ]
    apps = []
    seen = set()

    for d in search_dirs:
        p = Path(d)
        if not p.exists():
            continue
        for item in p.glob("*.app"):
            plist_path = item / "Contents" / "Info.plist"
            bundle_id = None
            name = item.stem

            if plist_path.exists():
                try:
                    out = subprocess.check_output(
                        ["defaults", "read", str(plist_path.resolve()), "CFBundleIdentifier"],
                        stderr=subprocess.DEVNULL
                    ).decode("utf-8").strip()
                    bundle_id = out
                except Exception:
                    pass

            if bundle_id and bundle_id not in seen:
                seen.add(bundle_id)
                apps.append({"name": name, "bundleId": bundle_id, "path": str(item)})

    return sorted(apps, key=lambda x: x["name"].lower())

def load_profile():
    if PROFILE_PATH.exists():
        try:
            with open(PROFILE_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {
        "revision": 1,
        "name": "Main Deck",
        "slots": [
            {"id": "app-1", "label": "VS Code", "bundleId": "com.microsoft.VSCode"},
            {"id": "app-2", "label": "Terminal", "bundleId": "com.apple.Terminal"},
            {"id": "app-3", "label": "Safari", "bundleId": "com.apple.Safari"},
            {"id": "app-4", "label": "Finder", "bundleId": "com.apple.finder"},
            {"id": "app-5", "label": "Settings", "bundleId": "com.apple.systempreferences"},
            {"id": "app-6", "label": "Music", "bundleId": "com.apple.Music"}
        ]
    }

def save_profile(data):
    data["revision"] = data.get("revision", 1) + 1
    with open(PROFILE_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    print(f"💾 Saved profile to {PROFILE_PATH} (revision {data['revision']})")
    print("📡 Connected Android phones will update automatically in real time!")

def print_slots(profile):
    print("\n📱 Current MacDeck Slots (Max 6):")
    print("--------------------------------------------------")
    for i, s in enumerate(profile.get("slots", [])):
        print(f"  Slot {i + 1}: {s.get('label', 'App')}  [{s.get('bundleId', '')}]")
    print("--------------------------------------------------\n")

def main():
    args = sys.argv[1:]
    profile = load_profile()

    if not args or args[0] == "list":
        print_slots(profile)
        print("Usage:")
        print("  ./scripts/manage_apps.sh list")
        print("  ./scripts/manage_apps.sh search <query>       (e.g.: ./scripts/manage_apps.sh search discord)")
        print("  ./scripts/manage_apps.sh set <1-6> <query>    (e.g.: ./scripts/manage_apps.sh set 3 brave)")
        return

    cmd = args[0].lower()

    if cmd == "search":
        if len(args) < 2:
            print("Please specify a search query: ./scripts/manage_apps.sh search <query>")
            return
        query = args[1].lower()
        apps = scan_installed_apps()
        matches = [a for a in apps if query in a["name"].lower() or query in a["bundleId"].lower()]
        print(f"\nFound {len(matches)} matching apps for '{query}':")
        for m in matches:
            print(f"  • {m['name']} → {m['bundleId']}")
        print("")

    elif cmd == "set":
        if len(args) < 3:
            print("Usage: ./scripts/manage_apps.sh set <slot 1-6> <app name or bundleId>")
            return
        try:
            slot_idx = int(args[1]) - 1
            if slot_idx < 0 or slot_idx > 5:
                raise ValueError()
        except ValueError:
            print("❌ Error: Slot must be an integer between 1 and 6.")
            return

        query = args[2].strip()
        apps = scan_installed_apps()

        # Try exact bundleId match first
        found = next((a for a in apps if a["bundleId"].lower() == query.lower()), None)
        # Try exact name match
        if not found:
            found = next((a for a in apps if a["name"].lower() == query.lower()), None)
        # Try partial name match
        if not found:
            matches = [a for a in apps if query.lower() in a["name"].lower() or query.lower() in a["bundleId"].lower()]
            if matches:
                found = matches[0]

        if found:
            label = found["name"]
            bundle_id = found["bundleId"]
        else:
            label = query.split(".")[-1].capitalize() if "." in query else query
            bundle_id = query

        # Ensure slots array is big enough
        while len(profile["slots"]) < 6:
            profile["slots"].append({
                "id": f"app-{len(profile['slots']) + 1}",
                "label": f"App {len(profile['slots']) + 1}",
                "bundleId": "com.apple.Terminal"
            })

        profile["slots"][slot_idx]["label"] = label
        profile["slots"][slot_idx]["bundleId"] = bundle_id
        save_profile(profile)
        print_slots(profile)

    else:
        print(f"Unknown command: '{cmd}'. Use 'list', 'search <query>', or 'set <1-6> <query>'.")

if __name__ == "__main__":
    main()
EOF
