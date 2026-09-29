#!/usr/bin/env bash
# Play the shipped sting after the agent commits, pushes, or opens a PR.
# Cursor user hook: afterShellExecution. Fail open. Never block the command.

input=$(cat)

DIR="${SHIPPED_HOME:-$HOME/.local/share/shipped}"

if [[ "$OSTYPE" == darwin* ]] && command -v afplay >/dev/null 2>&1; then
	PLAYER=(afplay)
	SOUND="$DIR/shipped.mp3"
	[[ -f "$SOUND" ]] || SOUND="$DIR/shipped.wav"
elif command -v paplay >/dev/null 2>&1; then
	PLAYER=(paplay)
	SOUND="$DIR/shipped.mp3"
	[[ -f "$SOUND" ]] || SOUND="$DIR/shipped.wav"
elif command -v aplay >/dev/null 2>&1; then
	PLAYER=(aplay -q)
	SOUND="$DIR/shipped.wav"
else
	exit 0
fi

[[ -f "$SOUND" ]] || exit 0

decision=$(printf '%s' "$input" | python3 -c '
import json, re, sys

try:
    data = json.load(sys.stdin)
except Exception:
    print("skip")
    raise SystemExit(0)

cmd = data.get("command") or ""
output = data.get("output") or ""
code = data.get("exit_code", data.get("exitCode"))

ship = re.compile(
    r"(?:^|&&|\|\||[;&|\n])\s*\(?\s*(?:[A-Za-z_][A-Za-z0-9_]*=\S*\s+)*(?:command\s+)?(?:\S*/)?git(?:\s+-[cC]\s+\S+)*(?:\s+-C\s+\S+)?\s+(?:commit|push)(?:\s|$)"
    r"|(?:^|&&|\|\||[;&|\n])\s*\(?\s*(?:[A-Za-z_][A-Za-z0-9_]*=\S*\s+)*(?:command\s+)?(?:\S*/)?gh\s+pr\s+create(?:\s|$)",
    re.M,
)

if not ship.search(cmd) or re.search(r"(?:^|\s)--dry-run(?:\s|$)", cmd):
    print("skip")
    raise SystemExit(0)

if code is not None:
    try:
        if int(code) != 0:
            print("skip")
            raise SystemExit(0)
    except (TypeError, ValueError):
        pass
elif (
    re.search(r"(?m)^(fatal:|error:)", output)
    or "nothing to commit" in output
    or "Aborting commit" in output
):
    print("skip")
    raise SystemExit(0)

print("play")
' 2>/dev/null || true)

if [[ "$decision" == "play" ]]; then
	# Double-fork into a new session so the sting outlives the hook process.
	python3 -c '
import os, sys
player = sys.argv[1:-1]
sound = sys.argv[-1]
if os.fork() > 0:
    raise SystemExit(0)
try:
    os.setsid()
except OSError:
    pass
if os.fork() > 0:
    os._exit(0)
devnull = os.open(os.devnull, os.O_RDWR)
os.dup2(devnull, 0)
os.dup2(devnull, 1)
os.dup2(devnull, 2)
os.execvp(player[0], player + [sound])
' "${PLAYER[@]}" "$SOUND" >/dev/null 2>&1 || true
fi

exit 0
