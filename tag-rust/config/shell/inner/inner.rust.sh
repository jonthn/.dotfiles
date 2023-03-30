shf_rust_bootstrap()
{
	local rustupbase="${RUSTUP_HOME}"
	local cargobase="${CARGO_HOME}"
	local cargobin="${CARGO_HOME}/bin"
	local latest_update_rustup="${rustupbase}/latest.rustupinit.update"

	if [ ! -r "${latest_update_rustup}" ] || [ -r "${latest_update_rustup}" -a "$(cat "${latest_update_rustup}")" -lt "$(date +%Y%m%d)" ]; then
		local temp_rustup="$(mktemp -q)"
		_inform 'Updating rustup.sh ... \n'
		if command -v curl >/dev/null 2>&1; then
			curl -fkLo "${temp_rustup}" https://sh.rustup.rs
		elif command -v wget >/dev/null 2>&1; then
			wget -O "${temp_rustup}" https://sh.rustup.rs
		else
			_fault "Can't update rustup script, using archived copy\n"
		fi

		[ ! -d "${rustupbase}/bin" ] && install -d "${rustupbase}/bin"
		if [ -f "${temp_rustup}" ] && [ -d "${rustupbase}/bin" ]; then
			install -m 0755 -v "${temp_rustup}" "${rustupbase}/bin/rustup-init"
			_inform "rustup-init script has been updated\n"
		fi
		rm "${temp_rustup}"

		local dir_latest_update="$(dirname "${latest_update_rustup}")"
		[ ! -d "${dir_latest_update}" ] && install -d "${dir_latest_update}"
		date +%Y%m%d > "${latest_update_rustup}"
	fi

	if [ -x "${rustupbase}/bin/rustup-init" ]; then
		_inform "rust bootstrap in '%s' (%s)... \n" "${cargobase}" "${rustupbase}"

		"${rustupbase}/bin/rustup-init" --no-modify-path -y
		${cargobin}/rustup default stable
	else
		_fault "Missing 'rustup-init' to install Rust\n"
		false
	fi
}

shf_rust_selfup()
{
	local rustupbase="${RUSTUP_HOME}"
	local cargobase="${CARGO_HOME}"
	local cargobin="${CARGO_HOME}/bin"

	if command -v rustup >/dev/null 2>&1; then
		rustup self update
		rustup update
	elif [ -d "${rustupbase}" -a -d "${cargobase}" ]; then
		${cargobin}/rustup self update
		${cargobin}/rustup update
	else
		_fault "Missing 'rustup' to proceed with update\n"
		false
	fi
}

shf_rust_dismantle()
{
	rm -ir "${CARGO_INSTALL_ROOT}"
	rm -ir "${CARGO_HOME}"
	rm -ir "${RUSTUP_HOME}"
}
