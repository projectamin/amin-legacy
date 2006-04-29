package Amin::Machine::Dispatcher;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

#Amin Dispatcher Machine

use strict;
use vars qw(@ISA);
use Amin::Machine;
use Amin::Machine::Filter::Dispatcher;

@ISA = qw(Amin::Machine);

sub new {
	my ($self, $spec) = @_;
	$spec->{Machine_Name} = Amin::Machine::Filter::Dispatcher->new();
	#deal with the filter_list ie set it up for a dispatcher filter machine
	my $fl = $spec->{Filter_List};
	
	#deal with the end first
	my $end;
	foreach (keys %$fl) {
		if ($fl->{$_}->{position} eq "end") {
			if (!$end) {
				$end = $fl->{$_}->{module}->new(Handler => $spec->{Handler}, Spec => $spec);
			} else {
				$end = $fl->{$_}->{module}->new(Handler => $end, Spec => $spec);
			}
		}
	}
	
	#deal with the middle	
	foreach (keys %$fl) {
		if ($fl->{$_}->{position} eq "middle") {
			my $middle;
			if ($end) {
				$middle = $fl->{$_}->{module}->new(Handler => $end, Spec => $spec);
			} else {
				$middle = $fl->{$_}->{module}->new(Handler => $spec->{Handler}, Spec => $spec);
			}
			$fl->{$_}->{chain} = $middle; 
		}
	}
	
	#deal with the beginning	
	foreach (keys %$fl) {
		if ($fl->{$_}->{position} eq "begin") {
			#get the parent's kids
			my $begin;
			my %repeats;
			foreach my $kid (keys %$fl) {
				if ($fl->{$kid}->{parent_stage} == $_) {
					if ($kid == $_) { 
						#this is the same parent filter skip it
						next;
					}
					my $repeat = $fl->{$kid}->{module};
					if ($repeats{$repeat} eq "r") {
						delete $fl->{$kid};
						next;
					}
					#this is one of the kids
					if (!$begin) {
						$begin = $fl->{$kid}->{module}->new(Handler =>$spec->{Handler}, Spec =>$spec);
						$repeats{$repeat} = "r";
						delete $fl->{$kid};
					} else {
						$begin = $fl->{$kid}->{module}->new(Handler =>$begin, Spec =>$spec);
						$repeats{$repeat} = "r";
						delete $fl->{$kid};
					}
				}
			}
			#add in the parent
			$begin = $fl->{$_}->{module}->new(Handler => $begin, Spec => $spec);
			$fl->{$_}->{chain} = $begin; 
		}
	}
	#put our new wierd filter list back as the spec's Filter_List
	$spec->{Filter_List} = $fl;
	return $self->SUPER::new($spec);
}

1;

=head1 NAME

Amin::Machine::Dispatcher - base class for a Dispatcher machine

=head1 DESCRIPTION

Please see Amin::Machine::Filter::Dispatcher for details on the
Dispatcher machine

This module is also ISA Amin::Machine. After setting the internal
spec's Machine_Name, we call Amin::Machine's new() with our $spec
to build our amin machine. This is done by manipulation of the $spec
and then calling Amin::Machines to run our machine with our manipulated
$spec.

We manipulate the $spec given to us by Machine_Spec.pm module as follows

1. We process all end filters first. All we do is hook the machine's
   Handler to the end filter. 
   
2. We process all the middle filters. This is similiar to end filters.
   If there are end filters they are added to each middle fitler chain
   as appropriate
   
3. We process all the begin filters. This is similiar to how end/middle
   filters work with one major difference. Each "sax chain" is seperated
   out into it's own chain inside the profile. This means that this begin
   filter will only deal with, worry about it's kids, grandkids etc. 

=cut