package Amin::Command::Ls;

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
			if ($attrs{'{}name'}->{Value} eq "I") {
				$self->ignore($data);
			}
			if ($attrs{'{}name'}->{Value} eq "k") {
				$self->block_size($data);
			}
			if ($attrs{'{}name'}->{Value} eq "T") {
				$self->tab($data);
			}
			if ($attrs{'{}name'}->{Value} eq "w") {
				$self->width($data);
			}
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->flag(split(/\s+/, $data));
			}
		}
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->param(split(/\s+/, $data));
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {

		my $dir = $self->{'DIR'};
		my $ignore = $self->{'IGNORE'};
		my $block_size = $self->{'BLOCK_SIZE'};
		my $tab = $self->{'TAB'};
		my $width = $self->{'WIDTH'};
		my $xflag = $self->{'FLAG'};
		my $xparam = $self->{'PARAM'};
		
		my (%acmd, @param, @flag, $flag);
		
		my $log = $self->{Spec}->{Log};
		
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
		
		if ($ignore) {
			$flag = "-I " . $ignore;
			push @flag, $flag;
		}
		if ($block_size) {
			$flag = "-k " . $block_size;
			push @flag, $flag;
		}
		if ($tab) {
			$flag = "-T " . $tab;
			push @flag, $flag;
		}
		if ($width) {
			$flag = "-w " . $width;
			push @flag, $flag;
		}
		foreach my $ip (@$xparam){
			push @param, $ip;
		}
		
		$acmd{'CMD'} = "ls";
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}

		my $cmd = $self->amin_command(\%acmd);

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "LS Failed. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "LS was successful.";
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
		$self->{IGNORE} = undef;
		$self->{BLOCK_SIZE} = undef;
		$self->{TAB} = undef;
		$self->{WIDTH} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}


sub ignore {
	my $self = shift;
	$self->{IGNORE} = shift if @_;
	return $self->{IGNORE};
}

sub block_size {
	my $self = shift;
	$self->{BLOCK_SIZE} = shift if @_;
	return $self->{BLOCK_SIZE};
}

sub tab {
	my $self = shift;
	$self->{TAB} = shift if @_;
	return $self->{TAB};
}

sub width {
	my $self = shift;
	$self->{WIDTH} = shift if @_;
	return $self->{WIDTH};
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
				} elsif ($_ eq "I") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "k") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "T") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "w") {
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

Ls - reader class filter for the gnu ls command.

=head1 version
	
ls (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the ls command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="ls">
                <amin:flag>lsa</amin:flag>
                <amin:param>/tmp</amin:param>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="ls">
                <amin:flag>lsa</amin:flag>
                <amin:param>/boot</amin:param>
        </amin:command>
       <amin:command name="ls">
                <amin:flag>lsa</amin:flag>
                <amin:param>/var</amin:param>
        </amin:command>
 </amin:profile>

=back  

=cut

