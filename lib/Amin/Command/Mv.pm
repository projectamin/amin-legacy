package Amin::Command::Mv;

use strict;
use vars qw(@ISA);
use Amin::Command::Move;

@ISA = qw(Amin::Command::Move);

1;

=head1 NAME

Mv - reader class filter for the move(mv) command.

=head1 version


=head1 DESCRIPTION

  A reader class for the move(mv) command. 
  
=head1 XML

=over 4

=item Full example

        <amin:command name="mv">
                <amin:param name="source">limits</amin:param>
                <amin:param name="target">limit-new</amin:param>
                <amin:shell name="dir">/tmp/</amin:shell>
        </amin:command>

=back  

=cut
