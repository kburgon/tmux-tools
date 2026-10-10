#!/usr/bin/env zsh
# tmux-tools plugin: settings and key bindings. Load from ~/.tmux.conf with
#
#   run-shell ~/path/to/tmux-tools/tmux-tools.tmux
#
# (or as a TPM plugin). Options are read from @tmux-tools-* tmux options; set
# them before the run-shell line. A key option set to "none" disables it.

TT_DIR="${0:A:h}"
source "$TT_DIR/lib/platform.zsh"
source "$TT_DIR/lib/theme.zsh"
tt_load_opts

# Bind a root-table key to open bin/$2 in a popup. $1 is the option name.
function popup {
	local key=$(tt_opt "$1-key" "$5") script=$2 width=$3 height=$4 title=$6
	[[ $key == none ]] && return
	tmux bind -n "$key" display-popup -E -w "$width" -h "$height" -T " $title " "${(q)TT_DIR}/bin/$script"
}

tmux_version=$(tmux -V)
if ! tt_version_ge "${tmux_version#tmux }" 3.2; then
	tmux display-message "tmux-tools needs tmux 3.2+ (found ${tmux_version#tmux })"
	exit 0
fi

tmux set -g history-limit "$(tt_opt history-limit 50000)"
tmux set -g renumber-windows on

# New panes and windows start in the current pane's directory.
tmux bind '"' split-window -v -c '#{pane_current_path}'
tmux bind % split-window -h -c '#{pane_current_path}'
tmux bind c new-window -c '#{pane_current_path}'

# Clipboard: OSC 52 reaches the local terminal even through ssh/mosh; a native
# copy command (wl-copy, xclip, clip.exe) covers terminals that ignore OSC 52.
tmux set -g set-clipboard on
copy_cmd=$(tt_copy_cmd)
[[ -n "$copy_cmd" ]] && tmux set -s copy-command "$copy_cmd"
tmux bind -T copy-mode-vi v send -X begin-selection
tmux bind -T copy-mode-vi y send -X copy-pipe-and-cancel

# Remember whether this is a remote machine, for the theme's host badge.
tt_is_remote && tmux set -g @tmux-tools-is-remote 1 && tt_opts[is-remote]=1

# Theme, status bar, and off-mode bindings (see lib/theme.zsh).
tt_apply_theme "$(tt_current_theme)"

popup projects tmux-project-picker 80% 70% M-S Projects
popup claude tmux-claude-sessions 80% 80% M-C 'Claude sessions'
popup hosts tmux-host-picker 80% 70% M-H Hosts
popup docker tmux-docker-picker 80% 80% M-D Containers
popup theme tmux-theme-picker 70% 50% none Themes

tmux set -g @tmux-tools-loaded 1
