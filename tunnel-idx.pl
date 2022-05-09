#! /usr/bin/perl
#
######################################################################
#
#   IN CASE OF TROUBLE RUNNING THE SCRIPT
#   REPLACE THE SHEBANG LINE TO:
#   #! /usr/bin/env perl
#
######################################################################
#
#   Widely used chatik.net (chat.idx.pl/chatik.pl) tunnel, modified,
#   and adapted by a few people; the lastest mod is by @drone-runner
#   
#   @drone-runner modifications:
#    + proper source code formatting
#    - stripping colors from chat messages (no eyefuck messages ;/)
#    + you can use standard //emoticon notation to express the chat
#      emotions i.e. //lol
#    + LICENSE:
#        I'm not sure but the original file hasn't had any
#        license information, original authors won't object
#        so I @drone-runner, am putting the file with my
#        modification to the PUBLIC DOMAIN (The Unlicense, as in
#        the <http://unlicense.org>.)
#    + a few more rather cosmetic changes
#
######################################################################

use strict;
use IO::Socket ();
use LWP::UserAgent;
use HTTP::Request;
use URI::Escape;
use POSIX;

my ($PORT, $DHOST, $DPORT, $BINDADDR);

# CUSTOMIZATION STARTS
$DHOST = "chat.idx.pl";
$DPORT = 6667;
$BINDADDR='127.0.0.1';
$PORT= 6667;
# CUSTOMIZATION ENDS

$| = 1;

{
	my %o = ('port' => $PORT,
                 'dport' => $DPORT,
                 'dhost' => $DHOST
	        );

	my $ah = IO::Socket::INET->new('LocalAddr' => $BINDADDR,
                                       'LocalPort' => $PORT,
                                       'Reuse' => 1,
                                       'Listen' => 10) || die "Failed to bind to local socket: $!";

	print "The Chatik.net tunnel has started. Connect to port $PORT at $BINDADDR with your favorite IRC client.\n";

	$SIG{'CHLD'} = 'IGNORE';
	my $num = 0;
	while (1) {
		my $ch = $ah->accept();
		if (!$ch) {
			print STDERR "Failed to accept: $!\n";
			next;
		}
		print "Accepted connection.\n";

		++$num;

		my $pid = fork();
		if (!defined($pid)) {
			print STDERR "Failed to fork: $!\n";
		} elsif ($pid == 0) {
			$ah->close();
			Run(\%o, $ch, $num);
		} else {
			$ch->close();
		}
	}
}


sub Run {
	my($o, $ch, $num) = @_;
	my $th = IO::Socket::INET->new('PeerAddr' => $o->{'dhost'},
                                       'PeerPort' => $o->{'dport'});

	if (!$th) {
		exit 0;
	}

	my ($fh, $nick,$user,$authpass);

	my  $color=1;

	$ch->autoflush();
	$th->autoflush();

	while ($ch || $th) {

		my $rin = "";

		vec($rin, fileno($ch), 1) = 1 if $ch;
		vec($rin, fileno($th), 1) = 1 if $th;

		my($rout, $eout);

		select($rout = $rin, undef, $eout = $rin, 120);
		if (!$rout  &&  !$eout) {
			print STDERR "Child: Timeout, terminating.\n";
		}

		my $cbuffer = "";
		my $tbuffer = "";

		if ($ch  &&  (vec($eout, fileno($ch), 1)  ||
		              vec($rout, fileno($ch), 1))) {
			my $result = sysread($ch, $tbuffer, 1024);

			if ($tbuffer=~ /NICK/ && ! $nick) {
				$nick=$tbuffer;
				$nick=~ s/NICK ~/NICK /s;
				$nick=~ s/^.*NICK (.*?)(\r|\n| ).*$/$1/s;
				if ($tbuffer=~ /USER/) {
					$user=$tbuffer;
					$user=~ s/USER ~/USER /s;
					$user=~ s/^.*USER (.*?)(\r|\n| ).*$/$1/s;
					my $res = syswrite($th, "NICK $nick\n");
				};
      			};
			if (!defined($result)) {
				print STDERR "Child: Error while reading from client: $!\n";
				exit 0;
			}
			if ($result == 0) {
				exit 0;
			}
		} 
		if ($th  &&  (vec($eout, fileno($th), 1)  ||
		              vec($rout, fileno($th), 1))) {
			my $result = sysread($th, $cbuffer, 1024);
			if (!defined($result)) {
				print STDERR "Child: Error while reading from tunnel: $!\n";
				exit 0;
			}
			if ($result == 0) {
				exit 0;
			}
			$cbuffer=~ s/%C.+%//;
			$cbuffer=~ s/%F.+%//;
			$cbuffer=~ s/%I(.+)%/ *\1* /;	
		}
		$tbuffer=~ s/\/\/(([a-z]|[0-9])+)/%I\1%/;
		if ($fh  &&  $tbuffer) {
			(print $fh $tbuffer);
		}
		while (my $len = length($tbuffer)) {
		       my $res = syswrite($th, $tbuffer, $len);
			if ($res > 0) {
				$tbuffer = substr($tbuffer, $res);
			} else {
				print STDERR "Child: Failed to write to tunnel: $!\n";
			}
		}
		while (my $len = length($cbuffer)) {
		       my $res = syswrite($ch, $cbuffer, $len);
			if ($res > 0) {
				$cbuffer = substr($cbuffer, $res);
			} else {
				print STDERR "Child: Failed to write to tunnel: $!\n";
			}
		}
	}
}
# EOF/20220509
