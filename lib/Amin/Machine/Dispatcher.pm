package Amin::Machine::Dispatcher;

#Amin Dispatcher Machine

use strict;
use vars qw(@ISA);
use Amin::Machine;
use Amin::Machine::Filter::Dispatcher;

@ISA = qw(Amin::Machine);

sub new {
    my ($self, $spec) = @_;
    $spec->{Machine_Name} = Amin::Machine::Filter::Dispatcher->new();
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
to build our amin machine.

=cut