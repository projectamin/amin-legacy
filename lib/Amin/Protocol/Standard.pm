package Amin::Protocol::Standard;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

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
