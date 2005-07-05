package Amin::Cond::OS;

use strict;
use vars qw(@ISA);
use Amin::Elt;
use Config;

@ISA = qw(Amin::Elt);

my $state = 0;
my $otherstate = 0;

my $OS = $^O;

if ($OS =~ /darwin/) {
	$OS = "darwin";
}
elsif ($OS =~ /freebsd/) {
	$OS = "freebsd";
}
elsif ($OS =~ /openbsd/) {
	$OS = "openbsd";
} else {
	$OS = "default";
}



sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};

	if (($state == 1) || ($otherstate == 1)) {
		unless ($element->{LocalName} eq "cond") {
			$self->SUPER::start_element($element);
		}
	}
	if ($OS eq "darwin") {
		if ($element->{LocalName} eq "darwin") {
			$state = 1;
			$self->SUPER::start_element($element);
		}
	}
	if ($OS eq "freebsd") {
		if ($element->{LocalName} eq "freebsd") {
			$state = 1;
			$self->SUPER::start_element($element);
		}
	}
	if ($OS eq "openbsd") {
		if ($element->{LocalName} eq "openbsd") {
			$state = 1;
			$self->SUPER::start_element($element);
		}
	}
	if ($OS eq "linux") {
		if (($element->{LocalName} eq "linux") || ($element->{LocalName} eq "default")) {
			$state = 1;
			$self->SUPER::start_element($element);
		}
	}
	if ($element->{LocalName} eq "cond") {
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
	if (($state == 1) || ($otherstate == 1)) {
		unless ($element->{LocalName} eq "cond") {
			$self->SUPER::end_element($element);
		}
	}
	
	if (($element->{LocalName} eq "darwin") || ($element->{LocalName} eq "freebsd") || 
	   ($element->{LocalName} eq "openbsd") || ($element->{LocalName} eq "linux")  ||
	   ($element->{LocalName} eq "default")) 
	{
		$state = 0;
	}
	
	if ($element->{LocalName} eq "cond") {
		$otherstate = 1;
		$self->SUPER::end_element($element);
	}
}

1;

=head1 NAME

OS - reader class filter for the OS conditional.

=head1 version

OS version 1.0

=head1 DESCRIPTION

  A reader class for the OS conditional. This module uses 
  perl's internal configuration variable to determine the 
  system OS
   
  The types known by this module is 
  
	darwin
	freebsd
	openbsd
	
  everything else, including linux is considered as 
	
	default	
 
  either linux or default is acceptable in your xml. 
  
=head1 XML

=over 4

=item Full example

  <amin:cond name="OS">
    <amin:darwin>
      <amin:command name="mkdir">
        <amin:param>/tmp/darwin</amin:param>
      </amin:command>
    </amin:darwin>
    <amin:freebsd>
      <amin:command name="mkdir">
        <amin:param>/tmp/freebsd</amin:param>
      </amin:command>
    </amin:freebsd>
    <amin:openbsd>
      <amin:command name="mkdir">
        <amin:param>/tmp/openbsd</amin:param>
      </amin:command>
    </amin:openbsd>
    <amin:default>
      <amin:command name="mkdir">
        <amin:param>/tmp/linux</amin:param>
      </amin:command>
    </amin:default>
  </amin:cond>

=back  

=cut


