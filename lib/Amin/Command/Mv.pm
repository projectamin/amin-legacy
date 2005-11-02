package Amin::Command::Mv;

use strict;
use vars qw(@ISA);
use Amin::Command::Move;

@ISA = qw(Amin::Command::Move);

sub version {
	return "1.0";
}

1;

=head1 NAME

Mv - reader class filter for the move(mv) command.

=head1 version


=head1 DESCRIPTION

  A reader class for the move(mv) command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="mv">
                <amin:param name="source">limit-new</amin:param>
                <amin:param name="target">limits</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="mv">
                <amin:param name="source">limit-new</amin:param>
                <amin:param name="target">limits</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
        <amin:command name="mv">
                <amin:param name="source">limit-new</amin:param>
                <amin:param name="target">limits</amin:param>
                <amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut
