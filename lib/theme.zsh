# Theme loading and application for the tmux-tools plugin and theme picker.
# Requires TT_DIR to be set to the repo root.

tt_palette=(accent on_accent surface text highlight muted border border_active busy waiting idle remote)
tt_theme_state="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-tools/theme"
tt_user_themes="${XDG_CONFIG_HOME:-$HOME/.config}/tmux-tools/themes"

# Load every @tmux-tools-* option into the tt_opts associative array, keyed
# without the prefix, using a single tmux call.
function tt_load_opts {
	typeset -gA tt_opts=()
	local line
	for line in ${(f)"$(tmux show -g 2>/dev/null | grep '^@tmux-tools-')"}; do
		tt_opts[${${line%% *}#@tmux-tools-}]=${(Q)line#* }
	done
}

# Print option $1 from tt_opts, or $2 if unset.
function tt_opt {
	print -r -- "${tt_opts[$1]:-$2}"
}

# Print the selected theme: @tmux-tools-theme, else the theme picker's saved
# choice, else "default".
function tt_current_theme {
	local saved
	[[ -r $tt_theme_state ]] && saved=$(<$tt_theme_state)
	print -r -- "${tt_opts[theme]:-${saved:-default}}"
}

# Print the file for theme $1: a path as given, else ~/.config/tmux-tools/themes
# before the repo's themes/. Fails if there's no such theme.
function tt_theme_file {
	local f
	for f in $1 "$tt_user_themes/$1.zsh" "$TT_DIR/themes/$1.zsh"; do
		[[ $f == */* && -r $f ]] && { print -r -- "$f"; return 0 }
	done
	return 1
}

# Print theme names: user themes first, then the repo's, without duplicates.
function tt_theme_names {
	local -a names=($tt_user_themes/*.zsh(N:t:r) $TT_DIR/themes/*.zsh(N:t:r))
	print -l -- ${(u)names}
}

# Set the palette variables for theme $1 ("none" gives the default palette),
# then apply @tmux-tools-color-* overrides from tt_opts.
function tt_load_palette {
	local file name
	source "$TT_DIR/themes/default.zsh"
	if [[ $1 != none ]] && file=$(tt_theme_file "$1"); then
		source "$file"
	fi
	for name in ${(k)tt_opts[(I)color-*]}; do
		name=${${name#color-}//-/_}
		(( ${tt_palette[(Ie)$name]} )) && typeset -g "$name=${tt_opts[color-${name//_/-}]}"
	done
}

# Apply theme $1 to the running tmux server in one batched tmux call: status
# bar, window pills, pane borders, off-mode bindings, and the remote badge.
# Expects tt_opts to be loaded.
function tt_apply_theme {
	local theme=$1
	if [[ $theme != none ]] && ! tt_theme_file "$theme" >/dev/null; then
		tmux display-message "tmux-tools: theme not found: $theme"
		theme=default
	fi
	tt_load_palette "$theme"

	# Pill end caps: Nerd Font half circles by default; "none" for square ends.
	local L=$(tt_opt cap-left $'') R=$(tt_opt cap-right $'')
	[[ $L == none ]] && L=
	[[ $R == none ]] && R=

	local -a cmds
	function cmd { cmds+=("$@" ';') }

	if [[ $theme != none ]]; then
		cmd set -g status-style "fg=$accent,bg=default"
		cmd set -g status-interval "$(tt_opt status-interval 5)"
		cmd set -g pane-border-style "fg=$border"
		cmd set -g pane-active-border-style "fg=$border_active"
		cmd set -g mode-style "fg=$on_accent,bg=$accent,bold"
		cmd set -g message-style "fg=$on_accent,bg=$accent,bold"
		cmd set -g message-command-style "fg=$on_accent,bg=$accent,bold"
		cmd set -g clock-mode-colour "$border_active"
		tt_version_ge "${$(tmux -V)#tmux }" 3.3 && cmd set -g popup-border-style "fg=$border"

		# Windows float as pills over the terminal background.
		cmd set -g window-status-separator ' '
		cmd set -g window-status-format \
			"#[fg=$surface,bg=default]$L#[fg=$accent,bg=$surface]#I #[fg=$text]#W #[fg=$accent]#F#[fg=$surface,bg=default]$R"
		cmd set -g window-status-current-format \
			"#[fg=$accent,bg=default]$L#[fg=$on_accent,bg=$accent]#I #W #F#[fg=$accent,bg=default]$R"
		cmd set -g window-status-bell-style "fg=$on_accent,bg=$accent,bold"

		# Right: Claude agents by status, then session name and date/time in one pill.
		local agents="#($(tt_job_arg $TT_DIR/bin/tmux-claude-status)" arg
		for arg in $surface $busy $waiting $idle $text $L $R; do
			agents+=" $(tt_job_arg $arg)"
		done
		agents+=")"
		cmd set -g status-right-length 100
		cmd set -g status-right "$agents#[fg=$surface,bg=default]$L#[fg=$highlight,bg=$surface] #S \
#[fg=$accent]$L#[fg=$on_accent,bg=$accent] %Y-%m-%d %H:%M #[fg=$accent,bg=default]$R"
	fi

	# Off mode for nested tmux: the toggle key disables this tmux's prefix and
	# root bindings so every key reaches the tmux running inside it (e.g. over
	# ssh). Settings are per-session, so unsetting them restores the globals.
	local off_key=$(tt_opt off-key M-:)
	if [[ $off_key != none ]]; then
		cmd bind -T root "$off_key" "set prefix None ; set key-table off ; \
set status-style 'fg=$muted,bg=default' ; \
set status-left '#[fg=$busy,bg=default]$L#[fg=$on_accent,bg=$busy,bold]OFF#[fg=$busy,bg=default,nobold]$R ' ; \
refresh-client -S"
		cmd bind -T off "$off_key" "set -u prefix ; set -u key-table ; \
set -u status-style ; set -u status-left ; refresh-client -S"
	fi

	# Host name badge on remote machines (detected once by the plugin).
	if [[ $(tt_opt remote-badge on) == on && -n ${tt_opts[is-remote]} ]]; then
		cmd set -g status-left "#[fg=$remote,bg=default]$L#[fg=$on_accent,bg=$remote,bold]#h#[fg=$remote,bg=default,nobold]$R "
		cmd set -g status-left-length 30
	fi

	tmux "${(@)cmds[1,-2]}"
}

# Quote an argument for a #() status command: shell single quotes, with '#'
# doubled so tmux's format expansion leaves it alone. (Values never contain
# single quotes: they're colours, glyphs, and the repo path.)
function tt_job_arg {
	print -rn -- "'${1//\#/##}'"
}
