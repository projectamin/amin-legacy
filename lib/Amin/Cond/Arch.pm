package Amin::Cond::Arch;

#Amin Arch

use strict;
use vars qw(@ISA);
use XML::SAX::Base;
use Amin::Elt;
use Config;

@ISA = qw(Amin::Elt XML::SAX::Base);

my $state = 0;
my $otherstate = 0;

my $arch = $Config{'archname'};

	if ($arch =~ /ppc/) {
			$arch = "ppc32";
	}
		elsif ($arch =~ /^ppc64$/) {
			$arch = "ppc64";
	}
		elsif ($arch =~ /Power \Macintosh/) {
			$arch = "ppc32";
	}
		elsif ($arch =~ /s390/) {
			$arch = "s390";
	}
		elsif ($arch =~ /x86_64/) {
			$arch = "x86_64";
	}
		elsif ($arch =~ /ia64/) {
			$arch = "ia64";
	} else {
		$arch = "default";	
	}

sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};

	if (($state == 1) || ($otherstate == 1)) {
		unless ($element->{LocalName} eq "cond") {
			$self->SUPER::start_element($element);
		}
	}
	if ($arch eq "default") {
		if (($element->{LocalName} eq "ia32") || ($element->{LocalName} eq "default")) {
			$state = 1;
			$self->SUPER::start_element($element);
		}
	}
	if ($arch eq "ia64") {
		if ($element->{LocalName} eq "ia64") {
			$state = 1;
			$self->SUPER::start_element($element);
		}
	}
	if ($arch eq "ppc32") {
		if ($element->{LocalName} eq "ppc32") {
			$state = 1;
			$self->SUPER::start_element($element);
		}
	}
	if ($arch eq "ppc64") {
		if ($element->{LocalName} eq "ppc64") {
			$state = 1;
			$self->SUPER::start_element($element);
		}
	}
        if ($arch eq "x86_64") {
                if ($element->{LocalName} eq "x86_64") {
                        $state = 1;
                        $self->SUPER::start_element($element);
                }
        }
	if ($arch eq "S390") {
		if ($element->{LocalName} eq "s390") {
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
	
	if (($element->{LocalName} eq "ia32") || ($element->{LocalName} eq "ia64") || 
	   ($element->{LocalName} eq "ppc32") || ($element->{LocalName} eq "s390") ||
	   ($element->{LocalName} eq "x86_64") || ($element->{LocalName} eq "ppc64") || 
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

Arch - reader class filter for the Arch conditional.

=head1 version

Arch version 1.0

=head1 DESCRIPTION

  A reader class for the Arch conditional. This module uses 
  perl's internal configuration variable to determine the 
  system name/type.
   
  The types known by this module is 
  
	ppc32
	ppc64
	s390
	x86_64
	ia64
	
  everything else, including ia32 is considered as 
	
	default	
 
  either ia32 or default is acceptable in your xml. 
  
=head1 XML

=over 4

=item Full example

  <amin:cond name="arch">
    <amin:ppc32>
      <amin:command name="mkdir">
        <amin:param>/tmp/ppc32</amin:param>
      </amin:command>
    </amin:ppc32>
    <amin:ppc64>
      <amin:command name="mkdir">
        <amin:param>/tmp/ppc64</amin:param>
      </amin:command>
    </amin:ppc64>
    <amin:s390>
      <amin:command name="mkdir">
        <amin:param>/tmp/s390</amin:param>
      </amin:command>
    </amin:s390>
    <amin:x86_64>
      <amin:command name="mkdir">
        <amin:param>/tmp/x86_64</amin:param>
      </amin:command>
    </amin:x86_64>
    <amin:ia64>
      <amin:command name="mkdir">
        <amin:param>/tmp/ia64</amin:param>
      </amin:command>
    </amin:ia64>
    <amin:default>
      <amin:command name="mkdir">
        <amin:param>/tmp/ia32</amin:param>
      </amin:command>
    </amin:default>
  </amin:cond>

=back  

=cut
