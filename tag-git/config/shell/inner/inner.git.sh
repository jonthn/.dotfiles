shf_git_gitwtf_update()
{
	_inform 'Updating git wtf ...\n'
	local temp_gitwtf
	temp_gitwtf="$(mktemp -q)"
	if command -v curl >/dev/null 2>&1; then
		curl -fkLo "${temp_gitwtf}" https://raw.githubusercontent.com/bsedat/git-wtf/master/git-wtf
	elif command -v wget >/dev/null 2>&1; then
		wget -O "${temp_gitwtf}" https://raw.githubusercontent.com/bsedat/git-wtf/master/git-wtf
	else
		_fault "Can't download git wtf script, cancelling update\n"
		return 1
	fi

	if [ -f "${temp_gitwtf}" ] && [ -d "${_base_localprefix}/bin" ]; then
		install -v -m 0755 "${temp_gitwtf}" "${_base_localprefix}/bin/wtf-git"
		_inform "git-wtf script has been updated\n"
	fi

	rm "${temp_gitwtf}"
}

# vim: set ft=sh ts=8 noet :
