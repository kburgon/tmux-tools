# tmux-tools

Utilities for working with tmux sessions: project, Claude session, ssh host,
and docker container pickers, plus a tmux plugin with settings for remote
development. Works on ChromeOS (Crostini), Linux, and WSL2.

## Setup

Clone the repository:

```zsh
git clone git@github.com:kburgon/tmux-tools.git ~/Apps/tmux-tools
```

Add to `~/.zshrc` (adjust the path if you cloned elsewhere):

```zsh
source ~/Apps/tmux-tools/session-tools.zsh
```

Add to the end of `~/.tmux.conf` to load the plugin (or list `kburgon/tmux-tools`
as a [TPM](https://github.com/tmux-plugins/tpm) plugin):

```tmux
run-shell ~/Apps/tmux-tools/tmux-tools.tmux
```

Then run `tt-doctor` to check the platform and dependencies. Requires `tmux`
3.2+, `fzf` 0.29+, and `jq`; `tree`, `mosh`, and `docker` are optional.

On servers, do the same setup there. `td` and the remote status badge are meant
for tmux running on the server.

## tmux plugin

`tmux-tools.tmux` applies:

| Setting | Effect |
| --- | --- |
| `M-:` | Off mode: this tmux ignores its prefix and key bindings, so keys reach a tmux running inside it (e.g. over ssh). The status bar dims and shows `OFF`; press `M-:` again to turn it back on. |
| Theme | Pane borders, window pills, and status bar styled from one palette (see [Themes](#themes)) |
| Status right | Claude agent counts by status (`●` busy, `◐` waiting, `○` idle), then session name, then date and time |
| `M-S` / `M-C` / `M-H` / `M-D` | Popups for `tp`, `tcs`, `th`, `td` |
| `prefix "` / `%` / `c` | Splits and new windows open in the current pane's directory |
| copy mode `v` / `y` | Begin selection / copy and exit (vi mode keys) |
| `set-clipboard on` | Copies reach the local clipboard via OSC 52, including through ssh and mosh |
| `copy-command` | Set to `wl-copy`, `xclip`, `xsel`, or `clip.exe` when found, for terminals without OSC 52 |
| `history-limit 50000`, `renumber-windows on` | |
| Remote badge | Over ssh/mosh, the host name shows at the left of the status bar |

Options (set in `~/.tmux.conf` before the `run-shell` line; `none` disables a key):

```tmux
set -g @tmux-tools-off-key M-:
set -g @tmux-tools-projects-key M-S
set -g @tmux-tools-claude-key M-C
set -g @tmux-tools-hosts-key M-H
set -g @tmux-tools-docker-key M-D
set -g @tmux-tools-history-limit 50000
set -g @tmux-tools-remote-badge on
set -g @tmux-tools-theme default         # theme name, a path to a theme file, or none
set -g @tmux-tools-theme-key none        # key for the tt-theme popup
set -g @tmux-tools-color-accent '#88c0d0' # override any palette colour
set -g @tmux-tools-cap-left none         # pill end caps; none for square ends
set -g @tmux-tools-cap-right none
set -g @tmux-tools-status-interval 5     # seconds between agent count refreshes
```

## Themes

Windows and status segments are drawn as pills floating over the terminal's own
background. Colours come from a palette in `themes/<name>.zsh`; included themes
are `default` (green), `nord`, and `gruvbox`.

Run `tt-theme` to pick one: each theme is applied live as you move through the
list, with its palette and a mock status bar in the preview. `Enter` keeps it
and `Esc` restores the previous theme. The choice is saved to
`~/.config/tmux-tools/theme`, so it survives restarts without touching
`~/.tmux.conf`. Setting `@tmux-tools-theme` in `~/.tmux.conf` takes precedence over it.
Live preview needs fzf 0.33+.

To make your own theme, copy one into `~/.config/tmux-tools/themes/` (or
`themes/` in the repo), change the values (colour names, `colourN`, or
`#rrggbb`), and pick it with `tt-theme`. Colours a theme leaves out fall back to
`default`.

| Colour | Used for |
| --- | --- |
| `accent` / `on_accent` | Current window, date pill, copy mode, messages / text on them |
| `surface` / `text` | Other windows, agents, session pill / window names on them |
| `highlight` | Session name |
| `border` / `border_active` | Pane borders / active pane border and clock |
| `busy` / `waiting` / `idle` | Claude agent counts |
| `muted` | Status text in off mode |
| `remote` | Host badge on remote machines |

The pill ends use Nerd Font half circles. If your font doesn't have them, set
`@tmux-tools-cap-left` and `@tmux-tools-cap-right` to `none`.

The plugin replaces any status and window styles set earlier in `~/.tmux.conf`,
so those lines can be removed.

## Commands

### `tp`

Opens an fzf picker of the directories directly inside `~/Projects`. Selecting one creates a tmux session rooted in that
directory, or switches to it if it already exists. Projects with an open session
are marked `●`, and `(claude)` when a Claude session is running in it. `Ctrl+X`
kills the highlighted project's session (asking first if Claude is running there);
`Ctrl+R` refreshes. Inside tmux the picker shows in a popup; outside tmux it runs
inline and then attaches.

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
renamed or moved.

### `th`

Opens an fzf picker of ssh hosts, previewing each one's resolved `HostName`,
`User`, and `Port`. `Enter` connects with mosh (ssh if mosh isn't installed) and
attaches to a tmux session on the host, creating it if needed; `Ctrl+S` does the
same over ssh; `Alt+Enter` opens a plain shell without remote tmux. Inside tmux
the connection opens in a window named after the host, or switches to it if
one is already open.

Hosts come from `Host` entries in `~/.ssh/config` (wildcards skipped) and one
name per line in `~/.config/tmux-tools/hosts`.

Environment overrides:

- `TMUX_TOOLS_SSH_CONFIGS`: extra ssh config files to read, colon-separated
- `TMUX_TOOLS_HOSTS`: hosts file (default `~/.config/tmux-tools/hosts`)
- `TMUX_TOOLS_REMOTE_SESSION`: remote tmux session name (default `main`)

To use local and remote tmux together, press `M-:` after connecting so your keys
go to the remote tmux.

### `td`

Opens an fzf picker of running docker containers, previewing recent logs.
`Enter` opens a shell in the container (`bash` if present, else `sh`) in a new
window; `Ctrl+L` follows its logs; `Ctrl+X` restarts it (asking first); `Ctrl+R`
refreshes.

### `tt-theme`

Theme picker; see [Themes](#themes).

### `tt-doctor`

Prints the detected platform (`chromeos`, `wsl`, or `linux`), whether required
and optional tools are installed (with install hints), how copying reaches the
clipboard, and whether the tmux plugin is loaded.

## Platform notes

- **ChromeOS**: the Terminal app supports OSC 52, so copying works without extra
  tools.
- **WSL2**: Windows Terminal supports OSC 52, and `clip.exe` is used as a
  fallback. If your ssh config lives on the Windows side, point
  `TMUX_TOOLS_SSH_CONFIGS` at it (e.g. `/mnt/c/Users/<you>/.ssh/config`).
  `td` works locally with Docker Desktop's WSL integration.
- **Linux**: some terminals (e.g. GNOME Terminal) ignore OSC 52; install
  `wl-clipboard` (Wayland) or `xclip` (X11) and the plugin uses it.
