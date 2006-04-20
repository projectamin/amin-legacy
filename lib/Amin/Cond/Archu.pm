package Amin::Cond::Archu;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

#Amin Archu

use strict;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);

my $state = 0;
my $arch = qx/uname -m/;

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

	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "cond") && ($attrs{'{}name'}->{Value} eq "archu")) {
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
	if (($self->command eq "archu") && ($data ne "")) {
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
	
	if (($element->{LocalName} eq "cond") && ($self->command eq "archu")) {
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

Archu - reader class filter for the Archu conditional.

=head1 version

Archu version 1.0

=head1 DESCRIPTION

  A reader class for the Archu conditional. This is the 
  same as the Arch conditional. The only difference is the
  usage of uname instead of perl's internal configuration
  variable to determine the system name. Please see 
  Amin::Cond::Arch for additional information. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
	<!-- in this example, only run the mkdir command if 
	     the arch ran on is an ia64 arch. Otherwise don't
	     do anything-->
	     
        <amin:cond name="arch">
                <amin:ia64>
                        <amin:command name="mkdir">
                                <amin:param>/tmp/ia64</amin:param>
                        </amin:command>
                </amin:ia64>
        </amin:cond>
 </amin:profile>

=back  

=cut
