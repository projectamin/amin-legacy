package Amin::Profile::Type;

use strict;
use vars qw(@ISA);
use Amin::Elt;
@ISA = qw(Amin::Elt);
my $type;
my $check;

sub start_document {
	my $self = shift;
	$type = undef;
	$check = undef;
}

sub start_element {
	my ($self, $element) = @_;
	if ($check ne "yes") {
	
		if ($element->{Name} eq "amin:profile") {
			$type = "profile";
			$check = "yes";
		}
		if ($element->{Name} eq "amin:adminlist") {
			$type = "adminlist";
			$check = "yes";
		}
		if ($element->{Name} eq "amin:networkmap") {
			$type = "networkmap";
			$check = "yes";
		}
	}
	$self->element($element);
	$self->SUPER::start_element($element);
}

sub end_document {
	my $self = shift;
	return $type;
}

1;

=head1 NAME

Amin::Profile::Type - 

=head1 version 1.0

=head1 DESCRIPTION

This is a filter whose sole purpose is to find which type
of xml document this is, ie adminlist, networkmap or profile. 
It does this by grabbing whatever comes "first" and then 
returning that type. 

=cut
