# Copyright © 2019-2021 by BIALAS
# CREDITS:
# various example code from existing HexChat addons
# regexes: taken largely from wilk@chatik chatik.pl script

use warnings;
use strict;
use HexChat qw(:all);

my $name = 'hexidx';
my $version = '0.666';
my $description = 'Chatik.pl HexChat adaptation script';

register($name, $version, $description);

sub convert_msg {
	my ($nick, $text, $mode, $id_text) = @{$_[0]};
	my $args = @{$_[0]} - 1;
	my $event = $_[1];

	$text =~ s/%C%//sg;        
	$text =~ s/%C\w+?%//sg;
	$text =~ s/%F.*?%//sg;
	$text =~ s/%I(\w+?)%/\ <$1> /sg;
	$text =~ s/&#261;/ą/sg;
	$text =~ s/&#378;/ż/sg;
	$text =~ s/&#263;/ć/sg;
	$text =~ s/&#281;/ę/sg;
	$text =~ s/&#380;/ż/sg;
	$text =~ s/&#347;/ś/sg;
	$text =~ s/&#322;/ł/sg;
	$text =~ s/&oacute;/ó/sg;
	emit_print($event, ($nick, $text, $mode, $id_text)[0 .. $args]);
	return EAT_ALL;
}

my @events = (
	"Channel Message",
	"Channel Msg Hilight",
	"Channel Action",
	"Channel Action Hilight",
	"Private Message",
	"Private Message to Dialog",
	"Private Action",
	"Private Action to Dialog"
);

for (@events) {
	hook_print($_, \&convert_msg, { data => $_ });
}
