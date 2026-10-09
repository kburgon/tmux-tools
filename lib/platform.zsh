# Platform detection shared by the tmux-tools plugin and scripts.
# Supports ChromeOS (Crostini), WSL2, and plain Linux.

# Print "wsl", "chromeos", or "linux".
function tt_platform {
	if [[ -n "$WSL_DISTRO_NAME" || -e /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
		print wsl
	elif [[ -e /dev/.cros_milestone ]]; then
		print chromeos
	else
		print linux
	fi
}

# Print a command that copies stdin to the local system clipboard, or nothing
# if none is available (the terminal's OSC 52 support is then the only path).
function tt_copy_cmd {
	if [[ -n "$WAYLAND_DISPLAY" ]] && (( $+commands[wl-copy] )); then
		print wl-copy
	elif [[ -n "$DISPLAY" ]] && (( $+commands[xclip] )); then
		print 'xclip -selection clipboard'
	elif [[ -n "$DISPLAY" ]] && (( $+commands[xsel] )); then
		print 'xsel -ib'
	elif (( $+commands[clip.exe] )); then
		print clip.exe
	fi
}

# Succeed if this machine is being used over ssh or mosh.
function tt_is_remote {
	[[ -n "$SSH_CONNECTION" || -n "$SSH_TTY" ]] || pgrep -x -u "$UID" mosh-server >/dev/null 2>&1
}

# Succeed if version $1 is at least $2 (dotted numbers; suffixes like "a" ignored).
function tt_version_ge {
	local -a have=(${(s:.:)${1//[^0-9.]/}}) want=(${(s:.:)2})
	local i
	for i in {1..$#want}; do
		(( ${have[i]:-0} > want[i] )) && return 0
		(( ${have[i]:-0} < want[i] )) && return 1
	done
	return 0
}
