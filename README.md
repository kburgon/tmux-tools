# session-tools

Utilities for working with tmux sessions.

## Setup

Add to `~/.zshrc`:

```zsh
source ~/Apps/session-tools/session-tools.zsh
```

Requires `tmux` (3.2+ for popups), `fzf`, and `tree` (for previews).

## Commands

### `tp`

Opens an fzf picker of the directories directly inside `~/Projects`. Selecting one creates a tmux session rooted in that
directory, or switches to it if it already exists. Inside tmux the picker
shows in a popup; outside tmux it runs inline and then attaches.

Also bound in tmux to `Alt+Shift+S` (`M-S` in `~/.tmux.conf`).

Environment overrides:

- `PROJECTS_DIR`: root to search (default `~/Projects`)
- `PROJECTS_DEPTH`: max `find` depth (default `1`)

### `tcs`

Shows a table of running Claude Code sessions: name, status (`busy`/`idle`),
tmux location, working directory, and when the status last changed. Inside tmux
it opens in an 80%×80% popup; outside tmux it prints inline. Press `r` to
refresh, any other key to close.

Data comes from the registry Claude Code writes to `~/.claude/sessions/<pid>.json`
(or `$CLAUDE_CONFIG_DIR/sessions`); entries whose process has exited are skipped.
Requires `jq`.
