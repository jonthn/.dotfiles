# adapt Git env

if command -v delta >/dev/null 2>&1; then
	export GIT_PAGER="delta --syntax-theme base16 --line-numbers"
fi

if command -v difft >/dev/null 2>&1; then
	export GIT_EXTERNAL_DIFF=difft
fi

# vim: set ft=sh ts=8 sw=8 tw=0 noet :
