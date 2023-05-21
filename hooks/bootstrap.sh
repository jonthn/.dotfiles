#!/bin/sh

# Safer script but don't be too verbose
#set -Eeuxo pipefail
set -Eeuo pipefail

basedir=$(CDPATH='' cd -- "$(dirname -- "${0}")" 2>/dev/null; pwd -P 2>/dev/null)

. "${basedir}/../config/shell/helpers/helpers.sh"

unset XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME
hostn=$(ulimit -c 0;hostname 2>&-)
dest="${HOME}"
dest_hostn="${HOME}/._/${hostn}"

if [ -d "${dest_hostn}" ]; then
	dest="${dest_hostn}"
fi

if [ $# -ge 1 ] && [ -n "${1}" ]; then
	dest="${1}"
fi

printf "Detected prefix to use : %s\nIf it's incorrect press Ctrl-C and provide the desired prefix (e.g. for this _host_ %s) otherwise simply press Enter.\n" "${dest}" "${dest_hostn}"

# wait for input
read

if [ "${dest}" != "${HOME}" ] && [ ! -d "${dest}" ]; then
	printf "Creates base XDG folder in %s\n" "${dest}"
	install -v -d "${dest}"
	install -v -d\
		"${dest}/.config"\
		"${dest}/.cache"\
		"${dest}/.local/share"\
		"${dest}/.local/state"
fi

if [ "${dest}" != "${HOME}" ] && [ ! -r "${dest}/.config/rcm/rcrc" -o -s "${dest}/.config/rcm/rcrc" ]; then
	install -v -d "${dest}/.config/rcm"
	cat <<-EOF > "${dest}/.config/rcm/rcrc"
EXCLUDES=LICENSE
UNDOTTED="Library/Fonts"
#HOSTNAME=xxx
TARGET=${dest}
EOF
fi

printf "Base completed for '%s'\n" "${dest}"

( . "${basedir}/../config/shell/bases.sh";\
	PATH=${basedir}/../tag-HOME/local/bin:$PATH\
	RCRC="${dest}/.config/rcm/rcrc"\
	${basedir}/../tag-HOME/local/bin/rcup\
	-v\
	-x LICENSE\
	-T "${dest}")

printf "Initial 'rcup' completed for '%s'\n" "${dest}"

available_tags=$(find "$basedir/../" -type d -name "tag-*" | sed s,^.*tag-,*\ ,)

cat <<EOF
'rcup' tags
$available_tags
#==============
# 1. Make your shell environment (XDG*)
. "${basedir}/../config/shell/bases.sh"
# 2. rcup the tags you wish
RCRC=${dest}/.config/rcm/rcrc PATH=${basedir}/../tag-HOME/local/bin:\$PATH rcup -t vim
# 3. it's required to _have_ a basic shell in \$HOME for some hardcoded path
PATH=${basedir}/../tag-HOME/local/bin:\$PATH ${basedir}/../tag-HOME/local/bin/rcup -v -x LICENSE -T "${HOME}" -t HOME
EOF

