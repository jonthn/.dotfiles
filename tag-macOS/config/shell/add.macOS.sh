# launchd script for environment {{{

macOS_local_launchd()
{
	mkdir -p ~/Library/LaunchAgents/
	sed -e s,PATH_SCRIPT_CHANGE,${XDG_CONFIG_HOME:-${HOME}/.config}/macOS/launchd.local.sh, "${XDG_DATA_HOME:-${HOME}/.local/share}"/macOS/local.launchd.conf.plist > ~/Library/LaunchAgents/local.launchd.conf.plist
}

# }}}

# vim: set ft=sh ts=8 sw=8 tw=0 noet fdm=marker:
