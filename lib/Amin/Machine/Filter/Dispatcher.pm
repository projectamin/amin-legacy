package Amin::Machine::Filter::Dispatcher;

#Amin Dispatcher
use strict;
use vars qw(@ISA);
use XML::SAX::Base;
use Amin::Machine::Handler::Empty;

@ISA = qw(XML::SAX::Base);

sub start_element {
	my ($self, $element) = @_;
	my $spec = $self->{Spec};
	my %attrs = %{$element->{Attributes}};
	my $log = $self->{Spec}->{Log};
	
	my $fl = $spec->{Filter_List};
	foreach (@ $fl) {
		if ($element->{LocalName} eq $_->{element})  {
		if (($attrs{'{}name'}->{Value} eq $_->{name}) || 
		($element->{LocalName} eq $_->{name})) {
			
			if ($self->{Spec}->{amin_error}) {
				#if there is an error reset handler to Empty
				$self->set_handler( Amin::Machine::Handler::Empty->new(Handler => $spec->{Handler}, Spec => $spec) );
			} else {
				eval "require $_->{module}"; 
				if ($@) {
					$self->{Spec}->{amin_error} = "red";
					my $text = "Dispatcher failed could not load $_->{module}. Reason $@";
					$log->error_message($text);
				} else {
					$self->set_handler( $_->{module}->new(Handler => $spec->{Handler}, Spec => $spec) );
				}
			}	
		}
		}
	}
	$self->SUPER::start_element($element);
}

1;

=head1 Name

Amin::Machine::Filter::Dispatcher - default Machine_Name filter for Amin

=head1 Description

There are no methods for this module. You use this module in your
own Machines as a Machine_Name. ie

 sub new {
    my ($self, $spec) = @_;
    $spec->{Machine_Name} = Amin::Machine::Filter::Dispatcher->new();
    return $self->SUPER::new($spec);
 }

What this filter does is quite simple. It will check against 
the machine_spec's filterlist for each sax start_element processed.
If an element matches the machine_spec's filterlist then the module
is loaded and the sax events are "Dispatched" to the appropriate 
sax filter by reseting XML::SAX::Base's Handler via set_handler. 
Please see that doc for more information.

If the $spec that is being passed around the machine to other 
filters ever has 

 $self->{Spec}->{amin_error}
 
set as anything defined, then dispatcher will instead send the
sax events to Amin::Machine::Handler::Empty instead of to the
next appropriate sax filter in this machine spec's filterlist.

 
=cut





