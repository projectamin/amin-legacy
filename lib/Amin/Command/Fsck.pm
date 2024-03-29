package Amin::Command::Fsck;

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
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "fsck")) {
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
	if (($command eq "fsck") && ($data ne "")) {
		if ($element->{LocalName} eq "shell") {
			if ($attrs{'{}name'}->{Value} eq "dir") {
				$self->dir($data);
			}
			if ($attrs{'{}name'}->{Value} eq "env") {
				$self->env_vars($data);
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
		if ($element->{LocalName} eq "flag") {
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->flag($_);
			}
			if ($attrs{'{}name'}->{Value} eq "b") {
				$self->superblock($data);
			}
			if ($attrs{'{}name'}->{Value} eq "B") {
				$self->blocksize($data);
			}
			if ($attrs{'{}name'}->{Value} eq "j") {
				$self->journal($data);
			}	
			if ($attrs{'{}name'}->{Value} eq "l") {
				$self->addbadblocks($data);
			}
			if ($attrs{'{}name'}->{Value} eq "L") {	
				$self->setbadblocks($data);
			}
		}	
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if (($element->{LocalName} eq "command") && ($self->command eq "fsck")) {
		my $dir = $self->{'DIR'};
		my $xflag = $self->{'FLAG'};
		my $xparam = $self->{'PARAM'};
		my $command = $self->{'COMMAND'};
		my $superblock = $self->{'SUPERBLOCK'};
		my $blocksize = $self->{'BLOCKSIZE'};
		my $journal = $self->{'JOURNAL'};
		my $addbadblocks = $self->{'ADDBADBLOCKS'};
		my $setbadblocks = $self->{'SETBADBLOCKS'};
		
		my ($flag, @flag, @param);
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
			if ($ip =~ /-/) {
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
		
		if ($superblock) {
			$flag = "-b " . $superblock;
			push @flag, $flag;
		}

		if ($blocksize) {
			$flag = "-B " . $blocksize;
			push @flag, $flag;
		}
		
		if ($journal) {
			$flag = "-j " . $journal;
			push @flag, $flag;
		}
		
		if ($addbadblocks) {
			$flag = "-l " . $addbadblocks;
			push @flag, $flag;
		}
		if ($setbadblocks) {
			$flag = "-L " . $setbadblocks;
			push @flag, $flag;
		}
				
		foreach my $ip (@$xparam){
			push @param, $ip;
		}

		my %acmd;
		$acmd{'CMD'} = $command;
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		
		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}
		my $cmd = $self->amin_command(\%acmd);
		if ($cmd->{TYPE} eq "error") {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to run the fsck command. Reason: $cmd->{ERR}";
			$default = 1;
			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
		}
		if (($cmd->{TYPE} eq "out") || ($cmd->{TYPE} eq "both")) {
			my $otext = "Fsck command was successful";
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
		$self->{SUPERBLOCK} = undef;
		$self->{BLOCKSIZE} = undef;
		$self->{JOURNAL} = undef;
		$self->{ADDBADBLOCKS} = undef;
		$self->{SETBADBLOCKS} = undef;
		$self->{FLAG} = [];
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

sub superblock {
	my $self = shift;
	$self->{SUPERBLOCK} = shift if @_;
	return $self->{SUPERBLOCK};
}

sub blocksize {
	my $self = shift;
	$self->{BLOCKSIZE} = shift if @_;
	return $self->{BLOCKSIZE};
}

sub journal {
	my $self = shift;
	$self->{JOURNAL} = shift if @_;
	return $self->{JOURNAL};
}
 
sub addbadblocks {
	my $self = shift;
	$self->{ADDBADBLOCKS} = shift if @_;
	return $self->{ADDBADBLOCKS};
}
 
sub setbadblocks {
	my $self = shift;
	$self->{SETBADBLOCKS} = shift if @_;
	return $self->{SETBADBLOCKS};
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
				} elsif ($_ eq "b") {
					#check for stuff like -n 100 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "B") {
					#check for stuff like -n 100 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "j") {
					#check for stuff like -n 100 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "l") {
					#check for stuff like -n 100 crap
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "L") {
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

Fsck - reader class filter for the fsck command.

=head1 version

Fsck 1.32 (09-Nov-2002)

=head1 DESCRIPTION

  A reader class for the fsck command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="fsck">
                <amin:param>/dev/hdc1</amin:param>
                <amin:flag>p</amin:flag>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="fsck">
                <amin:param>/dev/hdc1</amin:param>
                <amin:flag>p</amin:flag>
        </amin:command>
       <amin:command name="fsck">
                <amin:param>/dev/hdc2</amin:param>
                <amin:flag>p</amin:flag>
        </amin:command>
 </amin:profile>

=back  

=cut
