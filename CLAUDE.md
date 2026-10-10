# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal zsh + tmux utilities. No build step, no test suite. Must work on ChromeOS (Crostini), plain Linux, and WSL2 (Debian/Ubuntu userlands; GNU find, util-linux `column`). Runtime deps: `tmux` 3.2+, `fzf` 0.29+, `jq`; optional `tree`, `mosh`, `docker`. See README.md for user-facing behavior.

## Structure

- `bin/` — standalone zsh scripts that do the work. Each runs either inside a tmux popup or inline in a terminal, so they check `$TMUX` to decide between tmux commands (`switch-client`, `new-window`) and running inline (`attach-session`, `exec`).
- `session-tools.zsh` — sourced from `~/.zshrc`; adds `bin/` to `$path` and defines thin wrapper functions (`tp`, `tcs`, `th`, `td`) that open the matching script in `tmux display-popup` when inside tmux, else run it directly.
- `tmux-tools.tmux` — the tmux plugin (TPM convention), loaded by a `run-shell` line in `~/.tmux.conf`. It's a zsh script issuing `tmux set`/`tmux bind` against the server that ran it. Popup keybindings are built from the script's own directory, so the repo can live anywhere. Popup sizes are duplicated between this file and `session-tools.zsh`; change both. Options are `@tmux-tools-*`, read with `tmux show -gqv`.
- `lib/claude.zsh` — `tt_claude_sessions` reads the Claude Code session registry and filters stale entries; used by `tmux-claude-sessions` and `tmux-claude-status`.
- `lib/platform.zsh` — shared helpers (`tt_platform`, `tt_copy_cmd`, `tt_is_remote`, `tt_version_ge`), sourced by the plugin and `bin/tmux-tools-doctor`. Put platform-specific branching here rather than in individual scripts.
- The user keeps changes out of `~/.tmux.conf`/`~/.zshrc`; new settings go in the plugin, not their dotfiles.

## Picker pattern

Every picker follows `bin/tmux-claude-sessions`:
- A `--list` mode prints `<hidden key>\t<display>` lines (header first where there is one). Interactive mode pipes it into fzf with `--delimiter='\t' --with-nth=...` to hide the key, and calls itself with `--list` for `ctrl-r` reload.
- fzf `execute(...)` actions call back into the script with a subcommand (e.g. `--kill`, `--restart`) so confirmations and logic stay in zsh.
- ANSI coloring is applied after `column -t` so alignment isn't broken.
- Preview and `execute` commands run under the user's `$SHELL`, which may be bash on servers; keep them POSIX-ish.
- Stick to fzf features available in 0.29 (Ubuntu 22.04): use `--expect` for alternate keys, not `become`.

## Claude sessions (`bin/tmux-claude-sessions`)

- Reads Claude Code's session registry at `${CLAUDE_CONFIG_DIR:-~/.claude}/sessions/<pid>.json` (`name`, `status`, `cwd`, `tmux`, `statusUpdatedAt`, `pid`, `procStart`).
- Stale entries are filtered by checking `/proc/<pid>/stat` field 22 (start time) against `procStart`, which guards against pid reuse.
- The registry's `tmux` field is `session:@window.%pane`; only the `%pane` id is used, because it survives session/window renames and moves. `tmux-project-picker` reuses `--list` to find which tmux sessions are running Claude.

## Themes

`themes/<name>.zsh` files only assign palette variables (listed in `palette` in `tmux-tools.tmux`; add new ones there too). The plugin always sources `default.zsh` first, so themes may omit colours, then applies `@tmux-tools-color-*` overrides. All styles and formats are built from the palette in the plugin; themes contain no tmux syntax. The agents segment comes from `#(bin/tmux-claude-status <colours...>)`. Arguments go through `job_arg`, which doubles `#` so tmux format expansion doesn't eat hex colours. `%` in status formats is strftime-expanded, so don't pass it to jobs.

## Off mode

The plugin's off key (default `M-:`) sets session-level `prefix None`, `key-table off`, `status-style`, and `status-left`. Turning it back on unsets them, so the global values come back. Root-table (`-n`) bindings don't fire while `key-table` is `off`, which is what lets keys pass through to a nested remote tmux.

## Checking changes

- `zsh -n bin/* tmux-tools.tmux lib/platform.zsh session-tools.zsh` for syntax.
- Run a picker's `--list` and pipe it through `fzf --filter=<text> --delimiter='\t' --with-nth=...` to check the hidden key comes back.
- Test the plugin on a throwaway server, not the user's live one: `tmux -L tt-test -f /dev/null new -d`, `tmux -L tt-test run-shell $PWD/tmux-tools.tmux`, inspect with `list-keys`/`show -g`, then `kill-server`.
- To see a rendered status line, attach a client on the throwaway server under `script -qc 'tmux -L tt-test attach' /dev/null` and inspect its output; `display -p` doesn't run `#()` jobs.
- `bin/tmux-tools-doctor` reports platform and dependencies. Simulate WSL with `WSL_DISTRO_NAME=x`.
- Keep README.md in sync when behavior or keybindings change.
