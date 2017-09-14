package Monkeyness::Common;
$VERSION = '8.0';

=head1 NAME

Common

=head1 DESCRIPTION

Contains standard routines that defy a more specific locale.

=cut

use strict;
use utf8;
use constant TRUE => 1;
use constant FALSE => 0;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(getAnswer parseJSON makeJSON);


sub getAnswer {
#=====================================================

=head2 B<getAnswer>

 defined(my $answer = $self->getAnswer) || return;

=cut
#=====================================================
	my $self = shift || return;
	my $answer = <>;
	if (ord($answer) == 0) { print "\n"; return; }
	if ($answer =~ /^exit/) { print "\n"; return; }
	chomp($answer);
	$answer =~ s/(?:^\s+|\s+$)//g;
	if (!length($answer)) { return ""; }
	if (!$answer) { return '0'; }
	return $answer;
}

sub parseJSON {
#=====================================================

=head2 B<parseJSON>

=cut
#=====================================================
	my $jsonString = shift || return;
	
	# Newer JSON code
	my $json = JSON->new;
	$json = $json->utf8(0);
	my $perl;
	
	eval { $perl = $json->decode($jsonString); };
	if ($@) {
		print "Error parsing JSON: $@";
		return;
	}
	
	return $perl;
}

sub makeJSON {
#=====================================================

=head2 B<makeJSON>

=cut
#=====================================================
	my $perl = shift || return;
	
	# Newer JSON code
	my $json = JSON->new;
	$json = $json->utf8(0);
	
	my $jsonString;
	eval { $jsonString = $json->encode($perl); };
	if ($@) {
		print "Error making JSON: $@";
		return;
	}
	
	return $jsonString;
}




=head1 CHANGES

  20070628 TJM - v1.0 copied from various places
  20140320 TJM - v7.0 Modernized
  20170914 TJM - v8.0 Open sourced

=head1 AUTHOR

  Tim Moses <tim@sitemason.com>
  Monkeyness <http://www.monkeyness.com/>

=cut

1;

