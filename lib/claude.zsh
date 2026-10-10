# Reading Claude Code's session registry (~/.claude/sessions/<pid>.json).

# Print one tab-separated line per live session:
#   name, status, cwd, tmux location ("session:@window.%pane", or "-"), updated (ms epoch)
# Entries whose process has exited, or whose pid was reused, are skipped.
function tt_claude_sessions {
	local -a files=("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/sessions"/<->.json(N))
	(( $#files )) || return 0

	local pid proc_start rest stat
	# Empty fields would collapse under IFS=$'\t', so jq emits "-" instead.
	jq -r '[.pid, .procStart, .name, .status, .cwd, (.tmux // "-" | if . == "" then "-" else . end), (.statusUpdatedAt // .updatedAt)] | @tsv' $files |
		while IFS=$'\t' read -r pid proc_start rest; do
			[[ -r /proc/$pid/stat ]] || continue
			stat=$(</proc/$pid/stat)
			stat=${stat##*) }
			[[ ${${=stat}[20]} == "$proc_start" ]] || continue
			print -r -- "$rest"
		done
}
