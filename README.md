# shipped

Plays a sting every time your agent commits, pushes, or opens a pull request.

## Install

> [!WARNING]
> shipped adds a user-level Cursor hook in `~/.cursor/hooks.json`. Other hooks in that file are left in place.

```sh
curl -fsSL https://raw.githubusercontent.com/montyp0x/shipped/main/install.sh | bash
```

Cursor reloads `hooks.json` on save. If it stays quiet, restart Cursor.

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/montyp0x/shipped/main/uninstall.sh | bash
```

## What it listens for

The hook runs after the agent's shell commands (`afterShellExecution`). It plays when one of these succeeds:

- `git commit`
- `git push`
- `gh pr create`

Your own terminal is ignored. Failed commands stay quiet, including `nothing to commit` and `--dry-run`.

Try it:

```sh
printf '%s' '{"command":"git commit -m \"hi\"","output":"[main abc] hi"}' | ~/.cursor/hooks/shipped.sh
```

## Requirements

- Cursor
- `python3`
- `afplay` (macOS), `paplay` or `aplay` (Linux)
