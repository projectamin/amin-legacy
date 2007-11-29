package Amin::Command::Ldconfig;

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
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "ldconfig")) {
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
	if (($command eq "ldconfig") && ($data ne "")) {
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "") {
				my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
				foreach (@things) {
					$self->param($_);
				}
			}
		}
		if ($element->{LocalName} eq "flag") {
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->flag($data);
			}
			if (($attrs{'{}name'}->{Value} eq "format") || ($attrs{'{}name'}->{Value} eq "c")) {
				$self->format($data);
			}
			if ($attrs{'{}name'}->{Value} eq "C") {
				$self->cache($data);
			}
			if ($attrs{'{}name'}->{Value} eq "f") {
				$self->conf($data);
			}
			if ($attrs{'{}name'}->{Value} eq "r") {
				$self->root($data);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;
	if (($element->{LocalName} eq "command") && ($self->command eq "ldconfig")) {
		my $xflag = $self->{'FLAG'};
		my $xparam = $self->{'PARAM'};
		my $command = $self->{'COMMAND'};
		my $format = $self->{'FORMAT'};
		my $cache = $self->{'CACHE'};
		my $conf = $self->{'CONF'};
		my $root = $self->{'ROOT'};
		my (@param, $flag, @flag);
		my $log = $self->{Spec}->{Log};
		my $state = 0;
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
		if ($format) {
			$flag = "-c " . $format;
			push @flag, $flag;
		}

		if ($cache) {
			$flag = "-C " . $cache;
			push @flag, $flag;
		}
		if ($conf) {
			$flag = "-f " . $conf;
			push @flag, $flag;
		}
		if ($root) {
			$flag = "-r " . $root;
			push @flag, $flag;
		}
		foreach my $ip (@$xparam){
			push @param, $ip;
		}
		my %acmd;
		$acmd{'CMD'} = $command;
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		my $cmd = $self->amin_command(\%acmd);
		my $default = "0"; #setup the default msg flag
		if ($cmd->{TYPE} eq "error") {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to run the ldconfig command. Reason: $cmd->{ERR}";
			$default = 1;
			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
		}

		if (($cmd->{TYPE} eq "out") || ($cmd->{TYPE} eq "both")) {
			my $otext = "Ldconfig command was successful";
			my $etext = " There was also some error text $cmd->{ERR}";
			$etext = $otext . $etext; 
			if ($cmd->{TYPE} eq "out") {
				$default = 1;
				$log->success_message($otext);
				$log->OUT_message($cmd->{OUT});
			} else {
				$default = 1;
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
		$self->{FORMAT} = undef;
		$self->{CACHE} = undef;
		$self->{CONF} = undef;
		$self->{ROOT} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub format {
	my $self = shift;
	$self->{FORMAT} = shift if @_;
	return $self->{FORMAT};
}

sub cache {
	my $self = shift;
	$self->{CACHE} = shift if @_;
	return $self->{CACHE};
}

sub conf {
	my $self = shift;
	$self->{CONF} = shift if @_;
	return $self->{CONF};
}

sub root {
	my $self = shift;
	$self->{ROOT} = shift if @_;
	return $self->{ROOT};
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
				#this completes the -n 100 crap
				if ($_ =~ /\d+/) {
					$char = $_;
				} else {
					#this is a param and their -n is not
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
					#check for stuff like -n=100 crap
					($_, $char) = split (/=/, $_);
				} elsif (($_ eq "c") || ($_ eq "format")){
					#check for stuff like -n 100 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "C") {
					#check for stuff like -n 100 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "f") {
					#check for stuff like -n 100 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "r") {
					#check for stuff like -n 100 crap
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

Ldconfig - reader class filter for the ldconfig command.

=head1 version

Ldconfig (GNU libc) 2.3.2

=head1 DESCRIPTION

  A reader class for the ldconfig command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="ldconfig">
		<amin:flag name="c">compat</amin:flag>
                <amin:flag>v</amin:flag>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="ldconfig">
		<amin:flag name="c">compat</amin:flag>
                <amin:flag>v</amin:flag>
        </amin:command>
        <amin:command name="ldconfig">
		<amin:flag>?</amin:flag>
        </amin:command>
 </amin:profile>

=back  

=cut