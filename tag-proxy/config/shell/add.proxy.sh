# handle proxy to propagate this accordingly

_socks_proxy_active()
{
	is_active=false
	case $(uname -s 2>/dev/null) in
		Darwin)
			if [ Yes = $(networksetup -getsocksfirewallproxy Wi-Fi | grep Enabled: | head -n1 | cut -d' ' -f2) ]; then
				is_active=true
			fi
			if [ Yes = $(networksetup -getsocksfirewallproxy Ethernet | grep Enabled: | head -n1 | cut -d' ' -f2) ]; then
				is_active=true
			fi
			;;
	esac

	${is_active}
}

_socks_proxy_details()
{
	if _socks_proxy_active >/dev/null 2>&1; then
		case $(uname -s 2>/dev/null) in
			Darwin)
				server=$(networksetup -getsocksfirewallproxy Wi-Fi | grep Server: | head -n1 | cut -d' ' -f2)
				port=$(networksetup -getsocksfirewallproxy Wi-Fi | grep Port: | head -n1 | cut -d' ' -f2)

				if [ -z "${server}" ]; then
					server=$(networksetup -getsocksfirewallproxy Wi-Fi | grep Server: | head -n1 | cut -d' ' -f2)
					port=$(networksetup -getsocksfirewallproxy Wi-Fi | grep Port: | head -n1 | cut -d' ' -f2)
				fi
			;;
		esac
	fi

	if [ ! -z "${server}" ] && [ ! -z "${port}" ]; then
		printf "socks5://%s:%d\n" "${server}" "${port}"
	fi
}

_innershelf_proxy_toggle()
{
	if ! _socks_proxy_active; then
		#no-op in that case
		return
	fi

	if [ -z "${http_proxy}" ]; then
		# set the proxy
		value=$(_socks_proxy_details)
		export http_proxy=${value}
		export https_proxy=${value}
		export socks5_proxy=${value#socks5://}
		if [ -r ~/.config/git/gitconfig_proxy.template ]; then
			sed -e s,\${value},${value}, -e s,\${rawvalue},${value#socks5://}, ~/.config/git/gitconfig_proxy.template > ~/.config/git/gitconfig_proxy
		fi
		if [ -r ~/.ssh/common_proxy.template ]; then
			sed -e s,\${value},${value}, -e s,\${rawvalue},${value#socks5://}, ~/.ssh/common_proxy.template > ~/.ssh/common_proxy.sshconfig
		fi
		printf "Proxy set to %s\n"  "${value}"
	else
		# unset the proxy
		unset http_proxy
		unset https_proxy
		unset socks5_proxy
		[ -e ~/.config/git/gitconfig_proxy ] && rm ~/.config/git/gitconfig_proxy
		[ -e ~/.ssh/common_proxy.sshconfig ] && rm ~/.ssh/common_proxy.sshconfig
		printf "Proxy unset\n"
	fi
}

innershelf_proxy()
{
	case "${1}" in
		keyword)
			printf "%s" "proxy"
			return 0
			;;
		synopsis)
			printf "%s\n" "Proxy (SSH, Git, ...)"
			return 0
			;;
		debug)
			;;
		toggle)
			_innershelf_proxy_toggle
			;;
		details)
			_socks_proxy_details
			;;
		active)
			if _socks_proxy_active; then
				printf "Proxy is ACTIVE\n"
			else
				printf "Proxy disabled\n"
			fi
			;;
		help|usage|*)
			printf "[%s] has\n" "$(innershelf_proxy keyword)"
			printf "COMMANDS:\n"
			printf "%-25s# %s\n" "toggle" "Activate/Deactivate Proxy settings"
			printf "%-25s# %s\n" "details" "Details of Proxy settings"
			printf "%-25s# %s\n" "active" "Check if Proxy active"
			case "${1}" in
				help|usage)
					return 0
					;;
				*)
					return 1
					;;
			esac
			;;
	esac
}
