package Amin::Cond::Hostname;

#Amin Hostname Conditional

use strict;
use vars qw(@ISA);
use Amin::Elt;
use Sys::Hostname;

@ISA = qw(Amin::Elt);

my $local_hostname = hostname();
my $state = 0;

sub version {
	return "1.0";
}
#log = 1 Super = 0
sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};
	my $log = $self->{Spec}->{Log};
	
	if ($element->{LocalName} eq "cond"){
		$log->driver_start_element($element->{Name}, %attrs);
		$state = 1;
	}
	if ($element->{LocalName} eq $local_hostname) {
		$self->SUPER::start_element($element);
		$state = 0;
	}
	if ($state == 1) {
		unless (($element->{LocalName} eq "cond") ||
			($element->{LocalName} eq $local_hostname)) {
			$log->driver_start_element($element->{Name}, %attrs);
		}
	} else {
		unless (($element->{LocalName} eq $local_hostname) ||
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

sub end_element {
	my ($self, $element) = @_;
	my $log = $self->{Spec}->{Log};
	
	if ($element->{LocalName} eq "cond"){
		$state = 0;
		$self->SUPER::end_element($element);
	}	
	if ($element->{LocalName} eq $local_hostname) {
		$state = 1;
		$self->SUPER::end_element($element);
	}	
	if ($state == 1) {
		unless (($element->{LocalName} eq $local_hostname) ||
			($element->{LocalName} eq "cond")) {
			$log->driver_end_element($element->{Name});
		}
	} else {
		unless (($element->{LocalName} eq "cond") ||
			($element->{LocalName} eq $local_hostname)) {
			$self->SUPER::end_element($element);
		}
	}	
}
1;

=head1 NAME

Hostname - reader class filter for the Hostname conditional.

=head1 version

Hostname version 1.0

=head1 DESCRIPTION

  A reader class for the Hostname conditional. This module uses 
  uses system's hostnames to determine which conditional xml 
  block to use. Any hostname can be used.

=head1 XML

=over 4

=item Full example

  <!-- hostnames named after members of the grateful dead -->

  <amin:cond name="hostname">
    <amin:jerry>
      <amin:command name="mkdir">
        <amin:param>/tmp/jerry</amin:param>
      </amin:command>
    </amin:jerry>
    <amin:bobby>
      <amin:command name="mkdir">
        <amin:param>/tmp/bobby</amin:param>
      </amin:command>
    </amin:bobby>
    <amin:phil>
      <amin:command name="mkdir">
        <amin:param>/tmp/phil</amin:param>
      </amin:command>
    </amin:phil>
    <amin:bill>
      <amin:command name="mkdir">
        <amin:param>/tmp/bill</amin:param>
      </amin:command>
    </amin:bill>
    <amin:mickey>
      <amin:command name="mkdir">
        <amin:param>/tmp/mickey</amin:param>
      </amin:command>
    </amin:mickey>
    <amin:keyboardist>
      <amin:command name="mkdir">
        <amin:param>/tmp/keyboardist</amin:param>
      </amin:command>
    </amin:keyboardist>
  </amin:cond>

=back  

=cut


