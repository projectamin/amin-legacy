package Amin::Cond::OS;

use strict;
use vars qw(@ISA);
use Amin::Elt;
use Config;

@ISA = qw(Amin::Elt);

my $state = 0;

my $os = $^O;

if ($os =~ /darwin/) {
	$os = "darwin";
} elsif ($os =~ /freebsd/) {
	$os = "freebsd";
} elsif ($os =~ /openbsd/) {
	$os = "openbsd";
} else {
	$os = "linux";
}

#log = 1 Super = 0
sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};
	my $log = $self->{Handler}->{Spec}->{Log};

	if ($element->{LocalName} eq "cond") {
		$state = 1;
		$log->driver_start_element($element->{Name}, %attrs);
	}
	if ($os eq $element->{LocalName}) {
		$state = 0;
		$self->SUPER::start_element($element);
	}
	if ($state == 1) {
		unless (($element->{LocalName} eq "cond") ||
			($element->{LocalName} eq $os)) {
			$log->driver_start_element($element->{Name}, %attrs);
		}
	} else {
		unless (($element->{LocalName} eq $os) ||
			($element->{LocalName} eq "cond")) {
			$self->SUPER::start_element($element);
		}
	}
	
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	my $log = $self->{Handler}->{Spec}->{Log};
	$data = $self->fix_text($data);
	if ($data ne "") {
		if ($state == 1) {
			$log->driver_characters($data);
		} else {
			$self->SUPER::characters($chars);
		}
	}
}

sub end_element {
	my ($self, $element) = @_;
	my $log = $self->{Handler}->{Spec}->{Log};
	
	if ($element->{LocalName} eq "cond") {
		$state = 0;
		$self->SUPER::end_element($element);
	}
	if ($element->{LocalName} eq $os) {
		$state = 1;
		$self->SUPER::end_element($element);
	}
	if ($state == 1) {
		unless (($element->{LocalName} eq "cond") ||
			($element->{LocalName} eq $os)) {
			$log->driver_end_element($element->{Name});
		}
	} else {
		unless (($os eq $element->{LocalName}) ||
			($element->{LocalName} eq "cond")) {
			$self->SUPER::end_element($element);
		}
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
	default	
  
=head1 XML

=over 4

=item Full example

  <amin:cond name="os">
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
    <amin:linux>
      <amin:command name="mkdir">
        <amin:param>/tmp/linux</amin:param>
      </amin:command>
    </amin:linux>
  </amin:cond>

=back  

=cut


