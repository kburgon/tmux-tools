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

Opens an fzf picker of running Claude Code sessions: name, status (`busy`/`idle`),
tmux location (`session:window.pane`), window name, working directory, and when
the status last changed. The preview shows the live contents of the session's
pane. Press `Enter` to jump to that session's tmux session, window, and pane;
`Ctrl+R` refreshes, `Esc` closes. Inside tmux it opens in an 80%×80% popup;
outside tmux it runs inline and attaches on selection.

Data comes from the registry Claude Code writes to `~/.claude/sessions/<pid>.json`
(or `$CLAUDE_CONFIG_DIR/sessions`); entries whose process has exited are skipped. The tmux pane is resolved from the
pane id the registry records, so it stays correct after sessions or windows are
renamed or moved. Requires `jq`.
