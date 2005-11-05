package Amin::Profile::Checker;

use strict;
my $return = 0;
sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	if ($attrs{'{}type'}->{Value} eq "error") {
		$return = 1;
	}
}

sub end_document {
	my $self = shift;
	return \$return;
}

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
