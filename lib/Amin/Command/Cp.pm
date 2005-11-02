package Amin::Command::Cp;

use strict;
use vars qw(@ISA);
use Amin::Command::Copy;

@ISA = qw(Amin::Command::Copy);

sub version {
	return "1.0";
}

1;

=head1 NAME

Cp - reader class filter for the copy(cp) command.

=head1 version

cp (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the copy(cp) command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="cp">
                <amin:param name="source">touchfile</amin:param>
                <amin:param name="target">my_new_dir</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
	<amin:command name="cp">
		<amin:param name="source">touchfile</amin:param>
		<amin:param name="target">my_new_dir</amin:param>
		<amin:shell name="dir">/tmp/amin-tests/</amin:shell>
	</amin:command>
	<amin:command name="cp">
		<amin:param name="source">touchfile</amin:param>
		<amin:param name="target">my_new_dir</amin:param>
		<amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
	</amin:command>
 </amin:profile>

=back  

=cut