#!/usr/bin/env bash
set -euo pipefail

REPO="https://raw.githubusercontent.com/montyp0x/shipped/main"
INSTALL_DIR="$HOME/.local/share/shipped"
HOOK_DIR="$HOME/.cursor/hooks"
HOOK_FILE="$HOOK_DIR/shipped.sh"
HOOKS_JSON="$HOME/.cursor/hooks.json"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
	echo "python3 is required"
	exit 1
fi

if [[ "$OSTYPE" == darwin* ]]; then
	if ! command -v afplay >/dev/null 2>&1; then
		echo "no supported audio player found (afplay)"
		exit 1
	fi
elif command -v paplay >/dev/null 2>&1 || command -v aplay >/dev/null 2>&1; then
	:
else
	echo "no supported audio player found (paplay, aplay)"
	exit 1
fi

mkdir -p "$INSTALL_DIR" "$HOOK_DIR"

if [[ -f "$ROOT/assets/shipped.wav" && -f "$ROOT/hooks/shipped.sh" ]]; then
	cp "$ROOT/assets/shipped.wav" "$INSTALL_DIR/shipped.wav"
	if [[ -f "$ROOT/assets/shipped.mp3" ]]; then
		cp "$ROOT/assets/shipped.mp3" "$INSTALL_DIR/shipped.mp3"
	fi
	cp "$ROOT/hooks/shipped.sh" "$HOOK_FILE"
else
	curl -fsSL -o "$INSTALL_DIR/shipped.wav" "$REPO/assets/shipped.wav"
	curl -fsSL -o "$INSTALL_DIR/shipped.mp3" "$REPO/assets/shipped.mp3"
	curl -fsSL -o "$HOOK_FILE" "$REPO/hooks/shipped.sh"
fi

if [[ ! -f "$INSTALL_DIR/shipped.wav" || ! -f "$HOOK_FILE" ]]; then
	echo "failed to install shipped"
	exit 1
fi

chmod +x "$HOOK_FILE"

python3 - "$HOOKS_JSON" <<'PY'
import json, os, sys

path = sys.argv[1]
entry = {
    "command": "./hooks/shipped.sh",
    "matcher": r"\bgit\b[\s\S]*\b(?:commit|push)\b|\bgh\s+pr\s+create\b",
}

data = {"version": 1, "hooks": {}}
if os.path.exists(path) and os.path.getsize(path) > 0:
    try:
        with open(path) as fh:
            data = json.load(fh)
    except json.JSONDecodeError:
        sys.exit("could not parse ~/.cursor/hooks.json — fix it, then run install again")

if not isinstance(data, dict):
    sys.exit("~/.cursor/hooks.json is not a JSON object")

data.setdefault("version", 1)
hooks = data.setdefault("hooks", {})
if not isinstance(hooks, dict):
    sys.exit("~/.cursor/hooks.json has a hooks field that is not an object")

arr = hooks.setdefault("afterShellExecution", [])
if not isinstance(arr, list):
    sys.exit("afterShellExecution in ~/.cursor/hooks.json is not a list")

if any(isinstance(item, dict) and item.get("command") == "./hooks/shipped.sh" for item in arr):
    print("shipped is already installed in %s — refreshed the sound and hook script." % path)
else:
    arr.append(entry)
    tmp = path + ".shipped-tmp"
    with open(tmp, "w") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")
    os.replace(tmp, path)
    print("shipped installed into %s" % path)

print("Cursor reloads hooks on save. If it stays quiet, restart Cursor.")
PY
