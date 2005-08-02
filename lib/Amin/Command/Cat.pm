package Amin::Command::Cat;

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

	if ($element->{LocalName} eq "param") {
		if ($data ne "") {
			my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
			foreach (@things) {
				$self->param($_);
			}
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
		my $dir = $self->{'DIR'};
		my $xparam = $self->{'PARAM'};
		my $xflag = $self->{'FLAG'};
		my $command = $self->{'COMMAND'};
		my ($flag, @flag, @param);

		my $log = $self->{Spec}->{Log};
		my $state;
		foreach my $ip (@$xflag){
			if (($ip =~ /-/) || ($ip =~ /--/)) {
				push @flag, $flag;
			} else {	
				if (($ip eq "show-all") || ($ip eq "help") || ($ip eq "number-nonblank") 
				|| ($ip eq "verbose") || ($ip eq "show-ends")  || ($ip eq "number") 
				 || ($ip eq "squeeze-blank")  || ($ip eq "show-tabs")  || ($ip eq "show-nonprinting"))  {
					$flag = " --" . $ip;
					push @flag, $flag;
				} else {
					if ($state == 0) {
						$flag = "-" . $ip;
						$state = 1;
					} else {
						$flag = " -" . $ip;
					}
					push @flag, $flag;
				}
			}
		}
		
		foreach (@$xparam) {
			push @param, $_;
		}

		if ($dir) {
			if (! chdir $dir) {
				$self->{Spec}->{amin_error} = "red";
				my $text = "Unable to change directory to $dir. Reason: $!";
				$self->text($text);

				$log->error_message($text);
				$self->SUPER::end_element($element);
				return;
			}
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

1;


=head1 NAME

Cat - reader class filter for the cat command.

=head1 version

cat (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the cat command. 
  
=head1 XML

=over 4

=item Full example

        <amin:command name="cat">
                <amin:flag>A</amin:flag>
                <amin:param>/tmp/hg</amin:param>
        </amin:command>

=back  

=cut



