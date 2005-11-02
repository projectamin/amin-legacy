package Amin::Command::Patch;

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
			if ($attrs{'{}name'}->{Value} eq "input") {
				$self->input($data);
			}
		}
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "") {
				my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
				foreach (@things) {
					$self->param($_);
				}
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {
		my $dir = $self->{'DIR'};
		my $input = $self->{'INPUT'};
		my $xflag = $self->{'FLAG'};
		my $param = $self->{'PARAM'};
		my $command = "patch";
		my ($flag, @flag, @param);
		my $log = $self->{Spec}->{Log};

		foreach my $ip (@$xflag){
			if (($ip =~ /^-/) || ($ip =~ /^--/)) {
				push @flag, $ip;
			} else {	
				$flag = "-" . $ip;
				push @flag, $flag;
			}
		}
		
		foreach my $ip (@$param){
			push @param, $ip;
		}

		
		if ($input) {
			push @flag, "-i";
			push @flag, $input
		} else {
			#throw a must have an input error
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
		$acmd{'PARAM'} = \@param;
		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}

		my $cmd = $self->amin_command(\%acmd);

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to execute patch $command in $dir. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "Executing patch " . join (" ", @flag) . " " .  join (" ", @param) . " in $dir:";
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
		$self->{INPUT} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub input {
	my $self = shift;
	$self->{INPUT} = shift if @_;
	return $self->{INPUT};
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
				} elsif ($_ eq "B") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "d") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "D") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "F") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "g") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "i") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "o") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "r") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "V") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "x") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "Y") {
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

Patch - reader class filter for the patch command.

=head1 version

GNU 1998/03/21 PATCH

=head1 DESCRIPTION

  A reader class for the patch command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:download>
                <amin:param name="uri">http://projectamin.org/apan/tester/command/fake-0.02.patch</amin:param>
                <amin:param name="file">/tmp/amin-tests/fake-0.02.patch</amin:param>
        </amin:download>
        <amin:command name="patch">
                <amin:flag>p1</amin:flag>
                <amin:flag name="input">/tmp/amin-tests/fake-0.02.patch</amin:flag>
                <amin:shell name="dir">/tmp/amin-tests/fake-0.01</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:download>
                <amin:param name="uri">http://projectamin.org/apan/tester/command/fake-0.02.patch</amin:param>
                <amin:param name="file">/tmp/amin-tests/fake-0.02.patch</amin:param>
        </amin:download>
        <amin:command name="patch">
                <amin:flag>p1</amin:flag>
                <amin:flag name="input">/tmp/amin-tests/fake-0.02.patch</amin:flag>
                <amin:shell name="dir">/tmp/amin-tests/fake-0.01</amin:shell>
        </amin:command>
       <amin:download>
                <amin:param name="uri">http://projectamin.org/apan/tester/command/fake-0.02.patch</amin:param>
                <amin:param name="file">/tmp/amin-tests2/fake-0.02.patch</amin:param>
        </amin:download>
        <amin:command name="patch">
                <amin:flag>p1</amin:flag>
                <amin:flag name="input">/tmp/amin-tests2/fake-0.02.patch</amin:flag>
                <amin:shell name="dir">/tmp/amin-tests2/fake-0.01</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut