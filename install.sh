#!/bin/sh

cat << EOF
====
Hi! You should run this script instead of section A.2
of the thesis. It will set up certificates automatically
for you, including their renewal, which is very convenient.
However, for it to work (and continue working), you will
need to ensure that:

- traffic is allowed through port 80 on this machine by
  whatever external firewall exists

- (IMPORTANT) pf(4) is allowing traffic through port 80

Re. that second point, if you haven't configured pf yet,
then you're going to be okay. However, _WHEN_ you configure
it eventually, you will need to make sure that traffic over
port 80 is allowed inbound over the public interface. This
looks like the following relatively intuitive rule:

pass in on egress proto tcp from any to egress port http

You can also bunch this up with other services:

pass in on egress proto tcp from any to egress port {ssh, http, https}

Just make sure 'http' is in there. Press any key to acknowledge
this caveat, and we will get on with things.
====
EOF
read

# configure everything
doas sh -c 'sed -e "s/CHANGEME/`hostname`/" acme-client.conf > /etc/acme-client.conf'
doas sh -c 'sed -e "s/CHANGEME/`hostname`/" httpd.conf > /etc/httpd.conf'

rcctl check relayd
if [ $? -eq 0 ]; then
	cat << EOF
====
I noticed relayd is running. We should configure ssh
public key authentication for the worker machine fpga
account so that we can automatically update all worker
certificates. I will install ssh-copy-id to make this
happen, and then uninstall it once public key authentication
is configured.

If at any point in the future you want to add more
workers, come back here and rerun this installer script.
We will take care of setting public keys for you at that
point.

Please set up an ssh identity for _root_ in /root/.ssh.
Press Ctrl+C if you haven't done that already. Otherwise,
press any other key to continue.
====
EOF
	read

	doas pkg_add ssh-copy-id

	hosts=`doas relayctl show hosts | grep .mit.edu | cut -f 3`
	for host in $hosts; do
		doas ssh-copy-id fpga@$host
		[ $? -eq 0 ] || exit 1
	done

	doas pkg_delete ssh-copy-id
fi

# go
doas install -o root -g wheel -m 555 renewcerts /usr/local/bin
doas renewcerts

# reconfigure cron job
l="~       *       *       *       *       /usr/local/bin/renewcerts"

doas crontab -l | sed '/.*renewcerts.*/d' | doas crontab -
echo installing line "$l"
(doas crontab -l; echo "$l") | doas crontab -
