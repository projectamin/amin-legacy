package Amin::Command::Grpunconv;

use strict;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);

my (%attrs, @target);

sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	$self->attrs(%attrs);
	if ($element->{LocalName} eq "command") {
		$self->command($attrs{'{}name'}->{Value});
	}
	$self->element($element);
	$self->SUPER::start_element($element);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {
		my $command = $self->{'COMMAND'};

		my %acmd;
		$acmd{'CMD'} = $command;
		my $log = $self->{Spec}->{Log};

		my $cmd = $self->amin_command(\%acmd);

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Grpunconv failed. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "Grpunconv succeeded";
		$self->text($text);

		$log->success_message($text);
		if ($cmd->{OUT}) {
			$log->OUT_message($cmd->{OUT});
		}
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub version {
	return "1.0";
}

1;

=head1 NAME

Grpunconv - reader class filter for the grpunconv command.

=head1 version

Grpconv 26 Sep 1997

=head1 DESCRIPTION

  A reader class for the grpunconv command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="grpunconv" />
 </amin:profile>

=back  

=cut