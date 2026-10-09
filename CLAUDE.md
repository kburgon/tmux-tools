# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal zsh + tmux utilities. No build step, no test suite. Runtime deps: `tmux` (3.2+ for popups), `fzf`, `jq`, `tree`. See README.md for user-facing behavior.

## Structure

- `bin/` — standalone zsh scripts that do the work. Each runs either inside a tmux popup or inline in a terminal, so they check `$TMUX` to decide between `tmux switch-client` (inside) and `tmux attach-session` (outside).
- `session-tools.zsh` — sourced from `~/.zshrc`; adds `bin/` to `$path` and defines thin wrapper functions (`tp`, `tcs`) that open the matching script in `tmux display-popup` when inside tmux, else run it directly.
- `~/.tmux.conf` (outside this repo) also binds the scripts directly to keys (`M-S` → project picker, `M-C` → Claude sessions) with its own popup sizes. If you change a script's path or popup size, update both the zsh wrapper and that tmux binding.

## Claude sessions picker (`bin/tmux-claude-sessions`)

- Reads Claude Code's session registry at `${CLAUDE_CONFIG_DIR:-~/.claude}/sessions/<pid>.json` (`name`, `status`, `cwd`, `tmux`, `statusUpdatedAt`, `pid`, `procStart`).
- Stale entries are filtered by checking `/proc/<pid>/stat` field 22 (start time) against `procStart`, which guards against pid reuse. Linux-only.
- The registry's `tmux` field is `session:@window.%pane`; only the `%pane` id is used, because it survives session/window renames and moves. Current location and window name are resolved via `tmux display-message -t %pane`.
- `--list` prints the rows (`<pane-id>\t<column-aligned text>`, header first, `-` for sessions not in tmux). The interactive mode pipes that into fzf with `--with-nth=2..` to hide the pane id, and calls itself with `--list` for `ctrl-r` reload. ANSI coloring is applied after `column -t` so alignment isn't broken.

## Conventions

- zsh scripts with tab indentation, `#!/usr/bin/env zsh`, zsh-native idioms (glob qualifiers like `<->.json(N)`, `${(@f)...}`, `$EPOCHSECONDS`).
- Check syntax with `zsh -n bin/<script>`. Test the Claude list non-interactively with `bin/tmux-claude-sessions --list`.
- Keep README.md's command docs in sync when behavior or keybindings change.
