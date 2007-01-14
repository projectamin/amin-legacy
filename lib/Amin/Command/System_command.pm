package Amin::Command::System_command;

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
	if (!$attrs{'{}name'}->{'Value'}) {
		$attrs{'{}name'}->{'Value'} = "";
	}
	$self->attrs(%attrs);
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "system_command")) {
		$self->command($attrs{'{}name'}->{Value});
	}
	$self->element($element);
	$self->SUPER::start_element($element);
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	$data = $self->fix_text($data);
	my $attrs = $self->attrs;
	my $element = $self->{"ELEMENT"};
	my $command = $self->command;
	if (!$command) {
		$command = "";
	}
	if (($command eq "system_command") && ($data ne "")) {
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "basename") {
				$self->basename($data);
			}
			if ($attrs{'{}name'}->{Value} eq "") {
				my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
				foreach (@things) {
					$self->param($_);
				}
			}
		}
		if ($element->{LocalName} eq "special") {
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->special($data);
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
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->flag(split(/\s+/, $data));
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if (($element->{LocalName} eq "command") && ($self->command eq "system_command")) {
		#reset the command
		#$self->command("");
		my $basename = $self->{'BASENAME'};
		my $dir = $self->{'DIR'};
		my $xparam = $self->{'PARAM'};
		my $xflag = $self->{'FLAG'};
		my ($flag, @flag, $param, @param);
		my $special = $self->{'SPECIAL'};
		my $log = $self->{Spec}->{Log};

		foreach my $ip (@$xflag){
			if (!$ip) {next;};
			if (($ip =~ /^-/) || ($ip =~ /^--/)) {
				push @flag, $ip;
			} else {	
				$flag = "-" . $ip;
				push @flag, $flag;
			}
		}

		foreach my $ip (@$xparam){
			push @param, $ip;
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

		my (%acmd, %bcmd, $cmd);
		if ($special) {
			my $special2 = "shell";
			$cmd = $self->amin_command($special, $special2);
		} else {
			if (!$basename) {
				$self->{Spec}->{amin_error} = "red";
				my $text = "There must be a basename!";
				$self->text($text);

				$log->error_message($text);
				$self->SUPER::end_element($element);
				return;
			}
			$acmd{'CMD'} = $basename;
			$acmd{'FLAG'} = \@flag;
			$acmd{'PARAM'} = \@param;
			if ($self->{'ENV_VARS'}) {
				$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
			}
			$cmd = $self->amin_command(\%acmd);
		}
		
		
		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text;
			if ($dir) {
				$text = "Unable to execute $basename in $dir. Reason: $cmd->{ERR}";
			} else {
				$text = "Unable to execute $basename. Reason: $cmd->{ERR}";
			}
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text;
		if ($dir) {
			$text = "Executing $basename in $dir";
		} else {
			$text = "Executing $basename";
		}
		$self->text($text);
		$log->success_message($text);
		if ($cmd->{OUT}) {
			$log->OUT_message($cmd->{OUT});
		}
		#reset this command
		
		$self->{DIR} = undef;
		$self->{FLAG} = [];
		$self->{PARAM} = [];
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{ELEMENT} = undef;
		$self->{BASENAME} = undef;
		$self->{SPECIAL} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub basename {
	my $self = shift;
	$self->{BASENAME} = shift if @_;
	return $self->{BASENAME};
}

sub special {
	my $self = shift;
	$self->{SPECIAL} = shift if @_;
	return $self->{SPECIAL};
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

System_command - reader class filter for the system_command command.

=head1 version

amin 0.5.0

=head1 DESCRIPTION

  A reader class for the system_command command. System_command
  is a generic catch all for when you need a command with no
  filters available for said command. System_command also has 
  the <amin:special> child element. This element will pass thru
  any command you supply as char data to a "sh" shell. Use only
  in dire cases... :)
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="system_command">
                <amin:param name="basename">touch</amin:param>
                <amin:param>/tmp/amin-tests/limits</amin:param>
        </amin:command>
	
	
	<!-- sample special command

       <amin:command name="system_command">
                <amin:special>straight -pass /thru/of/a/command</amin:special>
        </amin:command>
 	-->
 
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="system_command">
                <amin:param name="basename">touch</amin:param>
                <amin:param>/tmp/amin-tests/limits</amin:param>
        </amin:command>
       <amin:command name="system_command">
                <amin:param name="basename">touch</amin:param>
                <amin:param>/tmp/amin-tests2/limits</amin:param>
        </amin:command>
 </amin:profile>
	
=back  

=cut
