package Amin::Machine::Dispatcher;

#LICENSE:
#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

#Amin Dispatcher Machine
use strict;
use Amin::Machine::Filter::Dispatcher;

my $end;
my $middle;
my $checker = "no";

sub new {
	
	my $proto = shift;
	my $class = ref $proto || $proto;
	my $spec = shift;
 	my @options_if_any = @_ && ref $_[-1] eq "HASH" ? %{pop()} : ();
 	my $self = bless { @options_if_any }, $class;
	$spec->{Machine_Name} = Amin::Machine::Filter::Dispatcher->new();
	$end = undef;
	$middle = undef;
	$checker = "no";
	#deal with the filter_list ie set it up for a dispatcher filter machine
	my $fl = $spec->{Filter_List};
	#deal with the end first
	foreach (keys %$fl) {
		if ($fl->{$_}->{position} =~ /end/) {
			if (!$end) {
				$end = $fl->{$_}->{module}->new(Handler => $spec->{Handler}, Spec => $spec);
			} else {
				$end = $fl->{$_}->{module}->new(Handler => $end, Spec => $spec);
			}
			#delete $fl->{$_};
		}
	}
	#deal with the middle	
	my %repeats;
	foreach (keys %$fl) {
		my $repeat = $fl->{$_}->{module};
		if (defined $repeats{$repeat} eq "r") {
			next;
		} elsif ($fl->{$_}->{position} =~ /middle/) {
			$checker = "yes";
			if (!$middle) {
				if ($end) {
					$middle = $fl->{$_}->{module}->new(Handler => $end, Spec => $spec);
					$repeats{$repeat} = "r";
				} else {
					$middle = $fl->{$_}->{module}->new(Handler => $spec->{Handler}, Spec => $spec);
					$repeats{$repeat} = "r";
				}
			} else {
				$middle = $fl->{$_}->{module}->new(Handler => $middle, Spec => $spec);
				$repeats{$repeat} = "r";
			}
			#build a middle 1 chain in case there is none.
			#delete $fl->{$_};
		}
	}
	#since we may have an end with no middle and only permanents
	if ($end) {
		if (!$middle) {
			#we need to make the $middle variable the $end as well
			#so we don't have to check for both later....
			$middle = $end;
		}
	}
	my $pbegin;
	#deal with the permanents
	foreach my $perms (keys %$fl) {
		if ($fl->{$perms}->{position} =~ /permanent/) {
			#this is a permanent
			if ($pbegin) {
				if ($fl->{$perms}->{module}) {
					#this catches commented out permanent filters
					$pbegin = $fl->{$perms}->{module}->new(Handler => $pbegin, Spec => $spec);
				}
			} else {
				if ($fl->{$perms}->{module}) {
					$pbegin = $fl->{$perms}->{module}->new(Handler => $middle, Spec => $spec);
				}
			}
			delete $fl->{$perms};
		}
	}
	
	my $no_begin = 0;
	#deal with the beginning	
	foreach (keys %$fl) {
		if ($fl->{$_}->{position} eq "begin") {
			#get the parent's kids
			my $begin;
			$no_begin=1;
			if ($end) {
				$begin = $end;
			}
			if ($pbegin) {
				if ($end) { 
					#how to do?
					#broke
					
				} else {
					$begin = $pbegin;
				}
			}
			my %repeats;
			#deal with permanents
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
	if ($no_begin == 0) {
		if ($pbegin) {
			$fl->{1}->{chain} = $pbegin;
		} else {
			$fl->{1}->{chain} = $middle;
		}
		#delete everything else in the filter list as there are no begins
		foreach (keys %$fl) {
			if ($_ eq "1") {
				next;
			} else {
				delete $fl->{$_};
			}
		}
	}
	#put our new wierd filter list back as the spec's Filter_List
	$spec->{Filter_List} = $fl;
	$self->{Spec} = $spec;
	return $self;
}

sub parse_uri {
	my ($self, $uri) = @_;
	my $type = "uri";
	my $results = $self->run($uri, $type);
	return $results;
}

sub parse_string {
	my ($self, $profile) = @_;
	my $results = $self->run($profile);
	return $results;
}

sub run {
	my ($self, $profile, $type) = @_;
	#build the machine
	my $spec = $self->{Spec};
	#add in the machine itself
	my $machine = $spec->{Machine_Name}->new(Handler => $spec->{Handler}, Spec => $spec);
	$spec->{Machine_Handler} = $machine;
	#grab a new sax parser and parse this sucker
	my $p = $spec->{Generator}->new(Handler => $machine, Spec => $spec);
	if ($type eq "uri") {
		$p->parse_uri( $profile );
	} else {
		$p->parse_string( $profile );
	}
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