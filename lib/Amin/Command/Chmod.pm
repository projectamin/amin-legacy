package Amin::Command::Chmod;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use warnings;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);
my %attrs;

sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	if (!$attrs{'{}name'}->{'Value'}) {
		$attrs{'{}name'}->{'Value'} = "";
	}
	$self->attrs(%attrs);
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "chmod")) {
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
	my $command = $self->command;
	if (($command eq "chmod") && ($data ne "")) {
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

	if (($element->{LocalName} eq "command") && ($self->command eq "chmod")) {

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
			if (!$ip) {next;};
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

		my $default = "0"; #setup the default msg flag
		unless ($set) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "No permission to set for chmod";
			$default = 1;
			$log->error_message($text);
		}
		push @flag, $set;
		foreach (@$targets) {
			push @target, glob($_);
		}
		if ($dir) {
			if (! chdir $dir) {
				$self->{Spec}->{amin_error} = "red";
				my $text = "Unable to change directory to $dir. Reason: $!";
				$default = 1;
				$log->error_message($text);
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

		if ($cmd->{TYPE} eq "error") {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to set permissions for " . join (", ", @target) . "to $set. Reason: $cmd->{ERR}";
			$self->text($text);

			$default = 1;
			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
		}
		if (($cmd->{TYPE} eq "out") || ($cmd->{TYPE} eq "both")) {
			my $otext;
			if ($dir) {
				$otext = "Changing permissions to $set in $dir for " . join (", ", @target);
			} else {
				$otext = "Changing permissions to $set for " . join (", ", @target);
			}
			my $etext = " There was also some error text $cmd->{ERR}";
			$etext = $otext . $etext; 
			$default = 1;
			if ($cmd->{TYPE} eq "out") {
				$log->success_message($otext);
				$log->OUT_message($cmd->{OUT});
			} else {
				$log->success_message($etext);
				$log->OUT_message($cmd->{OUT});
				$log->ERR_message($cmd->{ERR});
				
			}
		}
		if ($default == 0) {
			my $text = "there was no messages?";
			$log->error_message($text);
		}
		#reset this command
		$self->{DIR} = undef;
		$self->{FLAG} = [];
		$self->{REFERNCE} = undef;
		$self->{SET} = undef;
		$self->{TARGET} = [];
		$self->{PARAM} = [];
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{ELEMENT} = undef;
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

sub version {
	return "1.0";
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

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="chmod">
                <amin:param name="target">/tmp/amin-tests/limits</amin:param>
                <amin:param name="set">0750</amin:param>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="chmod">
                <amin:param name="target">/tmp/amin-tests/limits</amin:param>
                <amin:param name="set">0750</amin:param>
        </amin:command>
        <amin:command name="chmod">
                <amin:param name="target">/tmp/amin-tests2/limits</amin:param>
                <amin:param name="set">0750</amin:param>
        </amin:command>
 </amin:profile>

=back  

=cut
