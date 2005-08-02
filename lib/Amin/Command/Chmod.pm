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

	if ($data ne "") {
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "set") {
				$self->set($data);
			}
			if ($attrs{'{}name'}->{Value} eq "target") {
				my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
				foreach (@things) {
					$self->target($_);
				}
			}
		}
		if ($element->{LocalName} eq "shell") {
			if ($attrs{'{}name'}->{Value} eq "dir") {
				$self->dir($data);
			}
			if ($attrs{'{}name'}->{Value} eq "env") {
				$self->env_vars($data);
			}
		}
		if ($element->{LocalName} eq "flag") {
			if ($attrs{'{}name'}->{Value} eq "reference") {
				$self->reference($data);
			}
			if ($attrs{'{}name'}->{Value} eq "") {
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
		my $reference = $self->{'REFERENCE'};
		my @target;
		my $log = $self->{Spec}->{Log};

		my ($flag, @flag);

		my $state;
		foreach my $ip (@$xflag){
			if (($ip =~ /^-/) || ($ip =~ /^--/)) {
				push @flag, $ip;
			} else {	
				if ($state == 0) {
					if ($ip eq "help") {
						$flag = "--" . $ip;
					} elsif ($ip eq "version") {
						$flag = "--" . $ip;
					} elsif ($ip eq "silent") {
						$flag = "--" . $ip;
					} elsif ($ip eq "quiet") {
						$flag = "--" . $ip;
					} elsif ($ip eq "changes") {
						$flag = "--" . $ip;
					} elsif ($ip eq "recursive") {
						$flag = "--" . $ip;
					} elsif ($ip eq "verbose") {
						$flag = "--" . $ip;
					} else {
						$flag = "-" . $ip;
					}
					$state = 1;
				} else {
					if ($ip eq "help") {
						$flag = " --" . $ip;
					} elsif ($ip eq "version") {
						$flag = " --" . $ip;
					} elsif ($ip eq "silent") {
						$flag = " --" . $ip;
					} elsif ($ip eq "quiet") {
						$flag = " --" . $ip;
					} elsif ($ip eq "changes") {
						$flag = " --" . $ip;
					} elsif ($ip eq "recursive") {
						$flag = " --" . $ip;
					} elsif ($ip eq "verbose") {
						$flag = " --" . $ip;
					} else {
						$flag = " -" . $ip;
					}
				}
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

sub reference {
	my $self = shift;
	$self->{REFERENCE} = shift if @_;
	return $self->{REFERENCE};
}

sub filter_map {
	my $self = shift;
	my $command = shift;
	my %command;
	my @flags;
	my @params;
	my @shells;
	my @things = split(/([\*\+\.\w=\/-]+|'[^']+')\s*/, $command);

	my %scratch;
	my $stop;
	foreach (@things) {
	#check for real stuff
	if ($_) {
		my $x = 1; 
		#check for flag
		if (($_ =~ /^-.*$/) || ($_ =~ /^--.*$/)) {
			#it is a flag
			my %flag;
			my $char;
			$_ =~ s/-//;
			$_ =~ s/--//;
			if ($_ =~ /^.*=.*$/) {
				#check for stuff like -r=/some/file
				($_, $char) = split (/=/, $_);
			} else  {
				#its just a flag
				$char = $_;
				$_ = undef;
			}
			
			if ($_) {
				$flag{"name"} = $_;
			}
			$flag{"char"} = $char;
			push @flags, \%flag;
		} elsif ($_ =~ /^.*=.*$/) {
			my %shell;
			#it is an env variable 
			$shell{"name"} = 'env';
			$shell{"char"} = $_;
			push @shells, \%shell;
		} else {
			#it is either a param, command name
			if (!$command{name}) {
				$command{name} = $_;
			} else {
				my %param;
				$param{"char"} = $_;
				if ($x == 1) {
					$param{"name"} = "group";
				} elsif ($x == 2) {
					$param{"name"} = "target";
				}
				$x++;
				push @params, \%param;
			}
		}
	}
	}
	
	
	if (@shells) {
		$command{shell} = \@shells;
	}
	if (@flags) {
		$command{flag} = \@flags;
	}
	if (@params) {
		$command{param} = \@params;
	}
	
	my %fcommand;
	$fcommand{command} = \%command;
	return \%fcommand;	
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