package Amin::Command::Rm;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use warnings;
use vars qw(@ISA);
use Amin::Command::Remove;

@ISA = qw(Amin::Command::Remove);

sub version {
	return "1.0";
}

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

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="remove">
                <amin:param name="target">pass my_new_dir/touchfile<</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="rm">
                <amin:param name="target">pass my_new_dir/touchfile</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
        <amin:command name="rm">
                <amin:param name="target">pass my_new_dir/touchfile</amin:param>
                <amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut
