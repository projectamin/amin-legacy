package Amin::Depend::Checker;

use strict;

my $return = "pass";


sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	
	if ($attrs{'{}type'}->{Value} eq "error") {
		$return = "fail";
	}
}

sub end_document {
	my $self = shift;
	return \$return;
}

=head1 NAME

Amin::Depend::Checker - reader class filter for the depend element.

=head1 version


=head1 DESCRIPTION

  A reader class for the depend element. This module is used 
  by Amin::Depend to check if it's <test> had any failures 
  or not. This module does so by setting a $return value and
  then scanning the entire results for any 
  
  <amin:message type="error">
  
  If found, $return is set to fail.
  
=cut
