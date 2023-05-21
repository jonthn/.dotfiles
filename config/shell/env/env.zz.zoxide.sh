export _ZO_DATA_DIR="${XDG_STATE_HOME}/zoxide"

# init {{{

local zoxide_cmd
zoxide_cmd=$(shf_shell_zoxide location 2>/dev/null)

if command -v zoxide >/dev/null 2>&1; then
	zoxide_cmd=zoxide
elif [ -z ${zoxide_cmd} -o ! -x ${zoxide_cmd} ]; then
	shf_shell_zoxide init
	[ ! -x ${zoxide_cmd} ] && zoxide_cmd=''
fi
if [ -n "${zoxide_cmd}" ]; then
	case $(__shell) in
		zsh)
			eval "$("${zoxide_cmd}" init zsh)"
			;;
		bash)
			eval "$("${zoxide_cmd}" init bash)"
			;;
		*)
			eval "$("${zoxide_cmd}" init posix --hook prompt)"
			;;
	esac
fi

# }}}
