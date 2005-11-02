package Amin::Command::Copy;

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
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "target") {
				$self->target($data);
			}
			if ($attrs{'{}name'}->{Value} eq "source") {
				my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
				foreach (@things) {
					$self->source($_);
				}
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

	if ($element->{LocalName} eq "command") {

		my $dir = $self->{'DIR'};
		my $source = $self->{'SOURCE'};
		my $target = $self->{'TARGET'};
		my @source;
		my $xflag = $self->{'FLAG'};
		my $command = "cp";
		my ($flag, @flag);
		my $log = $self->{Spec}->{Log};

		foreach my $ip (@$xflag){
			if (($ip =~ /^-/) || ($ip =~ /^--/)) {
				push @flag, $ip;
			} else {	
				if ($ip eq "remove-destination") {
					$flag = "--" . $ip;
				} else {
					$flag = "-" . $ip;
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

		foreach (@$source) {
			push @source, glob($_);
		}
		push @source, $target;

			my %acmd;
			$acmd{'CMD'} = $command;
			$acmd{'FLAG'} = \@flag;
			$acmd{'PARAM'} = \@source;

		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}
			my $cmd = $self->amin_command(\%acmd);

			#get rid of target
			pop @source;

			if ($cmd->{STATUS} != 0) {
				$self->{Spec}->{amin_error} = "red";

				my $text = "Unable to copy " . join (", ", @source) . " to $target. Reason: $cmd->{ERR}";
				$self->text($text);

				$log->error_message($text);
				if ($cmd->{ERR}) {
					$log->ERR_message($cmd->{ERR});
				}
				$self->SUPER::end_element($element);
				return;
			}

		my $text = "Copying " . join (", ", @source) . " from $dir to $target.";
		$self->text($text);
		$log->success_message($text);
		if ($cmd->{OUT}) {
			$log->OUT_message($cmd->{OUT});
		}
		#reset this command
		
		$self->{DIR} = undef;
		$self->{TARGET} = undef;
		$self->{FLAG} = [];
		$self->{SOURCE} = [];
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

sub target {
	my $self = shift;
	$self->{TARGET} = shift if @_;
	return $self->{TARGET};
}

sub source {
	my $self = shift;
	if (@_) {push @{$self->{SOURCE}}, @_; }
	return @{ $self->{SOURCE} };
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
				#this completes the -S suffix crap
				if ($_ =~ /\w+\d+/) {
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
					#check for stuff like -S=0755 crap
					($_, $char) = split (/=/, $_);
				} elsif ($_ eq "S") {
					#check for stuff like -S 0755 crap
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

Copy - reader class filter for the copy(cp) command.

=head1 version

cp (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the copy(cp) command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="copy">
                <amin:param name="source">touchfile</amin:param>
                <amin:param name="target">my_new_dir/</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
	<amin:command name="copy">
		<amin:param name="source">touchfile</amin:param>
		<amin:param name="target">my_new_dir/</amin:param>
		<amin:shell name="dir">/tmp/amin-tests/</amin:shell>
	</amin:command>
	<amin:command name="copy">
		<amin:param name="source">touchfile</amin:param>
		<amin:param name="target">my_new_dir/</amin:param>
		<amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
	</amin:command>
 </amin:profile>

=back  

=cut
