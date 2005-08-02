package Amin::Command::Hostname;

use strict;
use vars qw(@ISA);
use Amin::Command::Elt;
use Amin::Dispatcher;

@ISA = qw(Amin::Command::Elt Amin::Dispatcher);

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

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	$data = $self->fix_text($data);
	my $attrs = $self->{"ATTRS"};
	my $element = $self->{"ELEMENT"};

	if ($element->{LocalName} eq "flag") {
		if ($attrs{'{}name'}->{Value} eq "") {
			if ($data ne "") {
				$self->flag(split(/\s+/, $data));
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {
		my $xflag = $self->{'FLAG'};
		my $command = $self->{'COMMAND'};
		my ($flag, @flag, @target);
		my $log = $self->{Spec}->{Log};

		my $state;
		foreach my $ip (@$xflag){
			if ($state == 0) {
				$flag = "--" . $ip;
				$state = 1;
			} else {
				$flag = " --" . $ip;
			}
			push @flag, $flag;
		}

		my %acmd;
		$acmd{'CMD'} = $command;
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@target;
		
		my $cmd = $self->amin_command(\%acmd);

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to run hostname. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "Hostname is $cmd->{OUT}";
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

1;

=head1 NAME

Hostname - reader class filter for the hostname command.

=head1 version

hostname (coreutils) 

=head1 DESCRIPTION

  A reader class for the hostname command. 
  
=head1 XML

=over 4

=item Full example

        <amin:command name="hostname"/>

=back  

=cut

