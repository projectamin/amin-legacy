package Amin::Command::Makewhatis;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use warnings;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);

my (%attrs, @target);

sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	if (!$attrs{'{}name'}->{'Value'}) {
		$attrs{'{}name'}->{'Value'} = "";
	}
	$self->attrs(%attrs);
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "makewhatis")) {
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
	if (($command eq "makewhatis") && ($data ne "")) {
		if ($element->{LocalName} eq "flag") {
			if (($attrs{'{}name'}->{Value} eq "s") || ($attrs{'{}name'}->{Value} eq "sections")) {
				$self->sections($data);
			}
			if (($attrs{'{}name'}->{Value} eq "catpath") ||($attrs{'{}name'}->{Value} eq "c")){
				$self->catpath($data);
			}
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->flag(split(/\s+/, $data));
			}
		}
		if ($element->{LocalName} eq "param") {
			my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
			foreach (@things) {
				$self->param($_);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if (($element->{LocalName} eq "command") && ($self->command eq "makewhatis")) {
		my $sections = $self->{'SECTIONS'};
		my $catpath = $self->{'CATPATH'};
		my $xflag = $self->{'FLAG'};
		my $command = $self->{'COMMAND'};
		my $xparam = $self->{'PARAM'};
		my ($flag, @flag, @param);
		my $log = $self->{Spec}->{Log};

		my $state = 0;
		foreach my $ip (@$xflag){
			if (!$ip) {next;};
			if ($state == 0) {
				$flag = "-" . $ip;
				$state = 1;
			} else {
				$flag = " -" . $ip;
			}
			push @flag, $flag;
		}
		if ($sections) {
			$flag = "-s " . $sections;
			push @flag, $flag;
		}

		if ($catpath) {
			$flag = "-c " . $catpath;
			push @flag, $flag;
		}

		foreach (@$xparam) {
			push @param, $_;
		}
		
		my %acmd;
		$acmd{'CMD'} = $command;
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		
		my $cmd = $self->amin_command(\%acmd);

		my $default = "0"; #setup the default msg flag
		if ($cmd->{TYPE} eq "error") {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to makewhatis. Reason: $cmd->{ERR}";
			$default = 1;
			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
		}
		if (($cmd->{TYPE} eq "out") || ($cmd->{TYPE} eq "both")) {
			my $otext = "Makewhatis was successful";
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
		$self->{PARAM} = [];
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{ELEMENT} = undef;
		$self->{SECTIONS} = undef;
		$self->{CATPATH} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}


sub sections {
	my $self = shift;
	$self->{SECTIONS} = shift if @_;
	return $self->{SECTIONS};
}

sub catpath {
	my $self = shift;
	$self->{CATPATH} = shift if @_;
	return $self->{CATPATH};
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
				#this completes the -s 5 crap
				if ($_ =~ /\d+/) {
					$char = $_;
				} else {
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
					($_, $char) = split (/=/, $_);
				} elsif ($_ eq "s") {
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "c") {
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

Makewhatis - reader class filter for the makewhatis command.

=head1 version

makewhatis (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the makewhatis command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="makewhatis">
                <amin:flag>w</amin:flag>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="makewhatis">
                <amin:flag>w</amin:flag>
        </amin:command>
        <amin:command name="makewhatis">
                <amin:flag>w</amin:flag>
        </amin:command>
 </amin:profile>

=back  

=cut

