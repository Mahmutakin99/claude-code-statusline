# claude-code-statusline

A single-file `bash` statusline for [Claude Code](https://docs.claude.com/en/docs/claude-code) that shows your working directory, git branch, active model, context window usage, session cost, and — for Claude subscribers — your 5-hour and 7-day rate limit usage, all in one line.

```
isTakipSistemi ⎇main  Sonnet 5 high  ctx 12%  $0.42  session 23%→21:10  week 87%
```

| Segment | Meaning |
|---|---|
| `isTakipSistemi ⎇main` | current directory basename + git branch (if inside a repo) |
| `Sonnet 5 high` | active model + effort level (and `fast` when Fast Mode is on) |
| `ctx 12%` | context window used |
| `$0.42` | total cost for the current session |
| `session 23%→21:10` | 5-hour rate limit usage, and the local time it resets |
| `week 87%` | 7-day rate limit usage |

Percentages are colored green (`<60%`), yellow (`60–84%`), or red (`≥85%`) so you can tell at a glance when you're getting close to a limit. Any segment whose data isn't available (e.g. rate limits, which Claude Code only sends after the first API response and only for Claude subscribers) is silently omitted instead of showing as empty or broken.

## Requirements

- `bash`
- [`jq`](https://jqlang.org/) — used to parse the JSON Claude Code feeds to the statusline command
- `git` (optional — only needed for the branch segment)

## Install

**Option 1 — install script (recommended)**

```sh
git clone https://github.com/Mahmutakin99/claude-code-statusline.git
cd claude-code-statusline
./install.sh
```

This copies `statusline.sh` to `~/.claude/statusline.sh` and adds/updates the `statusLine` key in `~/.claude/settings.json` (an existing `settings.json` is backed up first, timestamped). Restart Claude Code afterwards.

**Option 2 — manual**

1. Download `statusline.sh` and place it wherever you like, e.g. `~/.claude/statusline.sh`.
2. Make it executable: `chmod +x ~/.claude/statusline.sh`.
3. Add this to `~/.claude/settings.json` (create the file if it doesn't exist):

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "/Users/you/.claude/statusline.sh"
     }
   }
   ```
4. Restart Claude Code, or open a new session.

## Customizing

Everything lives in one small script — open `statusline.sh` and edit directly:

- **Color thresholds**: the `hue()` function (green/yellow/red cutoffs, currently 60 and 85).
- **Segments**: each block (directory, branch, model, context, cost, session, week) is a self-contained `if` — comment one out or reorder them to taste.
- **Colors**: the `R`/`DIM`/`BLU`/`GRN`/`YEL`/`RED`/`MAG`/`CYN` variables at the top are standard ANSI escape codes.

## Uninstall

Remove the `statusLine` key from `~/.claude/settings.json` (or restore your `.bak.*` backup), then delete `~/.claude/statusline.sh`.

## How it works

Claude Code invokes the configured `statusLine.command` on every prompt render, piping a JSON payload (model, cost, context usage, rate limits, workspace info, …) to its stdin, and prints whatever the command writes to stdout. This script just reads that JSON with `jq` and formats it. See the [Claude Code statusline docs](https://docs.claude.com/en/docs/claude-code/statusline) for the full payload schema.

## License

MIT — see [LICENSE](LICENSE).
