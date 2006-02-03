package Amin::Command::Mknod;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

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

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	$data = $self->fix_text($data);
	my $attrs = $self->{"ATTRS"};
	my $element = $self->{"ELEMENT"};

	if ($data ne "") {
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "type") {
				$self->type($data);
			}
			if ($attrs{'{}name'}->{Value} eq "major") {
				$self->major($data);
			}
			if ($attrs{'{}name'}->{Value} eq "minor") {
				$self->minor($data);
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
			if ($attrs{'{}name'}->{Value} eq "mode") {
				$self->mode($data);
			}
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->flag(split(/\s+/, $data));
			}
		}
	}
	#if ($element->{LocalName} eq "param") {
	#	if ($attrs{'{}name'}->{Value} eq "") {
	#		if ($data ne "") {
	#			my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
	#			foreach (@things) {
	#				$self->param($_);
	#			}
	#		}
	#	}
	#}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {
		my $mode = $self->{'MODE'};
		my $dir = $self->{'DIR'};
		my $target = $self->{'TARGET'};
		my $xflag = $self->{'FLAG'};
		my $command = $self->{'COMMAND'};
		my $type = $self->{'TYPE'};
		my $major = $self->{'MAJOR'};
		my $minor = $self->{'MINOR'};

		my $log = $self->{Spec}->{Log};
		my ($flag, @flag, @target);

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
					} else {
						$flag = "-" . $ip;
					}
					$state = 1;
				} else {
					if ($ip eq "help") {
						$flag = " --" . $ip;
					} elsif ($ip eq "version") {
						$flag = " --" . $ip;
					} else {
						$flag = " -" . $ip;
					}
				}
				push @flag, $flag;
			}
		}
		if ($mode) {
			$flag = "-m " . $mode;
			push @flag, $flag;
		}

		my $stuff = $type . " " . $major . " " . $minor . " ";
		push @target, $stuff;
		
		foreach (@$target) {
			push @target, $_;
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
			my $text = "Unable to run the mknod command. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$self->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "Mknod was successful";
		$self->text($text);

		$log->success_message($text);
		if ($cmd->{OUT}) {
			$log->OUT_message($cmd->{OUT});
		}
		#reset this command
		
		$self->{DIR} = undef;
		$self->{FLAG} = [];
		$self->{TARGET} = [];
		$self->{PARAM} = [];
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{ELEMENT} = undef;
		$self->{MODE} = undef;
		$self->{TYPE} = undef;
		$self->{MAJOR} = undef;
		$self->{MINOR} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub mode {
	my $self = shift;
	$self->{MODE} = shift if @_;
	return $self->{MODE};
}
sub type {
	my $self = shift;
	$self->{TYPE} = shift if @_;
	return $self->{TYPE};
}
sub major {
	my $self = shift;
	$self->{MAJOR} = shift if @_;
	return $self->{MAJOR};
}
sub minor {
	my $self = shift;
	$self->{MINOR} = shift if @_;
	return $self->{MINOR};
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
		if (($_ =~ /^-.*$/) || ($_ =~ /^--.*$/) || ($scratch{name})) {
			#it is a flag
			my %flag;
			my $char;
			$_ =~ s/-//;
			$_ =~ s/--//;
			if ($scratch{name}) {
				#this completes the -m 0755 crap
				if ($_ =~ /\d+/) {
					$char = $_;
				} else {
					#this is a param and their -m is not
					#a digit why they want this is unknown
					#:)
					my %param;
					$param{"char"} = $_;
					push @params, \%param;
				}
				$_ = $scratch{name};
				#undefine stuff
				$stop = undef;
				%scratch = {};
			} else {
				if ($_ =~ /^.*=.*$/) {
					#check for stuff like -m=0755 crap
					($_, $char) = split (/=/, $_);
				} elsif ($_ eq "m") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} else  {
					#its just a flag
					$char = $_;
					$_ = undef;
				}
			}
			
			if (!$stop) {
				if ($_) {
					$flag{"name"} = $_;
				}
			
				$flag{"char"} = $char;
				push @flags, \%flag;
			}
		
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

Mknod - reader class filter for the mknod command.

=head1 version

Mknod (coreutils) March 2003

=head1 DESCRIPTION

  A reader class for the mknod command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="mknod">
                <amin:param name="target">null</amin:param>
                <amin:param name="type">c</amin:param>
                <amin:param name="major">1</amin:param>
                <amin:param name="minor">3</amin:param>
                <amin:flag name="mode">0755</amin:flag>
                <amin:shell name="dir">/dev/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="mknod">
                <amin:param name="target">null</amin:param>
                <amin:param name="type">c</amin:param>
                <amin:param name="major">1</amin:param>
                <amin:param name="minor">3</amin:param>
                <amin:flag name="mode">0755</amin:flag>
                <amin:shell name="dir">/dev/</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut