package Adistro::Stage;

#Adistro Stage

use strict;
use vars qw(@ISA);
use XML::SAX::Base;
use Amin::Elt;

@ISA = qw(Amin::Elt XML::SAX::Base);

my $state = 1;
my $otherstate = 0;
my %attrs;

sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};
	$self->attrs(%attrs);
	my $param = $self->{Spec}->{Filter_Param};

	if ($element->{LocalName} eq "stage") {
		unless ($attrs{'{}name'}->{Value} eq $param) {
			$state = 0;
		}
	}
	if (($state == 1) || ($otherstate == 1)) {
		unless ($element->{LocalName} eq "stage") {
			$self->SUPER::start_element($element);
		}
	}
	if ($element->{LocalName} eq "stage") {
		$self->SUPER::start_element($element);
	}
}

sub characters {
	my ($self, $chars) = @_;
	
	if (($state == 1) || ($otherstate == 1))  {
		$self->SUPER::characters($chars);
	}
}

sub end_element {
	my ($self, $element) = @_;
	my $attrs = $self->{"ATTRS"};
	
	if (($state == 1) || ($otherstate == 1)) {
		unless ($element->{LocalName} eq "stage") {
			$self->SUPER::end_element($element);
		}
	}
	if ($element->{LocalName} eq "stage") {
		$self->SUPER::end_element($element);
	}
}

1;


=head1 NAME
 
Adistro::Stage - reader class filter for the <adistro:stage name=""> element.

=head1 version

Adistro::Stage amin-0.5.0

=head1 DESCRIPTION

  A reader class for the <adistro:stage name=""> element. Name
  is supplied via the controller to the machine. This is known 
  as a controller/machine filter_param. So looking at the example
  below, if you wanted to run the install stage with the amin controller
  you would type 
  
  amin -u file://my/package.xml -x install
  
  Your controller can set the filter_param internally and there
  is no need for typing out filter_param(s). 
  
=head1 XML

=over 4

=item Full example

 <adistro:stage name="install" >
     <amin:command name="touch">
       <amin:param>/tmp/install</amin:param>
     </amin:command>
 </adistro:stage>
 <adistro:stage name="remove" >
     <amin:command name="remove">
       <amin:param>/tmp/install</amin:param>
     </amin:command>
 </adistro:stage>
 <!-- and so on-->

=back  

=cut
