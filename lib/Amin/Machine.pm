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
module. It accepts one argument $uri. 

	$m->parse_uri($uri, $type);

this method will return the results from the 
machine's run method. See below for the default 
Amin::Machine run method. 	
	
=item *run

this method takes the $spec prepared by the machine type's
spec machine filter and loads it into an amin machine. 
This is the main routine that runs any amin machine type. 

=back

=cut