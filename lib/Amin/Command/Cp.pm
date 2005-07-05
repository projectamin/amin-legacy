package Amin::Command::Cp;

use strict;
use vars qw(@ISA);
use Amin::Command::Copy;

@ISA = qw(Amin::Command::Copy);

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

       <amin:command name="cp">
                <amin:param name="source">some_file</amin:param>
                <amin:param name="target">/this/dir/</amin:param>
                <amin:shell name="dir">/tmp/</amin:shell>
        </amin:command>

=back  

=cut