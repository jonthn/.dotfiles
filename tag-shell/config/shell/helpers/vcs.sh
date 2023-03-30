__vcs_root() {

	[ 1 = $#  ] || return 1
	[ -z "$1" ] && return 1

	local vcs_root=

	case $1 in
		git)
			vcs_root=$(git rev-parse --show-toplevel 2>/dev/null)

			[ -z "$vcs_root" ] && return 1

			if [ ! -z "$vcs_root" ] && [ "--show-toplevel" = "$vcs_root" ]; then
				local rel
				rel=$(git rev-parse --show-cdup 2>/dev/null)
				[ -z "$rel" ] && rel='.'
				vcs_root=$(cd "$rel" 2>/dev/null && pwd -P 2>/dev/null)
			fi
			;;
		hg)
			vcs_root=$(hg root 2>/dev/null)
			;;
		svn)
			vcs_root=$(dirfind_top_in_hierarchy '.svn' 2>/dev/null)
			;;
	esac

	[ -z "$vcs_root" ] && return 1

	printf '%s' "$(cd "${vcs_root}" 2>/dev/null && pwd -P 2>/dev/null)"
	return 0
}

__vcs_branch() {

	[ 1 = $#  ] || return 1
	[ -z "$1" ] && return 1

	local vcs_branch=

	case $1 in
		git)
			vcs_branch=$(git symbolic-ref HEAD 2>/dev/null) || return 1
			vcs_branch=${vcs_branch#refs/heads/}
			;;
		hg)
			vcs_branch=$(hg id -b 2>/dev/null)
			;;
		svn)
			vcs_branch=$(LC_ALL=POSIX svn info 2>/dev/null | sed -n s/Revision:\ //p)
			vcs_branch="r${vcs_branch}"
			;;
	esac

	[ -z "$vcs_branch" ] && return 1

	printf '%s' "${vcs_branch}"
	return 0
}

__vcs_state() {

	[ 1 = $#  ] || return 1
	[ -z "$1" ] && return 1

	local vcs_state=

	case $1 in
		git)
			;;
		hg)
			;;
		svn)
			;;
	esac

	[ -z "$vcs_state" ] && return 1

	printf '%s' ${vcs_state}
	return 0
}

__vcs_type() {
	local vcs_system=

	if dirfind_in_hierarchy '.git' >/dev/null 2>&1 ; then
		vcs_system='git'
	fi

	if dirfind_in_hierarchy '.hg' >/dev/null 2>&1 ; then
		vcs_system='hg'
	fi

	if dirfind_top_in_hierarchy '.svn' >/dev/null 2>&1 ; then
		vcs_system='svn'
	fi

	# no result
	[ -z "$vcs_system" ] && return 1

	printf "%s" ${vcs_system}
	return 0
}

# vim: set ft=sh ts=8 sw=8 tw=0
