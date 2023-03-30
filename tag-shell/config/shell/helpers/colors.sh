## Print the terminal escaped code for color in arg
#
terminal_color_code() {

	if [ $# = 0 ] || [ $# -gt 1 ]; then
		return 1
	fi

	color_code=0
	if tput setaf 4 >/dev/null 2>&1; then
		case ${1##bg_} in
			black)
				;;
			red)
				color_code=1
				;;
			green)
				color_code=2
				;;
			yellow)
				color_code=3
				;;
			blue)
				color_code=4
				;;
			magenta)
				color_code=5
				;;
			cyan)
				color_code=6
				;;
			white)
				color_code=7
				;;
			light_black)
				color_code=8
				;;
			light_red)
				color_code=9
				;;
			light_green)
				color_code=10
				;;
			light_yellow)
				color_code=11
				;;
			light_blue)
				color_code=12
				;;
			light_magenta)
				color_code=13
				;;
			light_cyan)
				color_code=14
				;;
			light_white)
				color_code=15
				;;
			e_o_l)
				printf "%s" "$(tput el)"
				;;
			reset|*)
				printf "%s" "$(tput sgr0)"
				;;
		esac

		if [ $color_code -gt 0 ]; then
			[ -z ${1%${1#bg_}} ] && printf "%s" "$(tput setaf "$color_code")" || printf "%s" "$(tput setab "$color_code")"
		fi

	elif tput AF 4 >/dev/null 2>&1; then
		case ${1##bg_} in
			black)
				;;
			red)
				color_code=1
				;;
			green)
				color_code=2
				;;
			yellow)
				color_code=3
				;;
			blue)
				color_code=4
				;;
			magenta)
				color_code=5
				;;
			cyan)
				color_code=6
				;;
			white)
				color_code=7
				;;
			light_black)
				color_code=8
				;;
			light_red)
				color_code=9
				;;
			light_green)
				color_code=10
				;;
			light_yellow)
				color_code=11
				;;
			light_blue)
				color_code=12
				;;
			light_magenta)
				color_code=13
				;;
			light_cyan)
				color_code=14
				;;
			light_white)
				color_code=15
				;;
			e_o_l)
				printf "%s" "$(tput el)"
				;;
			reset|*)
				printf "%s" "$(tput me)"
				;;
		esac

		if [ $color_code -gt 0 ]; then
			[ -z ${1%${1#bg_}} ] && printf "%s" "$(tput AF "$color_code")" || printf "%s" "$(tput AB "$color_code")"
		fi
	fi

	return 0
}

# vim: set ft=sh ts=8 noet :
