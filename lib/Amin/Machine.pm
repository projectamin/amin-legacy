package Amin::Machine;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;

sub new {
	my $class = shift;
	my $spec = shift;
	my $self = {};
	bless($self, $class);	
	$self->{Spec} = $spec;
	return $self;
}

sub run {
	my ($self, $profile, $type) = @_;
	#build the machine
	my $spec = $self->{Spec};
	#deal with the filter_list
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
		if ($fl->{$_}->{parent}) {
			my $parent = $fl->{$_}->{parent};
			my $begin;
			foreach my $child (@$parent) {
				foreach my $filter (keys %$fl) {
					my ($num, $lname) = split (/-/, $fl->{$filter}->{stage});
					if (!$lname) {
						next;
					}
					if ($lname eq $child) {
					if ($num eq $_) {
						#here is our kid
						$begin = $fl->{$_}->{module}->new(
						Handler =>$fl->{$filter}->{chain}, Spec =>$spec);
					}
					}
					delete $fl->{$filter};
					$fl->{$_}->{chain} = $begin; 
				}
			}
		}
	}
	
	#put our new wierd filter list back as the spec's Filter_List
	$spec->{Filter_List} = $fl;
	
	
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

1;


__END__

=head1 Name

Amin::Machine - base module for any Amin Machine

=head1 Description


=head1 Methods 

=over 4

=item *new

this method is actually called by a machine module that ISA 
Amin::Machine. The machine modules does so ie 

    return $self->SUPER::new($spec);
    
=item *parse_string
	
this method is called by Amin::Machines or your Machines 
module. It accepts one argument, $profile. 

	$m->parse_string( $profile );

this method will return the results from the 
machine's run method. See below for the default 
Amin::Machine run method. 	


=item *parse_uri

this method is called by Amin::Machines or your Machines 
module. It accepts one argument, $uri and $type. 

	$m->parse_uri($uri, $type);

$type needs to be set to  	

	my $type = "uri";

this method will return the results from the 
machine's run method. See below for the default 
Amin::Machine run method. 	
	
=item *run

this method is one of the more important methods inside
of the amin codebase. It's job is to take all the different
spec pieces, and run the resulting machine. It does this 
by building a filterlist in reverse. Since a normal sax
chain is built in reverse we do the same and attach the 
next filter in the filterlist as a handler in the chain.
Eventually we get a complete list that looks like


Generator->Machine_Name->Filters_Here->Handler

Filters_Here can also have 

Filters_Here_begin->Filters_Here_middle->Filters_Here_end

as explained in Amin::Machine::Machine_Spec
	
otherwise all this method does is run the appropriate
parse_uri or parse_string methods on the sax generator
and get's the party started. Just use this method or 
rewrite it if you don't like our party music.... :)
   
=back

=cut