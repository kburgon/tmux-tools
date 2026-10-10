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

# Theme: a palette from themes/<name>.zsh (or a path to a theme file), with
# per-colour overrides from @tmux-tools-color-<name>. The palette is loaded even
# with the theme set to "none", since off mode and the remote badge use it.
theme=$(opt theme default)
theme_file=$theme
[[ $theme == */* ]] || theme_file="$DIR/themes/$theme.zsh"
if [[ $theme != none && ! -r $theme_file ]]; then
	tmux display-message "tmux-tools: theme not found: $theme"
	theme_file="$DIR/themes/default.zsh"
fi
palette=(accent on_accent surface text highlight muted border border_active busy waiting idle remote)
source "$DIR/themes/default.zsh"
[[ $theme != none ]] && source "$theme_file"
for line in ${(f)"$(tmux show -g | grep '^@tmux-tools-color-')"}; do
	name=${${${line%% *}#@tmux-tools-color-}//-/_}
	(( ${palette[(Ie)$name]} )) && typeset -g "$name=${(Q)line#* }"
done

# Pill end caps: Nerd Font half circles by default; "none" for square ends.
L=$(opt cap-left $'\ue0b6') R=$(opt cap-right $'\ue0b4')
[[ $L == none ]] && L=
[[ $R == none ]] && R=

# Quote an argument for a #() status command: shell single quotes, with '#'
# doubled so tmux's format expansion leaves it alone. (Values never contain
# single quotes: they're colours, glyphs, and the repo path.)
function job_arg {
	print -rn -- "'${1//\#/##}'"
}

if [[ $theme != none ]]; then
	tmux set -g status-style "fg=$accent,bg=default"
	tmux set -g status-interval "$(opt status-interval 5)"
	tmux set -g pane-border-style "fg=$border"
	tmux set -g pane-active-border-style "fg=$border_active"
	tmux set -g mode-style "fg=$on_accent,bg=$accent,bold"
	tmux set -g message-style "fg=$on_accent,bg=$accent,bold"
	tmux set -g message-command-style "fg=$on_accent,bg=$accent,bold"
	tmux set -g clock-mode-colour "$border_active"
	tt_version_ge "${tmux_version#tmux }" 3.3 && tmux set -g popup-border-style "fg=$border"

	# Windows float as pills over the terminal background.
	tmux set -g window-status-separator ' '
	tmux set -g window-status-format \
		"#[fg=$surface,bg=default]$L#[fg=$accent,bg=$surface]#I #[fg=$text]#W #[fg=$accent]#F#[fg=$surface,bg=default]$R"
	tmux set -g window-status-current-format \
		"#[fg=$accent,bg=default]$L#[fg=$on_accent,bg=$accent]#I #W #F#[fg=$accent,bg=default]$R"
	tmux set -g window-status-bell-style "fg=$on_accent,bg=$accent,bold"

	# Right: Claude agents by status, then session name and date/time in one pill.
	agents="#($(job_arg $DIR/bin/tmux-claude-status)"
	for arg in $surface $busy $waiting $idle $text $L $R; do
		agents+=" $(job_arg $arg)"
	done
	agents+=")"
	tmux set -g status-right-length 100
	tmux set -g status-right "$agents#[fg=$surface,bg=default]$L#[fg=$highlight,bg=$surface] #S \
#[fg=$accent]$L#[fg=$on_accent,bg=$accent] %Y-%m-%d %H:%M #[fg=$accent,bg=default]$R"
fi

# Off mode for nested tmux: the toggle key disables this tmux's prefix and root
# bindings so every key reaches the tmux running inside it (e.g. over ssh).
# Settings are per-session, so unsetting them restores the global values.
off_key=$(opt off-key M-:)
if [[ $off_key != none ]]; then
	tmux bind -T root "$off_key" "set prefix None ; set key-table off ; \
set status-style 'fg=$muted,bg=default' ; \
set status-left '#[fg=$busy,bg=default]$L#[fg=$on_accent,bg=$busy,bold]OFF#[fg=$busy,bg=default,nobold]$R ' ; \
refresh-client -S"
	tmux bind -T off "$off_key" "set -u prefix ; set -u key-table ; \
set -u status-style ; set -u status-left ; refresh-client -S"
fi

# Show the host name on the left of the status bar on remote machines, so
# it's obvious which tmux is which.
if [[ $(opt remote-badge on) == on ]] && tt_is_remote; then
	tmux set -g status-left "#[fg=$remote,bg=default]$L#[fg=$on_accent,bg=$remote,bold]#h#[fg=$remote,bg=default,nobold]$R "
	tmux set -g status-left-length 30
fi

popup projects tmux-project-picker 80% 70% M-S Projects
popup claude tmux-claude-sessions 80% 80% M-C 'Claude sessions'
popup hosts tmux-host-picker 80% 70% M-H Hosts
popup docker tmux-docker-picker 80% 80% M-D Containers

tmux set -g @tmux-tools-loaded 1
