# tmux session utilities. Source from ~/.zshrc.

SESSION_TOOLS_DIR="${0:A:h}"
path=("$SESSION_TOOLS_DIR/bin" $path)

# tp: pick a project and open a tmux session in it.
# Inside tmux the picker runs in a popup; outside it runs inline.
function tp {
	local picker="$SESSION_TOOLS_DIR/bin/tmux-project-picker"
	if [[ -n "$TMUX" ]]; then
		tmux display-popup -E -w 80% -h 70% -T ' Projects ' "$picker"
	else
		"$picker"
	fi
}

# tcs: show running Claude Code sessions and their status.
# Inside tmux the table shows in a popup; outside it runs inline.
function tcs {
	local viewer="$SESSION_TOOLS_DIR/bin/tmux-claude-sessions"
	if [[ -n "$TMUX" ]]; then
		tmux display-popup -E -w 80% -h 80% -T ' Claude sessions ' "$viewer"
	else
		"$viewer"
	fi
}
