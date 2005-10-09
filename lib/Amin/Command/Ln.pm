package Amin::Command::Ln;

use strict;
use vars qw(@ISA);
use Amin::Command::Link;

@ISA = qw(Amin::Command::Link);

sub version {
	return "1.0";
}

1;

=head1 NAME

Link - reader class filter for the gnu ln/Link command.

=head1 version
	
ln (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the ln command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="ln">
                <amin:param name="source">original_thing</amin:param>
                <amin:param name="target">linked_thing</amin:param>
                <amin:flag>sf</amin:flag>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut

