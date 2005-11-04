package Amin::Cond::Arch;

#Amin Arch

use strict;
use vars qw(@ISA);
use Amin::Elt;
use Config;

@ISA = qw(Amin::Elt);

my $state = 0;
my $arch = $Config{'archname'};

if ($arch =~ /ppc/) {
	$arch = "ppc32";
} elsif ($arch =~ /^ppc64$/) {
	$arch = "ppc64";
} elsif ($arch =~ /Power \Macintosh/) {
	$arch = "ppc32";
} elsif ($arch =~ /s390/) {
	$arch = "s390";
} elsif ($arch =~ /x86_64/) {
	$arch = "x86_64";
} elsif ($arch =~ /ia64/) {
	$arch = "ia64";
} else {
	$arch = "ia32";
}

sub version {
	return "1.0";
}
#log = 1 Super = 0
sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};
	my $log = $self->{Spec}->{Log};
	
	if ($element->{LocalName} eq "cond") {
		$state = 1;
		$log->driver_start_element($element->{Name}, %attrs);
	}
	if ($element->{LocalName} eq $arch) {
		$self->SUPER::start_element($element);
		$state = 0;
	}
	if ($state == 1) {
		unless (($element->{LocalName} eq "cond") ||
			($element->{LocalName} eq $arch)) {
			$log->driver_start_element($element->{Name}, %attrs);
		}
	} else {
		unless (($element->{LocalName} eq $arch) ||
			($element->{LocalName} eq "cond")) {
			$self->SUPER::start_element($element);
		}
	}
	
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	my $log = $self->{Spec}->{Log};
	$data = $self->fix_text($data);
	if ($data ne "") {
		if ($state == 1) {
			$log->driver_characters($data);
		} else {
			$self->SUPER::characters($chars);
		}
	}
}

#log = 1 Super = 0
sub end_element {
	my ($self, $element) = @_;
	my $log = $self->{Spec}->{Log};
	
	if ($element->{LocalName} eq "cond") {
		$state = 0;
		$self->SUPER::end_element($element);
	}
	if ($element->{LocalName} eq $arch) {
		$state = 1;
		$self->SUPER::end_element($element);
	}
	if ($state == 1) {
		unless (($element->{LocalName} eq "cond") ||
			($element->{LocalName} eq $arch)) {
			$log->driver_end_element($element->{Name});
		}
	} else {
		unless (($arch eq $element->{LocalName}) ||
			($element->{LocalName} eq "cond")) {
			$self->SUPER::end_element($element);
		}
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
	ia32	
 
  
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
    <amin:ia32>
      <amin:command name="mkdir">
        <amin:param>/tmp/ia32</amin:param>
      </amin:command>
    </amin:ia32>
  </amin:cond>

=back  

=cut
