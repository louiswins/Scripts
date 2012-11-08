#!/usr/bin/perl -w
use strict;
use File::Find;
use Digest::MD5;
use List::Util qw(max reduce);

my $ctx = Digest::MD5->new;
my %files;

sub md5file {
	my $filename = shift;
	open(my $fh, $filename) or die "Cannot open $filename: $!";
	binmode $fh;
	return $ctx->addfile($fh)->b64digest;
}

sub wanted {
	return if (-d $_);
	my $md5 = md5file $_;
	if (exists $files{$md5}) {
		push @{ $files{$md5} }, $File::Find::name;
	} else {
		$files{$md5} = [ $File::Find::name ];
	}
}

sub pad {
	my $str = shift;
	my $len = shift;
	return $str . (" " x ($len - length $str));
}




my @dirs = @ARGV;
@dirs = '.' unless @dirs;

foreach my $dir (@dirs) {
	find \&wanted, $dir;
}

# The grep gets only the md5sums which have more than one file, then the map
# selects the filenames (because I don't care at all what the md5sums are)
my @dups = map { $files{$_} } grep { $#{ $files{$_} } } keys %files;

unless (@dups) {
	print "No duplicates found.\n";
	exit 0;
}

# Find padding lengths. This is pretty inefficient, but it is dwarfed by
# the time taken by md5sum above, so don't worry about it.
my $maxnumdups = max map { $#{ $_ } } @dups;
my @lengths;
foreach my $i (0 .. $maxnumdups) {
	$lengths[$i] = reduce {
		# If this list of duplicates has at least $i elements
		@$b > $i ?
		max($a, length $b->[$i])
		: $a
	} 0, @dups;
}

print "Duplicates:\n";
foreach my $list (@dups) {
	foreach my $i (0 .. $#{ $list }) {
		print pad($list->[$i], $lengths[$i]), " ";
	}
	print "\n";
}
