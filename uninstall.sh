#!/usr/bin/env bash
set -euo pipefail

HOOK_FILE="$HOME/.cursor/hooks/shipped.sh"
HOOKS_JSON="$HOME/.cursor/hooks.json"
INSTALL_DIR="$HOME/.local/share/shipped"

if ! command -v python3 >/dev/null 2>&1; then
	echo "python3 is required"
	exit 1
fi

python3 - "$HOOKS_JSON" <<'PY'
import json, os, sys

path = sys.argv[1]
if not os.path.exists(path) or os.path.getsize(path) == 0:
    print("shipped is not installed in %s — skipping." % path)
    raise SystemExit(0)

try:
    with open(path) as fh:
        data = json.load(fh)
except json.JSONDecodeError:
    sys.exit("could not parse ~/.cursor/hooks.json — remove the shipped hook by hand")

hooks = data.get("hooks") if isinstance(data, dict) else None
arr = hooks.get("afterShellExecution") if isinstance(hooks, dict) else None
if not isinstance(arr, list):
    print("shipped is not installed in %s — skipping." % path)
    raise SystemExit(0)

kept = [
    item
    for item in arr
    if not (isinstance(item, dict) and item.get("command") == "./hooks/shipped.sh")
]
if len(kept) == len(arr):
    print("shipped is not installed in %s — skipping." % path)
    raise SystemExit(0)

if kept:
    hooks["afterShellExecution"] = kept
else:
    hooks.pop("afterShellExecution", None)

extra = set(data) - {"version", "hooks"}
if not hooks and not extra:
    os.remove(path)
else:
    if not hooks:
        data.pop("hooks", None)
    tmp = path + ".shipped-tmp"
    with open(tmp, "w") as fh:
        json.dump(data, fh, indent=2)
        fh.write("\n")
    os.replace(tmp, path)

print("shipped removed from %s" % path)
PY

rm -f "$HOOK_FILE"

if [[ -d "$INSTALL_DIR" ]]; then
	rm -rf "$INSTALL_DIR"
fi

echo "restart Cursor if the hook is still listed"
