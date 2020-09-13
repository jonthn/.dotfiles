# Search in history {{{


unalias h 2>/dev/null

h() {
	if [ $# = 0 ]; then
		printf 'usage: h search_history\n'
		return 1
	fi

	case $(__shell) in
		mksh|zsh)
			fc -l 0 | grep "$@"
			;;
		*)
			history | grep "$@"
			;;
	esac
}
# }}}

# Delete .DS_Store and __MACOSX directories {{{
rm_osx_cruft() {
	find "${@:-$PWD}" \( \
		-type f -name '.DS_Store' -o \
		-type d -name '__MACOSX' \
		\) -print0 | xargs -0 rm -rf
}
# }}}

# SSH without host check & store {{{

ssh_anonymous() {
	ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" "$@"
}

scp_anonymous() {
	scp -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" "$@"
}

# }}}

# vim: set ft=sh ts=8 sw=8 tw=0 noet fdm=marker:
