package Amin::Protocol::Standard;

use strict;


sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);	
	return $self;
}

sub parse_uri {
	my $self = shift;
	my $uri = shift;
	
	print "$uri\n";
}


1;
