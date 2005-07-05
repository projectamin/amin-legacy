package Amin::Command::Rm;

use strict;
use vars qw(@ISA);
use Amin::Command::Remove;

@ISA = qw(Amin::Command::Remove);

1;

=head1 NAME

Rm - reader class filter for the remove(rm) command.

=head1 version

rm (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the remove(rm) command. 
  
=head1 XML

=over 4

=item Full example

        <amin:command name="remove">
                <amin:param name="target">limits</amin:param>
                <amin:shell name="dir">/tmp</amin:shell>
        </amin:command>

=back  

=cut
