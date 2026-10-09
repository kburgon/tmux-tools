#!/usr/bin/env zsh
# tmux-tools plugin: settings and key bindings. Load from ~/.tmux.conf with
#
#   run-shell ~/path/to/tmux-tools/tmux-tools.tmux
#
# (or as a TPM plugin). Options are read from @tmux-tools-* tmux options; set
# them before the run-shell line. A key option set to "none" disables it.

DIR="${0:A:h}"
source "$DIR/lib/platform.zsh"

# Print the value of @tmux-tools-$1, or $2 if unset.
function opt {
	local v=$(tmux show -gqv "@tmux-tools-$1")
	print -r -- "${v:-$2}"
}

# Bind a root-table key to open bin/$2 in a popup. $1 is the option name.
function popup {
	local key=$(opt "$1-key" "$5") script=$2 width=$3 height=$4 title=$6
	[[ $key == none ]] && return
	tmux bind -n "$key" display-popup -E -w "$width" -h "$height" -T " $title " "${(q)DIR}/bin/$script"
}

tmux_version=$(tmux -V)
if ! tt_version_ge "${tmux_version#tmux }" 3.2; then
	tmux display-message "tmux-tools needs tmux 3.2+ (found ${tmux_version#tmux })"
	exit 0
fi

tmux set -g history-limit "$(opt history-limit 50000)"
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

# Off mode for nested tmux: the toggle key disables this tmux's prefix and root
# bindings so every key reaches the tmux running inside it (e.g. over ssh).
# Settings are per-session, so unsetting them restores the global values.
off_key=$(opt off-key F12)
if [[ $off_key != none ]]; then
	tmux bind -T root "$off_key" "set prefix None ; set key-table off ; \
set status-style 'fg=colour238 bg=default' ; \
set status-left '#[fg=black,bg=yellow,bold] OFF #[default] ' ; refresh-client -S"
	tmux bind -T off "$off_key" "set -u prefix ; set -u key-table ; \
set -u status-style ; set -u status-left ; refresh-client -S"
fi

# Show the host name on the left of the status bar on remote machines, so
# it's obvious which tmux is which.
if [[ $(opt remote-badge on) == on ]] && tt_is_remote; then
	tmux set -g status-left '#[fg=black,bg=magenta,bold] #h #[default] '
	tmux set -g status-left-length 30
fi

popup projects tmux-project-picker 80% 70% M-S Projects
popup claude tmux-claude-sessions 80% 80% M-C 'Claude sessions'
popup hosts tmux-host-picker 80% 70% M-H Hosts
popup docker tmux-docker-picker 80% 80% M-D Containers

tmux set -g @tmux-tools-loaded 1
