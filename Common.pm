package MonkeynessPl::Common 8.0;

=head1 NAME

Common

=head1 DESCRIPTION

Contains standard routines that defy a more specific locale.

Placeholder until I can add the old code here.

=cut

use v5.012;
use strict;
use utf8;
use constant TRUE => 1;
use constant FALSE => 0;

use B qw(svref_2object);
use JSON;
use Time::gmtime;
use Unicode::Collate;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(getAnswer parseJSON makeJSON
	isBoolean isText isJSON isPosInt isNumber isOrdinal isArray isArrayWithContent isHash isHashWithContent isHashKey isArrayHash isArrayHashWithContent isObject toArray byAny
	joinText camel_case kebab_case snake_case convertToName percent
	generatePassword
	getFilenameUTCMinute getFilenameUTCHour getFilenameUTCDate convertArraysToCSV readFileList readFile writeFile
	maxLength printObject convertObjectToString isPerson getTermColors makeColor bold printBold mark
);


sub getAnswer {
#=====================================================

=head2 B<getAnswer>

 defined(my $answer = getAnswer) || return;
 defined(my $answer = getAnswer($array_of_inputs) || return;

$array_of_answers is an array of inputs that should be used before STDIN. Good for grabbing some advance answers in the original command line args.

=cut
#=====================================================
	my $inputs = shift;
	my $answer;
	print scalar getTermColor('bold');
	if (isArrayWithContent($inputs)) {
		$answer = shift(@{$inputs});
		print "$answer\n";
	} else {
		$answer = <STDIN>;
	}
	print scalar getTermColor('reset');
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


sub isBoolean {
#=====================================================

=head2 B<isBoolean>

 isBoolean($value) || return;

=cut
#=====================================================
	my $value = shift;
	if (ref($value) =~ /\bBoolean$/i) {
		return TRUE;
	}
	return undef;
}

sub isText {
#=====================================================

=head2 B<isText>

 isText($value) || return;

=cut
#=====================================================
	my $value = shift;
	if (!ref($value) && defined($value)) {
		if ($value =~ /\S/) {
			return TRUE;
		}
	}
	return undef;
}

sub isJSON {
#=====================================================

=head2 B<isJSON>

 isJSON($value) || return;

=cut
#=====================================================
	my $value = shift;
	if (!ref($value) && defined($value)) {
		if (($value =~ /^\s*\{/) && ($value =~ /\}\s*$/)) { return TRUE; }
		if (($value =~ /^\s*\[/) && ($value =~ /\]\s*$/)) { return TRUE; }
	}
	return undef;
}

sub isPosInt {
#=====================================================

=head2 B<isPosInt>

 isPosInt($value) || return;
 isPosInt($value, $min, $max) || return;

=cut
#=====================================================
	my $value = shift;
	my $min = shift;
	my $max = shift;
	if (!ref($value) && defined($value)) {
		if ($value =~ /^(\d+)$/) {
			my $inRange = TRUE;
			if (defined($min) && ($value < $min)) { undef $inRange; }
			if (defined($max) && ($value > $max)) { undef $inRange; }
			return $inRange;
		}
	}
	return undef;
}

sub isNumber {
#=====================================================

=head2 B<isNumber>

Started with a simple number to text comparison, then it got out of hand. If there are any problems with this, it will be time to scrap this approach and find something simpler.

 isNumber($value) || return;
 isNumber($value, $min, $max) || return;

=cut
#=====================================================
	my $value = shift;
	my $min = shift;
	my $max = shift;
	if (!ref($value) && defined($value)) {
		# Strip leading zeros
		if ($value =~ /\./) { $value =~ s/\b0+(\d*?\.)/$1/; }
		elsif ($value) { $value =~ s/\b0+(\d*?)/$1/; }
		# Crop digits
		if ($value =~ /\./) {
			# Count digits before decimal point
			my $pre = '';
			if ($value =~ /\d\./) { ($pre) = $value =~ /\b(\d+)(?:\.|\b)/; }
			else { $value =~ s/\./0\./; }
			# Count digits after decimal point
			my ($post) = $value =~ /\.(\d+)\b/;
			$post ||= '';
			if ((length($pre) + length($post)) > 15) {
				# Crop zeros
				my $target = 15 - length($pre);
				if ($target > 0) {
					$value =~ s/(\.\d{$target})\d+\b/$1/;
				} else {
					$value =~ s/\.\d+\b/$1/;
				}
			}
		}
		# Strip trailing zeros
		$value =~ s/(\.\d*?)0+\b/$1/;
		no warnings 'numeric';
		if (($value+0) eq $value) {
			my $inRange = TRUE;
			if (defined($min) && ($value < $min)) { undef $inRange; }
			if (defined($max) && ($value > $max)) { undef $inRange; }
			return $inRange;
		}
		use warnings 'numeric';
	}
	return undef;
}

sub isOrdinal {
#=====================================================

=head2 B<isOrdinal>

 Recognizes English and English metaphones of digit-based ordinals.

=cut
#=====================================================
	my $ordinal = shift;
	
	if ($ordinal =~ /^[1-9]\d*(?:st|n[dt]|r[dt]|th)$/i) { return TRUE; }
}

sub isArray {
#=====================================================

=head2 B<isArray>

Returns 1 if the argument is an array ref and has one or more elements.

=cut
#=====================================================
	my $array = shift || return;
	if (ref($array) eq 'ARRAY') { return TRUE; }
	return;
}

sub isArrayWithContent {
#=====================================================

=head2 B<isArrayWithContent>

=cut
#=====================================================
	my $array = shift || return;
	if (isArray($array) && @{$array}) { return TRUE; }
	return;
}

sub isHash {
#=====================================================

=head2 B<isHash>

Returns positive if the argument is a hash ref.

=cut
#=====================================================
	my $hash = shift || return;
	if ((ref($hash) eq 'HASH') || ($hash =~ /=HASH\(/)) { return TRUE; }
	return;
}

sub isHashWithContent {
#=====================================================

=head2 B<isHashWithContent>

=cut
#=====================================================
	my $hash = shift || return;
	if (isHash($hash) && keys(%{$hash})) { return TRUE; }
	return;
}

sub isHashKey {
#=====================================================

=head2 B<isHashKey>

 if (isHashKey($hash, $key))

=cut
#=====================================================
	my $hash = shift || return;
	my $key = shift || return;
	if (isHash($hash) && exists($hash->{$key})) { return TRUE; }
	return;
}


sub isArrayHash {
#=====================================================

=head2 B<isArrayHash>

Returns positive if argument is an array containing only one or more hash refs.
Returns defined if argument is an array containing only zero or more hash refs.
Does not recurse.

 if (isArrayHash($arrayHash))			# array with only hashes
 if (defined(isArrayHash($arrayHash)))	# empty array or array with only hashes

=cut
#=====================================================
	my $array = shift || return;
	my $answer;
	if (ref($array) eq 'ARRAY') {
		if (@{$array}) {
			foreach my $value (@{$array}) {
				if (ref($value) ne 'HASH') { return; }
			}
			return TRUE;
		}
		return 0;
	}
	return;
}

sub isArrayHashWithContent {
#=====================================================

=head2 B<isArrayHashWithContent>

=cut
#=====================================================
	my $array = shift || return;
	if (isArrayHash($array) && @{$array}) { return TRUE; }
	return;
}

sub isObject {
#=====================================================

=head2 B<isObject>

Returns positive if the argument is an object.

=cut
#=====================================================
	my $object = shift || return;
	if ((ref($object) =~ /::/) && isHash($object)) { return TRUE; }
	return;
}

sub toArray {
	my $input = shift || return;
	my $key = shift || return;
	
	my $outputArray = [];
	if (isArrayHash($input)) {
		foreach my $hash (@{$input}) {
			isHash($hash) || next;
			if (exists($hash->{$key})) { push(@{$outputArray}, $hash->{$key}); }
		}
	}
	return $outputArray;
}

sub byAny {
#=====================================================

=head2 B<byAny>

Sorts on one or more fields in an array of arrays, hashes, or values.

 my @sortedArray = sort { byAny($a,$b,$options) } @unsortedArray;
 my @sortedArray = sort { byAny($a,$b,$columnToSort,$options) } @unsortedArray;
 my @sortedArray = sort { byAny($a,$b,$listOfColumnsToSort,$options) } @unsortedArray;

 $columnToSort is the field name (for hashes) or element number (for arrays) on which to sort. It defaults to 0.
 $listOfColumnsToSort is an array ref of the field names (for hashes) or element numbers (for arrays) in order of which such take precedence in sorting. It defaults to [0].
 $options can include the following. The default is for numbers and undefined/blanks to sort first. The sort columns can be included here instead of as the third argument.
 {
 	numbersLast		=> TRUE,
 	nullsLast		=> TRUE,
 	sortList		=> $listOfColumnsToSort
 }

 my @unsortedArray = ('eggplant', '', undef, '.5', 2.5, 'egg', '½', 'aardvark', '0', 'umbrella', '.eggs', 'e.ggs', 'éek', 'eggs', '2', 'zebra', '10', 'éggplant');
 my @sortedArray = sort { byAny($a,$b) } @unsortedArray;
 foreach my $item (@sortedArray) { print "  $item\n"; }

=cut
#=====================================================
	my $a = shift;
	my $b = shift;
	my $options = shift;
	my $fieldList = [0];
	if (isArray($options) || isText($options)) {
		$fieldList = $options;
		$options = shift;
	}
	if (!isHash($options)) { $options = {}; }
	
	if ($options->{sortList}) { $fieldList = $options->{sortList}; }
	if (isText($fieldList)) { $fieldList = [$fieldList]; }
	if (!isArray($fieldList)) { $fieldList = [0]; }
	
	sub isNothing {
		my $input = shift;
		if (!isNumber($input) && !$input) { return TRUE; }
	}
	
	my $collator = Unicode::Collate->new();
	
	for (my $i = 0; $i < @{$fieldList}; $i++) {
		my ($a1, $b1);
		if (isArray($a)) {
			$a1 = $a->[$fieldList->[$i]];
			$b1 = $b->[$fieldList->[$i]];
		} elsif (isHash($a)) {
			$a1 = $a->{$fieldList->[$i]};
			$b1 = $b->{$fieldList->[$i]};
		} else {
			$a1 = $a;
			$b1 = $b;
		}
		
		# Handle undefined or blank vs. something
		if ($options->{nullsLast}) {
			if (isNothing($a1) && !isNothing($b1)) { return 1; }
			elsif (!isNothing($a1) && isNothing($b1)) { return -1; }
		} else {
			if (isNothing($a1) && !isNothing($b1)) { return -1; }
			elsif (!isNothing($a1) && isNothing($b1)) { return 1; }
		}
		# Handle numbers vs. non-numbers
		if ($options->{numbersLast}) {
			if (isNumber($a1) && !isNumber($b1)) { return 1; }
			elsif (!isNumber($a1) && isNumber($b1)) { return -1; }
		} else {
			if (isNumber($a1) && !isNumber($b1)) { return -1; }
			elsif (!isNumber($a1) && isNumber($b1)) { return 1; }
		}
		# Handle numbers
		no warnings 'numeric';
		if ($a1 <=> $b1) { return $a1 <=> $b1; }
		use warnings 'numeric';
		# Handle undefineds and blanks
		my $comp = $a1 cmp $b1;
		# Handle all others in a Unicode friendly way
		if ($a1 && $b1) { $comp = $collator->cmp($a1, $b1); }
		if ($comp) { return $comp; }
	}
	return 0;
}


sub joinText {
#=====================================================

=head2 B<joinText>

=cut
#=====================================================
	my $list = shift || return;
	isArrayWithContent($list) || return;
	if (@{$list} < 2) { return $list->[0]; }
	if (@{$list} == 2) { return "$list->[0] and $list->[1]"; }
	my $string = $list->[0];
	for (my $i = 1; $i < @{$list}; $i++) {
		if ($i == @{$list} - 1) { $string .= ", and $list->[$i]"; }
		else { $string .= ", $list->[$i]"; }
	}
	return $string;
}

sub camel_case {
	my $text = lc(shift);
	$text =~ s/[^a-z0-9]+([a-z])/\u$a/g;
	$text =~ s/[^a-z0-9]+//g;
	return $text;
}

sub kebab_case {
	my $text = lc(shift);
	$text =~ s/[^a-z0-9]+/-/g;
	$text =~ s/--+/-/g;
	return $text;
}

sub snake_case {
	my $text = lc(shift);
	$text =~ s/[^a-z0-9]+/_/g;
	$text =~ s/__+/_/g;
	return $text;
}

sub percent {
	my $number = shift || return;
	isNumber($number) || return;
	my $precision = shift;
	if ($precision && !isPosInt($precision)) { return; }
	my $format = "%d";
	if ($precision) { $format = "%.${precision}f"; }
	my $percent = sprintf($format, $number*100);
	return $percent;
}


sub generatePassword {
#=====================================================

=head2 B<generatePassword>

 my $password = generatePassword($options);
 $options = {
 	charset	=> 'default' || 'alpha' || 'letters' || 'numeric' || 'lower' || 'upper' || 'blank',	# defaults to 'default'
 	length	=> $lengthOfPassword	# defaults to 32
 }
 
=cut
#=====================================================
	my $defaultOption = shift;
	my $options = shift;
	if (isHash($defaultOption)) { $options = $defaultOption; }
	if (!isHash($options)) { $options = {}; }
	
	if (isPosInt($defaultOption)) { $options->{length} = $defaultOption; }
	elsif (isText($defaultOption)) { $options->{charset} = $defaultOption; }
	$options->{length} ||= 32;
	$options->{charset} ||= 'default';
	if ($options->{charset} eq 'blank') { return; }
	
	my @chars = ('a'..'z', 'A'..'Z', 0..9, '`', '~', '!', '@', '#', '$', '^', '&', '*', '(', ')', '-', '_', '=', '+', '[', '{', ']', '}', '|', ';', ',', '<', '.', '>', '/', '?');
	if ($options->{charset} eq 'alpha') { @chars = ('a'..'z', 'A'..'Z', 0..9); }
	elsif ($options->{charset} eq 'letters') { @chars = ('a'..'z', 'A'..'Z'); }
	elsif ($options->{charset} eq 'numeric') { @chars = (0..9); }
	elsif ($options->{charset} eq 'lower') { @chars = ('a'..'z'); }
	elsif ($options->{charset} eq 'upper') { @chars = ('A'..'Z'); }
	
	my $pass;
	for (my $i = 0; $i < $options->{length}; $i++) {
		$pass .= $chars[int(rand(@chars))];
	}
	return $pass;
}


sub getFilenameUTCMinute {
	my $gm = gmtime();
	my $year = $gm->year + 1900; my $mon = $gm->mon + 1;
	return sprintf("%04d-%02d-%02d_%02d-%02d", $year, $mon, $gm->mday, $gm->hour, $gm->min);
}

sub getFilenameUTCHour {
	my $gm = gmtime();
	my $year = $gm->year + 1900; my $mon = $gm->mon + 1;
	return sprintf("%04d-%02d-%02d_%02d", $year, $mon, $gm->mday, $gm->hour);
}

sub getFilenameUTCDate {
	my $gm = gmtime();
	my $year = $gm->year + 1900; my $mon = $gm->mon + 1;
	return sprintf("%04d-%02d-%02d", $year, $mon, $gm->mday);
}

sub convertArraysToCSV {
#=====================================================

=head2 B<convertArraysToCSV>

 my $csv = convertArraysToCSV($table, $debug);

=cut
#=====================================================
	my $data = shift || return;
	my $debug = shift;
	my $csv;
	my $cnt;
	foreach my $row (@{$data}) {
		my @csvRow;
		foreach my $value (@{$row}) {
			$value =~ s/"/""/g;
			if ($value =~ /[",\n\r]/) { $value = "\"$value\""; }
			push(@csvRow, $value);
		}
		my $line = join(',',@csvRow);
		$csv .=  "$line\r\n";
		if (($cnt <= 2) && $debug) { print "convertArraysToCSV: $line\n"; }
		elsif (($cnt == 3) && $debug) { print "convertArraysToCSV: ...\n"; }
		$cnt++
	}
	return $csv;
}

sub readFileList {
# my $array = readFileList($basePath);
	my $base = shift || return;
	my $path = shift;
	my $array = shift || [];
	my $filepath = $base;
	if ($path) { $filepath .= "/$path"; }
	
	if (!opendir(FILES, $filepath)) { print STDERR "Can't open dir $filepath: $!"; return; }
	my @files = grep { !/^\./ } readdir(FILES);
	closedir FILES;
	
	foreach my $file (@files) {
		my $output = $file;
		if ($path) { $output = "$path/$file"; }
		if (-d "$filepath/$file") {
			my $innerArray = readFileList($base, $output);
			push(@{$array}, @{$innerArray});
		}
		elsif (-f "$filepath/$file") {
			push(@{$array}, $output);
		}
	}
	return $array;
}

sub readFile {
# my $content = readFile($filename);
	my $file = shift || return;
	unless (open(FILE, "<$file")) { print STDERR "ERROR: Can't open file: $file\n"; return; }
	my $content;
	while (my $line = <FILE>) { $content .= $line; }
	close(FILE);
	return $content;
}

sub writeFile {
#=====================================================

=head2 B<writeFile>

 my $newpath = writeFile($path, $content, {
 	addDate		=> TRUE || FALSE,
 	makeDirs	=> TRUE || FALSE,
 	overwrite	=> TRUE || FALSE,
 	printErrors	=> TRUE || FALSE,
 }, $debug);

=cut
#=====================================================
	my $fullpath = shift || return;
	my $content = shift || return;
	my $options = shift;
	my $debug = shift;
	if (!isHash($options)) { $options = {}; }
	if ($debug) { $options->{printErrors} = TRUE; }
	
	my ($path, $filename) = $fullpath =~ /(?:(.*)\/)?(.*?)$/;
	
	# Make dir, if needed
	if ($path && !-d $path) {
		if ($options->{makeDirs}) { system("mkdir -p $path"); }
		else {
			$options->{printErrors} && print STDERR "ERROR: Directory doesn't exist: $path\n";
			return;
		}
	}
	
	if ($options->{addDate}) {
		my $time = getFilenameUTCDate;
		my ($name, $ext) = $filename =~ /(.*)\.(.*?)$/;
		if ($name && $ext) {
			$filename = "${name}_$time.$ext";
		} else {
			$filename .= "_$time";
		}
		$fullpath = "$path/$filename";
	}
	
	if (!$options->{overwrite} && -s $fullpath) {
		$options->{printErrors} && print STDERR "ERROR: File already exists: $fullpath\n";
		return;
	}
	
	unless (open(FILE, ">$fullpath")) {
		$options->{printErrors} && print STDERR "ERROR: Can't open file for writing: $fullpath\n";
		return;
	}
	print FILE $content;
	close(FILE);
	if ($filename =~ /\.(sh|pl|py|js)$/) { chmod 0755, $fullpath; }
	
	$debug && print "writeFile: path: $fullpath\n";
	return $fullpath;
}


sub maxLength {
	my $object = shift || return;
	my $limit = shift || 8192;
	my $array = [];
	if (isHash($object)) {
		@{$array} = values(%{$object});
	} elsif (isArray($object)) {
		$array = $object;
	} elsif (!ref($object)) {
		return length($object);
	} else { return; }
	my $max = 0;
	foreach my $item (@{$array}) {
		if ((length($item) > $max) && (length($item) <= $limit)) { $max = length($item); }
	}
	return $max;
}

sub printObject {
#=====================================================

=head2 B<printObject>

	my $string = 'string';
	my $function = sub { print "Lambda\n"; };
	my $function2 = \&readCustomerConfig;
	my $object = {
		test => 'sdflkj',
		very_extra_long_key_name => 1,
		a => TRUE,
		an_array => [1, 'blue', undef, "Something with a\nnewline", { a => 0, b => 1, longer => 2 }, 6, 7, 8, [], 9, 10, 11],
		undefined => undef,
		scalarref => \$string,
		function => $function,
		function2 => $function2,
		object => $self,
		emptyHash => {},
		emptyArray => []
	};
	
	printObject($object, 'My Object', 5);
	printObject('test', 'My String', 5);
	printObject('test', undef, 5);
	printObject([], undef, 5);
	printObject($function2, undef, 5);

=cut
#=====================================================
	my $object = shift;
	my $label = shift || '';
	my $indent = shift || 0;
	
	if ($label) { $label = makeColor($label, 'bold'); }
	my $string = convertObjectToString($object);
	my $indentString = ' ' x $indent;
	$string =~ s/\n/\n$indentString/gs;
	$string =~ s/$indentString$//;
	if ($label) {
		print "$indentString$label: $string";
	} else {
		print "$indentString$string";
	}
}

sub _convertObjectToStringKey {
	my $key = shift;
	my $value = shift;
	my $printKey = $key;
	if (isHash($value)) { $printKey = makeColor($key, ['green', 'bold']); }
	elsif (isArray($value)) { $printKey = makeColor($key, ['azure', 'bold']); }
	else { $printKey = makeColor($key, ['gray', 'bold']); }
	return $printKey;
}
sub convertObjectToString {
	my $object = shift;
	my $level = shift || 0;
	
	my $string = '';
	my $spacing = '.   ';
	if (termSupportsColors()) { $spacing = makeColor('+---', 'silver'); }
	my $indent = $spacing x $level;
	
	if (isHash($object)) {
		if (isHashWithContent($object)) {
			my $opening = makeColor('{', ['green', 'bold']);
			my $closing = makeColor('}', ['green', 'bold']);
			
			if ($object =~ /^(.*?)=HASH/) {
				my $printObject = makeColor($1, 'teal');
				$string .= "$printObject $opening\n";
			} else {
				$string .= "$opening\n";
			}
			my $max = 0;
			while (my($key, $value) = each(%{$object})) {
				if ((length($key) > $max) && (length($key) <= 20)) { $max = length($key); }
			}
			foreach my $key (sort { byAny($a,$b) } keys %{$object}) {
				my $value = $object->{$key};
				my $printKey = _convertObjectToStringKey($key, $value);
				my $tempMax = $max + length($printKey) - length($key) ;
				$string .= sprintf("%s%s%-${tempMax}s => ", $indent, $spacing, $printKey);
				$string .= convertObjectToString($value, $level + 1);
			}
			$string .= "$indent$closing\n";
		} else {
			$string .= "{}\n";
		}
	} elsif (isArray($object)) {
		if (isArrayWithContent($object)) {
			my $opening = makeColor('[', ['blue', 'bold']);
			my $closing = makeColor(']', ['blue', 'bold']);
			$string .= "$opening\n";
			my $arrayLength = @{$object};
			my $max = length($arrayLength);
			if ($max > 20) { $max = 20; }
			my $key = 0;
			foreach my $value (@{$object}) {
				my $fullKey = sprintf("[%${max}s]", $key);
				my $printKey = _convertObjectToStringKey($fullKey, $value);
				$string .= sprintf("%s%s%s => ", $indent, $spacing, $printKey);
				$string .= convertObjectToString($value, $level + 1);
				$key++;
			}
			$string .= "$indent$closing\n";
		} else {
			$string .= "[]\n";
		}
	} elsif (ref($object) eq 'CODE') {
		my $cv = svref_2object ( $object );
		my $gv = $cv->GV;
		my $printObject = makeColor("sub " . $gv->NAME, 'blue');
		$string .= "$printObject\n";
	} elsif (ref($object) eq 'SCALAR') {
		${$object} =~ s/\n/\\n/gm;
		${$object} =~ s/\r/\\r/gm;
		my $printObject = makeColor('"' . ${$object} . '"', 'maroon');
		$string .= "scalar $printObject\n";
	} elsif (ref($object)) {
		my $printObject = makeColor($object, 'olive');
		$string .= "$printObject\n";
	} elsif (!defined($object)) {
		my $printObject = makeColor('undef', 'line');
		$string .= "$printObject\n";
	} else {
		$object =~ s/\n/\\n/gm;
		$object =~ s/\r/\\r/gm;
		my $printObject = makeColor('"' . $object . '"', 'maroon');
		$string .= "$printObject\n";
	}
	return $string;
}

sub isPerson {
	if (($ENV{TERM} && ($ENV{TERM} ne 'dumb') && ($ENV{TERM} ne 'tty')) || $ENV{SSH_AUTH_SOCK}) {
		return TRUE;
	}
}

sub termSupportsColors {
	if ($ENV{TERM} && ($ENV{TERM} ne 'dumb') && ($ENV{TERM} ne 'tty')) { return TRUE; }
}

sub _getTermColorNumbers {
	# https://en.wikipedia.org/wiki/ANSI_escape_code
	# https://en.wikipedia.org/wiki/Web_colors
	my $debug = shift;
	if (!$debug && isHash($MonkeynessPl::Common::TermColors)) { return $MonkeynessPl::Common::TermColors; }
	
	my $colors = [
		{ name => 'reset',			num => 0 },
		{ name => 'default',		num => 39 },
		{ name => 'defaultBg',		num => 49 },
		
		{ name => 'bold',			num => 1 },	# reset 21 # yes
		{ name => 'faint',			num => 2 },	# reset 22 # yes
		{ name => 'italic',			num => 3 },	# reset 23
		{ name => 'underline',		num => 4 },	# reset 24 # yes
		{ name => 'blink',			num => 5 },	# reset 25 # yes
		{ name => 'rapid',			num => 6 },	# reset 26
		{ name => 'inverse',		num => 7 },	# reset 27 # yes
		{ name => 'conceal',		num => 8 },	# reset 28 # yes
		{ name => 'crossed',		num => 9 },	# reset 29
		
		{ name => 'white',			num => 97 },
		{ name => 'silver',			num => 37 },
		{ name => 'gray',			num => 90 },
		{ name => 'black',			num => 30 },
		
		{ name => 'red',			num => 91 },
		{ name => 'maroon',			num => 31 },
		{ name => 'yellow',			num => 93 },
		{ name => 'olive',			num => 33 },
		{ name => 'lime',			num => 92 },
		{ name => 'green',			num => 32 },
		{ name => 'cyan',			num => 96 },
		{ name => 'teal',			num => 36 },
		{ name => 'blue',			num => 94 },
		{ name => 'azure',			num => 34 },
		{ name => 'pink',			num => 95 },
		{ name => 'magenta',		num => 35 },
		
		{ name => 'whiteBg',		num => 107 },
		{ name => 'silverBg',		num => 47 },
		{ name => 'grayBg',			num => 100 },
		{ name => 'blackBg',		num => 40 },
		
		{ name => 'redBg',			num => 101 },
		{ name => 'maroonBg',		num => 41 },
		{ name => 'yellowBg',		num => 103 },
		{ name => 'oliveBg',		num => 43 },
		{ name => 'limeBg',			num => 102 },
		{ name => 'greenBg',		num => 42 },
		{ name => 'cyanBg',			num => 106 },
		{ name => 'tealBg',			num => 46 },
		{ name => 'blueBg',			num => 104 },
		{ name => 'azureBg',		num => 44 },
		{ name => 'pinkBg',			num => 105 },
		{ name => 'magentaBg',		num => 45 }
	];
	my $colorRef = {};
	for (my $color = 0; $color < @{$colors}; $color++) {
		my $item = $colors->[$color];
		$colorRef->{$item->{name}} = $item->{num};
		if ($debug) {
			my $s = "\e[$item->{num}"; my $e = "\e[0m";
			if ($color < 12) {
				printf("%14s: ${s}m%s$e\n", $item->{name}, $item->{name});
			} else {
				if ($color == 12) {
					my $header = sprintf("%14s  %-14s %-14s %-14s %-14s", '', 'default', 'bold', 'faint', 'inverse');
					print "\n" . makeColor($header, ['bold', 'underline']) . "\n";
					printf("%14s: \e[39m%-14s$e \e[39;1m%-14s$e \e[39;2m%-14s$e \e[39;7m%-14s$e\n", 'default', 'default', 'default', 'default', 'default');
				} elsif ($color == 28) {
					print "\n";
				}
				my $name = $item->{name};
				$name =~ s/Bg$//;
				printf("%14s: ${s}m%-14s$e ${s};1m%-14s$e ${s};2m%-14s$e ${s};7m%-14s$e\n", $name, $name, $name, $name, $name);
			}
		}
	}
	if ($debug) { print "\n"; }
	$MonkeynessPl::Common::TermColors = $colorRef;
	return $colorRef;
}
sub getTermColor {
	# my $colorCode = getTermColor($colorName);
	my $name = shift;
	if ($name && termSupportsColors()) {
		my $colors = _getTermColorNumbers;
		if (defined($colors->{$name})) {
			return sprintf("\e[%dm", $colors->{$name});
		}
	}
	return '';
}

sub makeColor {
	my $text = shift;
	my $color = shift || 'bold';
	my $bg = shift;
	termSupportsColors() || return $text;
	my $debug = shift;
	
	if ($bg) {
		if (isArray($color)) { push(@{$color}, "${bg}Bg"); }
		else { $color = [$color, "${bg}Bg"]; }
	}
	
	my $colorNumbers = _getTermColorNumbers($debug);
	if (isArray($color)) {
		my @colorList;
		foreach my $item (@{$color}) {
			if ($colorNumbers->{$item}) { push(@colorList, $colorNumbers->{$item}); }
		}
		@colorList || return $text;
		return sprintf("\e[%sm%s\e[0m", join(';', @colorList), $text);
	} elsif ($colorNumbers->{$color}) {
		return sprintf("\e[%dm%s\e[0m", $colorNumbers->{$color}, $text);
	}
	return $text;
}

sub resetColor {
	my $colors = getTermColors();
	if (exists($colors->{reset})) { return $colors->{reset}; }
	return '';
}

sub bold {
	return makeColor(shift, 'bold');
}

sub printBold {
	print makeColor(shift, 'bold');
}

sub sayBold {
	print makeColor(shift, 'bold') . "\n";
}

sub mark {
	my $label = shift;
	if ($label) { $label .= ' '; }
	
	my @returns = caller(1);
	my $location = "$returns[3] - Line $returns[2]";
	if (!@returns) { @returns = caller(0); $location = "$returns[1] - Line $returns[2]"; }
	
	state $counter = 0;
	print makeColor(' ' . $counter++ . ' ', ['bold', 'inverse']) . 
		bold(" ${label}===> $location") . "\n";
}


=head1 CHANGES

  20070628 TJM - v1.0 copied from various places
  20140320 TJM - v7.0 Modernized
  20170914 TJM - v8.0 Open sourced

=head1 AUTHOR

  Tim Moses <tim@moses.com>
  Monkeyness <http://www.monkeyness.com/>

=cut

1;
