package Amin::Command::Chmod;

use strict;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);
my %attrs;

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

	if ($attrs{'{}name'}->{Value} eq "set") {
		if ($data ne "") {
			$self->set($data);
		}
	}
	if ($attrs{'{}name'}->{Value} eq "dir") {
		if ($data ne "") {
			$self->dir($data);
		}
	}
	if ($attrs{'{}name'}->{Value} eq "env") {
		if ($data ne "") {
			$self->env_vars($data);
		}
	}
	if ($attrs{'{}name'}->{Value} eq "target") {
		if ($data ne "") {
			my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
			foreach (@things) {
				$self->target($_);
			}
		}
	}
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

		my $set = $self->{'SET'};
		my $dir = $self->{'DIR'};
		my $targets = $self->{'TARGET'};
		my $xflag = $self->{'FLAG'};
		my $command = $self->{'COMMAND'};
		my @target;
		my $log = $self->{Spec}->{Log};

		my ($flag, @flag);

		foreach my $ip (@$xflag){
			if (($ip =~ /^-/) || ($ip =~ /^--/)) {
				push @flag, $ip;
			} else {	
				$flag = "-" . $ip;
				push @flag, $flag;
			}
		}

		unless ($set) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "No permission to set for chmod";
			$self->text($text);

			$log->error_message($text);
			$self->SUPER::end_element($element);
			return;
		}

		push @flag, $set;


		foreach (@$targets) {
			push @target, glob($_);
		}

		if (! chdir $dir) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to change directory to $dir. Reason: $!";
			$self->text($text);

			$log->error_message($text);
			$self->SUPER::end_element($element);
			return;
		}

		my %acmd;
		$acmd{'CMD'} = $command;
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@target;

		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}
		my $cmd = $self->amin_command(\%acmd);

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to set permissions for " . join (", ", @target) . "to $set. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "Changing permissions to $set in $dir for " . join (", ", @target);
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

sub set {
	my $self = shift;
	$self->{SET} = shift if @_;
	return $self->{SET};
}


1;

=head1 NAME

chmod - reader class filter for the chmod command.

=head1 version

chmod (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the chmod command. 
  
=head1 XML

=over 4

=item Full example

        <amin:command name="chmod">
                <amin:param name="target">/tmp/limits</amin:param>
                <amin:flag name="set">0750</amin:flag>
        </amin:command>

=back  

=cut