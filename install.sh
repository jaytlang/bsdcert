#!/bin/sh

cat << EOF
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
EOF
read

# configure everything
doas sh -c 'sed -e "s/CHANGEME/`hostname`/" acme-client.conf > /etc/acme-client.conf'
doas sh -c 'sed -e "s/CHANGEME/`hostname`/" httpd.conf > /etc/httpd.conf'

doas rcctl -f start httpd
doas acme-client -v `hostname`
doas rcctl stop httpd

# reconfigure cron job
l="~       *       *       *       *       rcctl -f start httpd && acme-client -v `hostname` && rcctl stop httpd"

doas crontab -l | sed '/.*acme-client.*/d' | doas crontab -
echo installing line "$l"
(doas crontab -l; echo "$l") | doas crontab -
