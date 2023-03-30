
shf_pkgsrc_stable_tag()
{
	local pkgsrc_tar_xz
	local stable_tag

	if [ $# -eq 0 ]; then
		pkgsrc_tar_xz=$(mktemp -q)

		if command -v curl >/dev/null 2>&1; then
			curl -fkLo "${pkgsrc_tar_xz}" https://cdn.netbsd.org/pub/pkgsrc/stable/pkgsrc.tar.xz
		elif command -v wget >/dev/null 2>&1; then
			wget -O "${pkgsrc_tar_xz}" https://cdn.netbsd.org/pub/pkgsrc/stable/pkgsrc.tar.xz
		else
			_fault "Can't download pkgsrc archive\n"
			rm -f "${pkgsrc_tar_xz}" 2>/dev/null
			return 2
		fi

		stable_tag=$(tar tvf "${pkgsrc_tar_xz}" "pkgsrc/doc/CHANGES-pkgsrc*" | sed 's,^.*doc/CHANGES-pkgsrc-,,')

		rm -f "${pkgsrc_tar_xz}" 2>/dev/null

	elif [ -d "${1}" ]; then
		stable_tag=$(find "${1}/doc" -name "CHANGES-pkgsrc*" |  sed 's,^.*doc/CHANGES-pkgsrc-,,')

	else
		pkgsrc_tar_xz="${1}"
		stable_tag=$(tar tvf "${pkgsrc_tar_xz}" "pkgsrc/doc/CHANGES-pkgsrc*" | sed 's,^.*doc/CHANGES-pkgsrc-,,')
	fi

	printf "%s" "${stable_tag}"
}

shf_pkgsrc_retrieve_sources()
{
	local vers
	vers="${1}"
	local pkgsrc
	pkgsrc="${2}"

	local with_wip=false

	if [ "${3}" = "wip" ]; then
		with_wip=true
	fi

	_inform "pkgsrc (%s) setup in %s \n" "${vers}" "${pkgsrc}"

	local already_present=false
	if ${with_wip} && [ -d "${pkgsrc}/wip" ]; then
		already_present=true
	fi
	if ! ${already_present} && [ -d "${pkgsrc}/" ]; then
		already_present=true
	fi

	if ${already_present}; then
		_fault "pkgsrc already exists (%s)\n" "${pkgsrc}"
		return 0
	fi

	[ ! -d "${pkgsrc}" ] && install -d -v "${pkgsrc}"

	local got_sources=false
	if [ current = "${vers}" ]; then
		if command -v git >/dev/null 2>&1; then
			[ ! -d "${pkgsrc}/bootstrap" ] &&
				(git clone --config branch.autosetuprebase=always\
				https://github.com/NetBSD/pkgsrc "${pkgsrc}" || return)
			 ${with_wip} && [ ! -d "${pkgsrc}/wip" ] &&
				(git clone --config branch.autosetuprebase=always\
				git://wip.pkgsrc.org/pkgsrc-wip.git "${pkgsrc}/wip" || return)
			got_sources=true
		fi
	fi

	if ! "${got_sources}"; then
		local pkgsrc_archive
		local pkgsrc_archive_url
		local pkgsrcwip_archive
		local pkgsrcwip_archive_url

		if [ "${vers}" = stable ]; then
			pkgsrc_archive_url=https://cdn.netbsd.org/pub/pkgsrc/stable/pkgsrc.tar.xz
		else
			# pkgsrc_archive_url=http://ftp.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.gz
			pkgsrc_archive_url=https://cdn.netbsd.org/pub/pkgsrc/current/pkgsrc.tar.xz
		fi

		if [ ! -d "${pkgsrc}/bootstrap" ]; then
			pkgsrc_archive=$(mktemp -q)

			if command -v curl >/dev/null 2>&1; then
				curl -fkLo "${pkgsrc_archive}" ${pkgsrc_archive_url}

			elif command -v wget >/dev/null 2>&1; then
				wget -O "${pkgsrc_archive}" ${pkgsrc_archive_url}
			else
				_fault "Can't download pkgsrc sources\n"
				return 2
			fi
		fi

		if ${with_wip} && [ ! -d "${pkgsrc}/wip" ]; then

			pkgsrcwip_archive=$(mktemp -q)
			pkgsrcwip_archive_url="https://wip.pkgsrc.org/cgi-bin/gitweb.cgi?p=pkgsrc-wip.git;a=snapshot;h=HEAD;sf=tgz"

			if command -v curl >/dev/null 2>&1; then
				curl -fkLo "${pkgsrcwip_archive}" "${pkgsrcwip_archive_url}"
			elif command -v wget >/dev/null 2>&1; then
				wget -O "${pkgsrcwip_archive}" "${pkgsrcwip_archive_url}"
			else
				_fault "Can't download pkgsrc/wip sources\n"
				return 2
			fi
		fi

		if [ ! -d "${pkgsrc}/bootstrap" ]; then
			tar -C "${pkgsrc}" -xf "${pkgsrc_archive}" --strip-components 1
		fi

		if ${with_wip} && [ ! -d "${pkgsrc}/wip" ]; then
			install -v -d "${pkgsrc}/wip" &&
				tar -C "${pkgsrc}/wip" -xf "${pkgsrcwip_archive}" --strip-components 1
		fi

		[ -f "${pkgsrcwip_archive}" ] && rm -f "${pkgsrcwip_archive}"
		[ -f "${pkgsrc_archive}" ] && rm -f "${pkgsrc_archive}"
	fi

	true
}

shf_pkgsrc_bootstrap()
{
	local pkgsrc="$1"
	local pkgdist="$2"

	_inform "pkgsrc bootstrap in '%s' based on '%s'... \n" "${pkgdist}" "${pkgsrc}"

	if [ -d "${pkgsrc}/bootstrap/work" ]; then
		rm -rf "${pkgsrc}/bootstrap/work"
	fi

	local bootstraptmp=$(mktemp -q)

	pkgsrc_fragment=""
	if [ -r "${HOME}/.local/share/pkgsrc/pkgsrc.fragment.mk" ]; then
		pkgsrc_fragment="${HOME}/.local/share/pkgsrc/pkgsrc.fragment.mk"
	fi

	# Change sh_shell for bash on Linux
	SH_SHELL=$(command -v sh)
	if [ "$(uname -s 2>/dev/null)" = "Linux" ]; then
		SH_SHELL=$(command -v bash)
	fi

	(
		cd "${pkgsrc}/bootstrap/" || return 1
		_inform "%s %s %s\n"\
			"./bootstrap --prefer-pkgsrc yes --unprivileged --prefix"\
			"${pkgdist}"\
			"${pkgsrc_fragment:+--mk-fragment ${pkgsrc_fragment}}"

		echo SH=$SH_SHELL ./bootstrap --prefer-pkgsrc yes --unprivileged --prefix "${pkgdist}" \
			${pkgsrc_fragment:+--mk-fragment "${pkgsrc_fragment}"}
		if ! SH=$SH_SHELL MAKEFLAGS="OSX_TOLERATE_SDK_SKEW=yes"\
			./bootstrap\
			--unprivileged\
			--prefer-pkgsrc yes\
			--prefix "${pkgdist}" \
			${pkgsrc_fragment:+--mk-fragment} "${pkgsrc_fragment}"; then
			_fault "pkgsrc bootstrap failed (see %s)\n" "${bootstraptmp}"
		else
			_inform "pkgsrc bootstrap complete\n"
		fi
	)
}

shf_pkgsrc_cleanup()
{
	printf "removing work directories in %s...\n" "${1:-${PKGSRC}}"
	find "${1:-${PKGSRC}}" -name work -exec rm -rf {} +
	printf "done\n"
}

shf_pkgsrc_setup()
{
	if shf_pkgsrc_retrieve_sources current "${PKGSRC}"; then
		shf_pkgsrc_bootstrap "${PKGSRC}" "${PKGSRC_DIST_CURRENT}"
	fi
}

# vim: set ft=sh ts=8 sw=8 tw=0 noet :
