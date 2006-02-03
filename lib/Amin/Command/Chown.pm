package Amin::Command::Chown;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

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
		if ($element->{LocalName} eq "shell") {
			if ($attrs{'{}name'}->{Value} eq "env") {
			$self->env_vars($data);
			}
			if ($attrs{'{}name'}->{Value} eq "dir") {
				$self->dir($data);
			}
		}
		if ($element->{LocalName} eq "flag") {
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->flag(split(/\s+/, $data));
			}
		}
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->param(split(/\s+/, $data));
			}
			if ($attrs{'{}name'}->{Value} eq "ogroup") {
				$self->ogroup($data);
			
			}
			if ($attrs{'{}name'}->{Value} eq "target") {
				$self->target($data);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {

		my $dir = $self->{'DIR'};
		my $target = $self->{TARGET};
		my $ogroup = $self->{OGROUP};
		my $xflag = $self->{'FLAG'};
		my $xparam = $self->{'PARAM'};
		
		my (%acmd, @param, @flag, $flag);
		
		my $log = $self->{Spec}->{Log};
		
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
					} elsif ($ip eq "dereference") {
						$flag = "--" . $ip;
					} elsif ($ip eq "no-dereference") {
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
						$flag = "--" . $ip;
					} elsif ($ip eq "quiet") {
						$flag = "--" . $ip;
					} elsif ($ip eq "changes") {
						$flag = "--" . $ip;
					} elsif ($ip eq "dereference") {
						$flag = "--" . $ip;
					} elsif ($ip eq "no-dereference") {
						$flag = "--" . $ip;
					} elsif ($ip eq "recursive") {
						$flag = "--" . $ip;
					} elsif ($ip eq "verbose") {
						$flag = "--" . $ip;
					} else {
						$flag = " -" . $ip;
					}
				}
				push @flag, $flag;
			}
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
		if ($ogroup) {
			push @param, $ogroup;
		
		} 
		if ($target) {
			push @param, $target;
		}
		
		foreach my $ip (@$xparam){
			push @param, $ip;
		}
		
		$acmd{'CMD'} = "chown";
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}

		my $cmd = $self->amin_command(\%acmd);

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Chown Failed for $ogroup, on $target. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "Chown was successful for $ogroup on $target.";
		$self->text($text);
		$log->success_message($text);
		if ($cmd->{OUT}) {
			$log->OUT_message($cmd->{OUT});
		#reset this command
		$self->{DIR} = undef;
		$self->{TARGET} = undef;
		$self->{OGROUP} = undef;
		$self->{FLAG} = [];
		$self->{PARAM} = [];
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{ELEMENT} = undef;
		}
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub target {
	my $self = shift;
	$self->{TARGET} = shift if @_;
	return $self->{TARGET};
}

sub ogroup {
	my $self = shift;
	$self->{OGROUP} = shift if @_;
	return $self->{OGROUP};
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
				#check for stuff like -m=0755 crap
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
					$param{"name"} = "og";
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

Chown - reader class filter for the chown command.

=head1 version

chown (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the chown command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="chown">
                <amin:flag>c</amin:flag>
                <amin:param name="ogroup">bin.bin</amin:param>
                <amin:param name="target">/tmp/amin-tests/limits</amin:param>
        </amin:command>
 </amin:profile>

	
=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="chown">
                <amin:flag>c</amin:flag>
                <amin:param name="ogroup">bin.bin</amin:param>
                <amin:param name="target">/tmp/amin-tests/limits</amin:param>
        </amin:command>
        <amin:command name="chown">
                <amin:flag>c</amin:flag>
                <amin:param name="ogroup">bin.bin</amin:param>
                <amin:param name="target">/tmp/amin-tests2/limits</amin:param>
        </amin:command>
 </amin:profile>

=back  

=cut

