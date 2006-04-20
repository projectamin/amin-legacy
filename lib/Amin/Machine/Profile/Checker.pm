package Amin::Machine::Profile::Checker;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);

my $return = 0;
sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};
	if ($element->{Name} eq "amin:message") {
		if ($attrs{'{}type'}->{Value} eq "error") {
			$return = 1;
		}
	}
}

sub end_document {
	my $self = shift;
	return $return;
}

1;

=head1 NAME

Amin::Profile::Checker - checks for error messages in any profile.

=head1 version 1.0


=head1 DESCRIPTION

  Checks for error messages in any profile.. This module does so by 
  setting a $return to 0 value and then scanning the entire results for any 
  
  <amin:message type="error">
  
  If found, $return is set to fail(1) instead of pass(0).

  Example Usage:
  
  my $h = Amin::Profile::Checker->new();
  my $p = XML::SAX::PurePerl->new(Handler => $h);
  my $result = $p->parse_string($results);	
  #do something with $result
    


=cut
