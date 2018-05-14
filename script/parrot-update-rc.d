#! /usr/bin/perl

# Wrapper around update-rc.d that auto-disables service that we don't
# want to start by default.

use strict;
use warnings;

my $initd = "/etc/init.d";
my $etcd  = "/etc/rc";
my $notreally = 0;

my @orig_argv = @ARGV;

while($#ARGV >= 0 && ($_ = $ARGV[0]) =~ /^-/) {
	shift @ARGV;
}

my $bn = shift @ARGV;
my $action = shift @ARGV;

my %status_wanted;
while (<DATA>) {
    next if /^#/;
    my ($service, $status) = split;
    $status_wanted{$service} = $status;
}

my @links = glob("/etc/rc[0-9S].d/[SK][0-9][0-9]$bn");

if (exists $ENV{'DPKG_RUNNING_VERSION'} and
    $action =~ /defaults|start|stop/ and not scalar(@links)) {
    # We're in a maint-script and we're about to install a new init script
    if (exists $status_wanted{$bn}) {
	if ($status_wanted{$bn} eq "disabled") {
	    print STDERR "update-rc.d: $bn is in our deadpool blacklist! YOU SHALL NOT PASS!\n";
	    system("/usr/sbin/debian-update-rc.d", @orig_argv);
	    system("/usr/sbin/debian-update-rc.d", $bn, "disable");
	    exit 0;
	}
    } else {
	my $header = parse_lsb_header("/etc/init.d/$bn");
	print STDERR "update-rc.d: We have no instructions for the $bn init script.\n";
	if ($header->{'required-start'} =~ /\$network/ ||
	    $header->{'should-start'} =~ /\$network/)
	{
	    print STDERR "update-rc.d: It looks like a network service! YOU SHALL NOT PASS!\n";
	    system("/usr/sbin/debian-update-rc.d", @orig_argv);
	    system("/usr/sbin/debian-update-rc.d", $bn, "disable");
	    exit 0;
	} else {
	    print STDERR "update-rc.d: It looks like a non-network service, we enable it.\n";
	}
    }
}

exec("/usr/sbin/debian-update-rc.d", @orig_argv);
die "$0: could not exec debian-update-rc.d: $!\n";

sub parse_lsb_header {
    my $initdscript = shift;
    my %lsbinfo;
    my $lsbheaders = "Provides|Required-Start|Required-Stop|Default-Start|Default-Stop|Should-Start|Should-Stop";
    open(INIT, "<$initdscript") || die "error: unable to read $initdscript";
    while (<INIT>) {
        chomp;
        $lsbinfo{'found'} = 1 if (m/^\#\#\# BEGIN INIT INFO\s*$/);
        last if (m/\#\#\# END INIT INFO\s*$/);
        if (m/^\# ($lsbheaders):\s*(\S?.*)$/i) {
	    $lsbinfo{lc($1)} = $2;
        }
    }
    close(INIT);

    # Check that all the required headers are present
    if (!$lsbinfo{found}) {
	printf STDERR "update-rc.d: warning: $initdscript missing LSB information\n";
	printf STDERR "update-rc.d: see <http://wiki.debian.org/LSBInitScripts>\n";
    } else {
        for my $key (split(/\|/, lc($lsbheaders))) {
            if (!exists $lsbinfo{$key}) {
                print STDERR "$initdscript missing LSB keyword '$key'\n"
		    unless $key =~ /^should-/;
		$lsbinfo{$key} = '';
            }
        }
    }

    return \%lsbinfo;
}

__DATA__
#
# Deadpool
#
apache2 disabled
avahi-daemon disabled
bluetooth disabled
couchdb disabled
clamav-daemon disabled
clamav-freshclam disabled
cups disabled
dictd disabled
dhcpcd disabled
dradis disabled
exim4 disabled
greenbone-security-assistant disabled
iodined disabled
mariadb disabled
minissdpd disabled
nfs-common disabled
nginx disabled
nmbd disabled
openbsd-inetd disabled
openvas-manager disabled
openvas-scanner disabled
polipo disabled
postfix disabled
postgresql disabled
pppd-dns disabled
procmail disabled
redis-server disabled
redsocks disabled
rpcbind disabled
samba disabled
smbd disabled
saned disabled
ssh disabled
stunnel4 disabled
winbind disabled
thin disabled
tinyproxy disabled
tor disabled
udftools disabled
pure-ftpd disabled
#
# Whitelist
#
acpid enabled
acpi-fakekey enabled
acpi-support enabled
alsa-utils enabled
anacron enabled
atd enabled
atop enabled
binfmt-support enabled
bootlogs enabled
bootmisc.sh enabled
checkfs.sh enabled
checkroot-bootclean.sh enabled
checkroot.sh enabled
console-setup enabled
cpufrequtils enabled
cron enabled
cryptdisks-early enabled
cryptdisks enabled
dbus enabled
ebtables enabled
etc-setserial enabled
fetchmail enabled
gdm3 enabled
hdparm enabled
hostname.sh enabled
hwclock.sh enabled
kbd enabled
kerneloops enabled
keyboard-setup enabled
keymap.sh enabled
kmod enabled
libvirt-bin enabled
libvirt-guests enabled
lightdm enabled
live-config enabled
live-boot enabled
loadcpufreq enabled
lvm2 enabled
lxc enabled
mcstrans enabled
motd enabled
mountall-bootclean.sh enabled
mountall.sh enabled
mountdevsubfs.sh enabled
mountkernfs.sh enabled
mountnfs-bootclean.sh enabled
mountnfs.sh enabled
mtab.sh enabled
networking enabled
network-manager enabled
nfs-common enabled
pppd-dns enabled
procps enabled
pulseaudio enabled
qemu-kvm enabled
rc.local enabled
rdnssd enabled
resolvconf enabled
restorecond enabled
rmnologin enabled
rsync enabled
rsyslog enabled
saned enabled
schroot enabled
screen-cleanup enabled
setserial enabled
spamassassin enabled
speech-dispatcher enabled
sudo enabled
udev enabled
udev-mtab enabled
uml-utilities enabled
urandom enabled
virtualbox enabled
x11-common enabled
