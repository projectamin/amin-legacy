package Amin::Command::Zip;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use warnings "all";
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
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "zip")) {
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
	if (($self->command eq "zip") && ($data ne "")) {
		if ($element->{LocalName} eq "shell") {
			if ($attrs{'{}name'}->{Value} eq "env") {
				$self->env_vars($data);
			}
			if ($attrs{'{}name'}->{Value} eq "dir") {
				$self->dir($data);
			}
		}
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "source") {
				$self->source(split(/\s+/, $data));
			}
			if ($attrs{'{}name'}->{Value} eq "target") {
				$self->target(split(/\s+/, $data));
			}
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->param(split(/\s+/, $data));
			}
		}
		if ($element->{LocalName} eq "flag") {
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->flag(split(/\s+/, $data));
			}
			if ($attrs{'{}name'}->{Value} eq "b") {
				$self->path($data);
			}
			if ($attrs{'{}name'}->{Value} eq "t") {
				$self->date($data);
			}
			if ($attrs{'{}name'}->{Value} eq "n") {
				$self->suffix($data);
			}
			if ($attrs{'{}name'}->{Value} eq "x") {
				$self->exclude($data);
			}
			if ($attrs{'{}name'}->{Value} eq "i") {
				$self->include($data);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;
	my $attrs = $self->{"AATTRS"};

	if (($element->{LocalName} eq "command") && ($self->command eq "zip")) {
		my $dir = $self->{'DIR'};
		my $path = $self->{'PATH'};
		my $date = $self->{'DATE'};
		my $suffix = $self->{'SUFFIX'};
		my $exclude = $self->{'EXCLUDE'};
		my $include = $self->{'INCLUDE'};
		my $xflag = $self->{'FLAG'};
		my $xparam = $self->{'PARAM'};
		my $source = $self->{'SOURCE'};
		my $target = $self->{'TARGET'};
		
		my (%acmd, @param, @flag, $flag);
		
		my $log = $self->{Spec}->{Log};
		
		my $default = "0"; #setup the default msg flag
		if ($dir) {
			if (! chdir $dir) {
				$self->{Spec}->{amin_error} = "red";
				my $text = "Unable to change directory to $dir. Reason: $!";
				$default = 1;
				$log->error_message($text);
			}
		}
		
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
		
		if ($path) {
			$flag = "-b " . $path;
			push @flag, $flag;
		}
	
		if ($date) {
			$flag = "-t " . $date;
			push @flag, $flag;
		}
		if ($suffix) {
			$flag = "-n " . $suffix;
			push @flag, $flag;
		}
		if ($include) {
			$flag = "-i " . $include;
			push @flag, $flag;
		}
		if ($exclude) {
			$flag = "-x " . $exclude;
			push @flag, $flag;
		}
		foreach my $xtarget (@$target){
			push @param, $xtarget;
		}
		foreach my $xsource (@$source){
			push @param, glob($xsource);
		}
		foreach my $ip (@$xparam){
			push @param, $ip;
		}
		
		$acmd{'CMD'} = "zip";
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}

		my $cmd = $self->amin_command(\%acmd);

		if ($cmd->{TYPE} eq "error") {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Zip Failed. Reason: $cmd->{ERR}";
			$default = 1;
			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
		}

		if (($cmd->{TYPE} eq "out") || ($cmd->{TYPE} eq "both")) {
			my $otext = "Zip was successful.";
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
		$self->{TARGET} = [];
		$self->{PARAM} = [];
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{ELEMENT} = undef;
		$self->{SOURCE} = [];
		$self->{PATH} = undef;
		$self->{DATE} = undef;
		$self->{EXCLUDE} = undef;
		$self->{INCLUDE} = undef;
		$self->{SUFFIX} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub source {
	my $self = shift;
	if (@_) {push @{$self->{SOURCE}}, @_; }
	return @{ $self->{SOURCE} };
}

sub path {
	my $self = shift;
	$self->{PATH} = shift if @_;
	return $self->{PATH};
}

sub date {
	my $self = shift;
	$self->{DATE} = shift if @_;
	return $self->{DATE};
}

sub exclude {
	my $self = shift;
	$self->{EXCLUDE} = shift if @_;
	return $self->{EXCLUDE};
}

sub include {
	my $self = shift;
	$self->{INCLUDE} = shift if @_;
	return $self->{INCLUDE};
}

sub suffix {
	my $self = shift;
	$self->{SUFFIX} = shift if @_;
	return $self->{SUFFIX};
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
				} elsif ($_ eq "b") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "t") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "n") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "i") {
					#check for stuff like -m 0755 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "x") {
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

Zip - reader class filter for the zip command.

=head1 version

Zip 2.3 (November 29th 1999)

=head1 DESCRIPTION

  A reader class for the zip command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="zip">
                <amin:flag name="b">/tmp/amin-tests/*</amin:flag>
                <amin:param>/tmp/amin-tests/file.zip</amin:param>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="zip">
                <amin:param name="source">/tmp/amin-tests/*</amin:param>
                <amin:param name="target">/tmp/amin-tests/amin-file.zip</amin:param>
                <amin:flag>q</amin:flag>
        </amin:command>
        <amin:command name="zip">
                <amin:param name="source">/tmp/amin-tests2/*</amin:param>
                <amin:param name="target">/tmp/amin-tests2/amin-file.zip</amin:param>
                <amin:flag>q</amin:flag>
        </amin:command>
 </amin:profile>

=back  

=cut

