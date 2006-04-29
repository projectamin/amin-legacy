package Amin::Machine::Filter::Dispatcher;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

#Amin Dispatcher
use strict;
use vars qw(@ISA);
use Amin::Machine::Handler::Empty;
use Amin::Elt;

@ISA = qw(Amin::Elt);

sub start_element {
	my ($self, $element) = @_;
	my $spec = $self->{Spec};
	my %attrs = %{$element->{Attributes}};
	my $log = $self->{Spec}->{Log};
	if (!$attrs{'{}name'}->{'Value'}) {
		$attrs{'{}name'}->{'Value'} = "";
	}
	
	my $fl = $spec->{Filter_List};
	foreach (keys %$fl) {
		if ($element->{LocalName} eq $fl->{$_}->{element})  {
		if (($attrs{'{}name'}->{Value} eq $fl->{$_}->{name}) || 
		($element->{LocalName} eq $fl->{$_}->{name})) {
		if ($fl->{$_}->{namespace} eq $element->{Prefix}) {
			if ($self->{Spec}->{amin_error}) {
				#if there is an error reset handler to Empty
				$self->set_handler( Amin::Machine::Handler::Empty->new(Handler => $spec->{Handler}, Spec => $spec) );
			} else {
				#this is one of those special begin chains....
				if (($fl->{$_}->{'name'} eq $element->{'LocalName'} ) && ($attrs{'{}name'}->{'Value'})) {
					if ($fl->{$_}->{attr} ne $attrs{'{}name'}->{'Value'}) {
						next;
					}
				}	
				
				my $module = $fl->{$_}->{module};
				eval "require $module"; 
				
				if ($@) {
					$self->{Spec}->{amin_error} = "red";
					my $text = "Dispatcher failed could not load $_->{module}. Reason $@";
					$log->error_message($text);
				} else {
					my $schain = $fl->{$_}->{chain};
					$self->set_handler($schain);
				}
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
