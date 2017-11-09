package MonkeynessPl::Database;
$VERSION = '5.0';

=head1 NAME

Database

=head1 DESCRIPTION

Mainly a placeholder until I get the old code in here.

=cut

use strict;
use utf8;
use constant TRUE => 1;
use constant FALSE => 0;

use Data::Dumper;
use DBI;
use DBD::Pg;

use MonkeynessPl::Common;



sub new {
	my ($class, %arg) = @_;
	$class || return;
	
	my $self = {};
	
	$self->{dbh} = dbConnect($arg{db}) || return;
	
	bless $self, $class;
	return $self;
}





sub dbConnect {
	my $options = shift || return;
	isHashWithContent($options) || return;
	
	my $type = $options->{dbType} || 'Pg';
	my $host = $options->{dbHost};
	my $port = $options->{dbPort};
	if (!$port) {
		if ($type eq 'Pg') { $port = '5432'; }
		elsif ($type eq 'mysql') { $port = '3306'; }
	}
	my $name = $options->{dbName} || return;
	my $user = $options->{dbUser} || return;
	my $pass = $options->{dbPass} || undef;
	return DBI->connect("DBI:${type}:host=${host};port=${port};dbname=${name}", $user, $pass, { PrintError => 1, AutoCommit => 1 });
}

sub quoteList {
	my $self = shift || return;
	my $inputList = shift || return;
	my $debug = shift;
	my $qlist = $self->quote($inputList, $debug);
	my $qstring = join(', ', @{$qlist});
	return $qstring;
}

sub quote {
	my $self = shift || return;
	my $input = shift;
	my $debug = shift;
	$debug && print Dumper($input);
	
	if (isArray($input)) {
		my $quotedList = [];
		foreach my $item (@{$input}) {
			my $qitem = $self->_quoteEach($item);
			push(@{$quotedList}, $qitem);
		}
		return $quotedList;
	}
	elsif (isHash($input)) {
		my $quotedHash = {};
		while (my($name, $item) = each(%{$input})) {
			$quotedHash->{name} = $self->_quoteEach($item);
		}
		return $quotedHash;
	}
	elsif (defined($input)) {
		return $self->_quoteEach($input);
	}
	else {
		return 'NULL';
	}
}
sub _quoteEach {
	my $self = shift || return;
	my $item = shift;
	if (!defined($item)) { return 'NULL'; }
	return $self->{dbh}->quote($item);
}


sub selectRowArray {
#=====================================================

=head2 B<selectRowArray>

 my @array = $self->selectRowArray($sql);
 my ($single) = $self->selectRowArray($sql);

=cut
#=====================================================
	my $self = shift || return;
	my $sql = shift || return;
	my $debug = shift;
	$debug && $self->debugSQL($sql);
	my @data = $self->{dbh}->selectrow_array($sql);
	return @data;
}


sub selectRowHashref {
#=====================================================

=head2 B<selectRowHashref>

 my $hashRef = $self->selectRowHashref($sql);

=cut
#=====================================================
	my $self = shift || return;
	my $sql = shift || return;
	my $debug = shift;
	$debug && $self->debugSQL($sql);
	my $data = $self->{dbh}->selectrow_hashref($sql);
	return $data;
}


sub selectColArrayref {
#=====================================================

=head2 B<selectColArrayref>

 my $arrayRef = $self->selectColArrayref($sql);

=cut
#=====================================================
	my $self = shift || return;
	my $sql = shift || return;
	my $debug = shift;
	$debug && $self->debugSQL($sql);
	my $data = $self->{dbh}->selectcol_arrayref($sql);
	return $data;
}


sub selectAllArrayref {
#=====================================================

=head2 B<selectAllArrayref>

 my $hashRef = $self->selectAllArrayref($sql, $key);

=cut
#=====================================================
	my $self = shift || return;
	my $sql = shift || return;
	my $debug = shift;
	$debug && $self->debugSQL($sql);
	my $data = $self->{dbh}->selectall_arrayref($sql);
	return $data;
}


sub selectAllHashref {
#=====================================================

=head2 B<selectAllHashref>

 my $hashRef = $self->selectAllHashref($sql, $key);

=cut
#=====================================================
	my $self = shift || return;
	my $sql = shift || return;
	my $key = shift || return;
	my $debug = shift;
	$debug && $self->debugSQL($sql);
	my $data = $self->{dbh}->selectall_hashref($sql, $key);
	return $data;
}


sub selectAllArrayhash {
#=====================================================

=head2 B<selectAllArrayhash>

 my $arrayHash = $self->selectAllArrayhash($sql);

=cut
#=====================================================
	my $self = shift || return;
	my $sql = shift || return;
	my $debug = shift;
	$debug && $self->debugSQL($sql);
	my $sth = $self->{dbh}->prepare($sql);
	$sth->execute;
  	my $data = $sth->fetchall_arrayref({});
	return $data;
}

sub debugSQL {
#=====================================================

=head2 B<debugSQL>

 $self->debugSQL($sql);

=cut
#=====================================================
	my $self = shift || return;
	my $sql = shift;
	print "$sql\n";
}



=head1 CHANGES

  ???????? TJM - v1.0 copied from various places
  20170914 TJM - v5.0 Open sourced

=head1 AUTHOR

  Tim Moses <tim@moses.com>
  Monkeyness <http://www.monkeyness.com/>

=cut

1;
