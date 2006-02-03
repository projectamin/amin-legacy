package Amin::Chroot;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

#amin Chroot
use strict;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);

my $pid = 1;
my $state = 0;

sub version {
	return "1.0";
}

sub start_element {
        my ($self, $element) = @_;
        my %attrs = %{$element->{Attributes}};
        my $dir = $attrs{'{}dir'}->{Value};
        if ($element->{LocalName} eq "profile") {
		$self->SUPER::start_element($element);
	}
	if ($element->{LocalName} eq "chroot") {
                $pid = fork;
                if ( ! chroot $dir ) {
                        print "Could not chroot to $dir";
                }
        }
        if ($pid == 0) {
		$self->SUPER::start_element($element);
        }
        wait;
}

sub characters {
        my ($self, $chars) = @_;
        if ($pid == 0) {
                $self->SUPER::characters($chars);
        }
        wait;
}

sub end_element {
        my ($self, $element) = @_;
	my $chroot;

        if ($element->{LocalName} eq "chroot") {
                #get out of chroot
                $chroot = 1;
        }
        if ($element->{LocalName} eq "profile") {
                if ($chroot == 1) {
                        $self->SUPER::end_element($element);
                        exit;
                }
        }
        if ($pid == 0) {
                $self->SUPER::end_element($element);
        }
        wait;
}
1;

=head1 NAME

Chroot - reader class filter for the chroot command.

=head1 version

Chroot - perl version

=head1 DESCRIPTION

  A reader class for the chroot command. This is the
  shell equivalent of chroot, just in perl. This only 
  works as described in the full example below. If you
  want to fix and or improve this problem, please do so...
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin="http://projectamin.org/ns/amin">
 	<!-- chroot must be first and last child of profile, so 
	     everything in this profile is in chroot -->
	     
 	<amin:chroot dir="/mnt/chroot">
        	<amin:command name="mkdir">
        	        <amin:param>/tmp/inside_chroot</amin:param>
        	</amin:command>
 	</amin:chroot>
 </amin:profile>
=back  

=cut