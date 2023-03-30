# SSH without host check & store {{{

shf_ssh_ssh_amnesiac()
{
	ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" "$@"
}

shf_ssh_scp_amnesiac()
{
	scp -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" "$@"
}

# }}}

# vim: set ft=sh ts=8 noet :
