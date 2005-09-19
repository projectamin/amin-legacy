package Amin::Machine;

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
	my ($lfl, $flf, $last);
	
	#deal with the filter_list
	my $fl = $spec->{Filter_List};
	my $prev;
	my $first;
	my $machine_name;
	my $handler;
	my $next;
	
	foreach (@$fl) {	
		if (!$next) {
			$next = $_->{module}->new(Handler => $spec->{Handler}, Spec => $spec);
		} else {
			$next = $_->{module}->new(Handler => $next);
		}
	}
					
	$machine_name = $spec->{Machine_Name}->new(Handler => $next);

		
	$spec->{Machine_Handler} = $machine_name;	
	#	if ($_ eq $reverse[-1]) {
			
			#this is the first module of the sax chain
	#		if ($_ eq $reverse[0]) {
				#this is also the last module of the sax chain
	#			$next = $_->{module}->new(Handler => $spec->{Handler}, Spec => $spec);
	#		} else {
	#			$next = $_->{module}->new(Handler => $next, Spec => $spec);
	#		}
			
	#	} elsif ($_ eq $reverse[0]) {
			#this is the last module of the sax chain
	#	} else {
	#		$next = $_->{module}->new(Handler => $next, Spec => $spec);
	#	}
	#}
	
	
	my $p = $spec->{Generator}->new(Handler => $machine_name, Spec => $spec);
	
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
and get's the party started.
   
=back

=cut