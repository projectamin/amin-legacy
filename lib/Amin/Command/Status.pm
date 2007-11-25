package Amin::Command::Status;

use strict;
use Amin::Elt;
use Proc::ProcessTable;

use vars qw(@ISA);

@ISA = qw(Amin::Elt);

my (%attrs, @target);

sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	$self->attrs(%attrs);
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "status")) {
		$self->command($attrs{'{}name'}->{Value});
	}
	$self->element($element);
	$self->SUPER::start_element($element);
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	$data = $self->fix_text($data);
	my $attrs = $self->{"ATTRS"};
	my $element = $self->{"ELEMENT"};

	if (($self->command eq "status") && ($data ne "")) {
		if ($element->{LocalName} eq "param") {
			my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
			foreach (@things) {
				$self->param($_);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;


	if (($element->{LocalName} eq "command") && ($self->command eq "status")) {
		my $xparam = $self->{'PARAM'};
		my $command = $self->{'COMMAND'};
		my @param;
		my $log = $self->{Spec}->{Log};
		my $state;
		
		foreach (@$xparam) {
			push @param, $_;
		}

		my $status = 0;
		my $t = new Proc::ProcessTable;
		my $text = "Status found information on the following processes ";
		my $error;
		foreach my $pat (@pat) {
		foreach my $p (@{$t->table}) {
			if ($p->cmndline =~ /$pat/) {
				if (($p->state eq "sleep") || ($p->state eq "run")) {
					#the process is running add a message
					#increment meter
					$status++;
					$text = $text . "$pat $p->pid is in $p->state mode."; 
				} else {
					$text = $text . "$pat $p->pid is not available,";
					if ($p->state) {
						$text = $text . "$p->state is the current status,";
					}
					$self->{Spec}->{amin_error} = "red";
					$error = 1;
				}
			}
		}
		}
		$text = " total number of processes checked $status.";
		

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to run the cat command. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "Ran the cat command.";
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

Status - reader class filter for the amin status command.

=head1 version

Ainit 1.0 Sept 2005

=head1 DESCRIPTION

  A reader class for the amin status command.

=head1 XML

=over 4

=item Full example

        <amin:command name="status">
                <amin:param>apache</amin:param>
        </amin:command>

=back

=cut


