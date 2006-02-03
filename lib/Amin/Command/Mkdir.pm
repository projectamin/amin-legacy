package Amin::Command::Mkdir;

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
			my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
			foreach (@things) {
				#target and param are same thing
				if ($attrs{'{}name'}->{Value} eq "target") {
					$self->target($_);
				} else {
					$self->param($_);
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
			if (($attrs{'{}name'}->{Value} eq "mode") || 
			($attrs{'{}name'}->{Value} eq "m")) {
				$self->mode($data);
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
		my $mode = $self->{'MODE'};
		my $dir = $self->{'DIR'};
		my $target = $self->{'TARGET'};
		my $xflag = $self->{'FLAG'};
		my $xparam = $self->{'PARAM'};
		my $command = $self->{'COMMAND'};
		my ($flag, @flag, @target);

		
		my $log = $self->{Spec}->{Log};
		
		my $state;
		foreach my $ip (@$xflag){
			if (($ip =~ /-/) || ($ip =~ /--/)) {
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
		if ($mode) {
			$flag = "-m " . $mode;
			push @flag, $flag;
		}

		foreach (@$target) {
			push @target, $_;
		}
		foreach my $ip (@$xparam){
			push @target, $ip;
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
			my $text = "Unable to create directory. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "Making directories in $dir (perm: =";
		$text .= "$mode" || "default";
	        $text .= "):";
	        $text .= join (", ", @target);
		$self->text($text);

		$log->success_message($text);
		if ($cmd->{OUT}) {
			$log->OUT_message($cmd->{OUT});
		}
		
		#reset this command
		
		$self->{MODE} = undef;
		$self->{DIR} = undef;
		$self->{TARGET} = [];
		$self->{FLAG} = [];
		$self->{PARAM} = [];
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{NAME} = undef;
		$self->{ELEMENT} = undef;
		
		
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
					#this is a param and their -m is 0000
					#why they want this is unknown :)
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

Mkdir - reader class filter for the mkdir command.

=head1 version

mkdir (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the mkdir command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="mkdir">
                <amin:param name="target">/tmp/amin-tests/my_new_dir</amin:param>
                <amin:flag>p</amin:flag>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="mkdir">
                <amin:param name="target">/tmp/amin-tests/my_new_dir</amin:param>
                <amin:flag>p</amin:flag>
        </amin:command>
        <amin:command name="mkdir">
                <amin:param name="target">/tmp/amin-tests2/my_new_dir</amin:param>
                <amin:flag>p</amin:flag>
        </amin:command>
 </amin:profile>

=back  

=cut
