package Amin::Chroot;

#amin Chroot
use strict;
use vars qw(@ISA);
use XML::SAX::Base;
use File::Glob;

@ISA = qw(XML::SAX::Base);

my $pid;
my $chroot;

sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};
	my $dir = $attrs{'{}dir'}->{Value};
	my $log = $self->{Spec}->{Log};
	if ($element->{LocalName} eq "chroot") {
		$pid = fork;
		if ( ! chroot $dir ) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Could not chroot to $dir";
			$log->error_message($text);
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
  shell equivalent of chroot, just in perl.
  
=head1 XML

=over 4

=item Full example

 <amin:chroot dir="/mnt/chroot">
        <amin:command name="mkdir">
                <amin:param>/tmp/inside_chroot</amin:param>
        </amin:command>
 </amin:chroot>

=back  

=cut
