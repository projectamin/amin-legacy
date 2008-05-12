package Amin::Cond;

#Amin Cond

use strict;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);

my $state = 0;
my %attrs;
#log = 1 Super = 0
sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};
	$self->attrs(\%attrs);
	my $param = $self->{Spec}->{Filter_Param};
	my $log = $self->{Spec}->{Log};
	
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "cond")){
		$self->command("cond");
		if ($attrs{'{}name'}->{Value} eq $param) {
			$state = 0;
			$self->SUPER::start_element($element);
		} else {
			$state = 1;
			$log->driver_start_element($element->{Name}, %attrs);
		}
	}
	if ($state == 1) {
		unless ($element->{LocalName} eq "cond") {
			$log->driver_start_element($element->{Name}, %attrs);
		}
	} else {
		unless ($element->{LocalName} eq "cond") {
			$self->SUPER::start_element($element);
		}
	}
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	my $log = $self->{Handler}->{Spec}->{Log};
	$data = $self->fix_text($data);
	if (($self->command eq "cond") && ($data ne "")) {
		if ($state == 1) {
			$log->driver_characters($data);
		} else {
			$self->SUPER::characters($chars);
		}
	}
}

sub end_element {
	my ($self, $element) = @_;
	my $attrs = $self->attrs;
	my $param = $self->{Spec}->{Filter_Param};
	my $log = $self->{Handler}->{Spec}->{Log};

	if (($element->{LocalName} eq "cond") && ($self->command eq "cond")) {
		if ($attrs{'{}name'}->{Value} eq $param) {
			$state = 1;
			$self->SUPER::end_element($element);
		} else {
			$state = 0;
			$log->driver_end_element($element->{Name});
		}
	}
	if ($state == 1) {
		unless ($element->{LocalName} eq "cond") {
			$log->driver_end_element($element->{Name});
		}
	} else {
		unless ($element->{LocalName} eq "cond") {
			$self->SUPER::end_element($element);
		}
	}
}

sub version {
	return "1.0";
}


1;


=head1 NAME
 
Amin::Cond - reader class filter for the <amin:cond name=""> element.

=head1 version

Amin::Cond Amin 1.0

=head1 DESCRIPTION

  A reader class for the <amin:cond name=""> element. Name
  is supplied via the controller to the machine. This is known 
  as a controller/machine filter_param. So looking at the example
  below, if you wanted to run the start stage with the amin controller
  you would type 
  
  amin -u file://my/profile.xml -x ia32
  
  Your controller can also set the filter_param(s) internally and 
  there may be no need for typing out filter_param(s). Please consult
  your controller documentation. 
  
  
=head1 XML

=over 4

=item Full example

 <amin:cond name="ia32" >
     <amin:command name="mkdir">
       <amin:param>/tmp/ia32</amin:param>
     </amin:command>
 </amin:cond>
 <amin:cond name="sparc64" >
     <amin:command name="mkdir">
       <amin:param>/tmp/sparc64</amin:param>
     </amin:command>
 </amin:cond>
 <!-- and so on-->

=back  

=cut
