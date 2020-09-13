# Based on https://gist.github.com/pkuczynski/8665367
# From project https://github.com/jasperes/bash-yaml

yaml_parse()
{
    local yaml_file=$1
    local prefix=$2
    local s
    local w
    local fs

    # length($1) / indent_factor
    #  indent_factor=2 indent 2 spaces
    #  indent_factor=7 indent 4 spaces

    s='[[:space:]]*'
    w='[a-zA-Z0-9_.-]*'
    fs="$(echo @|tr @ '\034')"

	cat "$yaml_file" |

        sed -e '/- [^\“]'"[^\']"'.*: /s|\([ ]*\)- \([[:space:]]*\)|\1-\'$'\n''  \1\2|g' |

        sed -ne '/^--/s|--||g; s|\"|\\\"|g; s/[[:space:]]*$//g;' \
            -e "/#.*[\"\']/!s| #.*||g; /^#/s|#.*||g;" \
            -e "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
            -e "s|^\($s\)\($w\)${s}[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" |

        awk -F"$fs" '{
            indent = length($1) / 2; 
            if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
            vname[indent] = $2;
            for (i in vname) {if (i > indent) {delete vname[i]}}
                if (length($3) > 0) {
                    vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
                    printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
                }
            }' |

        sed -e 's/_=/+=/g' |

        awk 'BEGIN {
                FS="=";
                OFS="="
            }
            /(-|\.).*=/ {
                gsub("-|\\.", "_", $1)
            }
            { print }'
}

yaml_getl()
{
    if [ $# -lt 3 -o $# -gt 5 ]; then
        >&2 printf "# get <parsed yml file> <prefix> <key> [start_point] <new_prefix>\n"
        return 1
    fi

    if [ ! -r "${1}" ]; then
        >&2 printf "Impossible to read '%s'\n" "${1}"
        return 1
    fi

    local parsed_yaml="${1}"
    local prefix="${2}"
    local new_prefix="${5}"
    local startkey="${3}"
    local start_point="${4}"
    local current_item=''
    local current_key=''
    local values=''

    while read -r line; do
        if printf "%s" "${line}" | grep "${prefix}${startkey}" >/dev/null 2>&1; then
            if [ -n "${start_point}" ] && [ "${line}" = "${start_point}" ]; then
                current_item="${line}"
            elif [ -n "${start_point}" ] && [ -z "${current_item}" ]; then
                continue
            elif [ -n "${current_item}" ]; then
                if [ -n "${current_key}" ]; then
                    printf "%s=\"%s\"\n" "${new_prefix}${current_key}" "${values}"
                    current_key=''
                    values=''
                fi
                printf "#%s\n" "${line}"
                break
            else
                current_item="${line}"
            fi
        fi

        [ -z "${current_item}" ] && continue

        local yaml_key >/dev/null
        local yaml_val >/dev/null
        yaml_key=$(printf "%s" "${line}" | cut -d'=' -f1 | sed 's,\+$,,' | sed "s,^${prefix},,")
        yaml_val=$(printf "%s" "${line}" | sed -e 's,.*("\(.*\)").*,\1,')

        if [ "${current_key}" = "${yaml_key}" ]; then
            values="${values}${values+ }${yaml_val}"
        else
            if [ -n "${current_key}" ]; then
                printf "%s=\"%s\"\n" "${new_prefix}${current_key}" "${values}"
            fi
            current_key="${yaml_key}"
            values="${yaml_val}"
        fi

    done < "${parsed_yaml}"

    if [ ! -z "${current_item}" ]; then
        if [ -n "${current_key}" ]; then
            printf "%s=\"%s\"\n" "${new_prefix}${current_key}" "${values}"
        fi
        true
    else
        false
    fi
}

yaml_local_variables()
{
    sed -e '/^[[:space:]]*$/d' -e '/^#.*/d'  -e 's,^\(.*\)=.*,local \1,'
}

yaml_unset_variables()
{
    sed -e '/^[[:space:]]*$/d' -e '/^#.*/d'  -e 's,^\(.*\)=.*,unset \1,'
}
