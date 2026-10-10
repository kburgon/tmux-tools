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

# tcs: pick a running Claude Code session and jump to its tmux pane.
# Inside tmux the picker shows in a popup; outside it runs inline.
function tcs {
	local viewer="$SESSION_TOOLS_DIR/bin/tmux-claude-sessions"
	if [[ -n "$TMUX" ]]; then
		tmux display-popup -E -w 80% -h 80% -T ' Claude sessions ' "$viewer"
	else
		"$viewer"
	fi
}

# th: pick an ssh host and connect, attaching to tmux on the host.
# Inside tmux the picker shows in a popup; outside it runs inline.
function th {
	local picker="$SESSION_TOOLS_DIR/bin/tmux-host-picker"
	if [[ -n "$TMUX" ]]; then
		tmux display-popup -E -w 80% -h 70% -T ' Hosts ' "$picker"
	else
		"$picker"
	fi
}

# td: pick a running docker container and open a shell or its logs.
# Inside tmux the picker shows in a popup; outside it runs inline.
function td {
	local picker="$SESSION_TOOLS_DIR/bin/tmux-docker-picker"
	if [[ -n "$TMUX" ]]; then
		tmux display-popup -E -w 80% -h 80% -T ' Containers ' "$picker"
	else
		"$picker"
	fi
}

# tt-theme: pick a theme, previewing each one live on the status bar.
# Inside tmux the picker shows in a popup; outside it runs inline.
function tt-theme {
	local picker="$SESSION_TOOLS_DIR/bin/tmux-theme-picker"
	if [[ -n "$TMUX" ]]; then
		tmux display-popup -E -w 70% -h 50% -T ' Themes ' "$picker"
	else
		"$picker"
	fi
}

# tt-doctor: report the platform and which dependencies are installed.
alias tt-doctor=tmux-tools-doctor
