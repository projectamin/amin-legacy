package Amin::Command::Gcc_dump_specs;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use warnings;
use vars qw(@ISA);
use Amin::Elt;
use Data::Dumper;

@ISA = qw(Amin::Elt);
my %attrs;

sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	$attrs{'{}name'}->{'Value'} = "" unless $attrs{'{}name'}->{'Value'};	
	$self->attrs(%attrs);
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "gcc_dump_specs")) {
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
	if (($command eq "gcc_dump_specs") && ($data ne "")) {
		if ($element->{LocalName} eq "flag") {
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->flag(split(/\s+/, $data));
			}
		}
	
		if ($element->{LocalName} eq "shell") {
	
			if ($attrs{'{}name'}->{Value} eq "env") {
				$self->env_vars($data);
			}
			if ($attrs{'{}name'}->{Value} eq "dir") {
				$self->dir($data);
			}
		}
	
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "specsfile") {
				$self->specsfile($data);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if (($element->{LocalName} eq "command") && ($self->command eq "gcc_dump_specs")) {

		my $dir = $self->{'DIR'};
		my $specsfile = $self->{'SPECSFILE'};
		my $content;
		my @content;
		
		my (%acmd, @param, @flag);
		
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

		$acmd{'CMD'} = "gcc";
		push(@flag, "-dumpspecs");
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}

		my $cmd = $self->amin_command(\%acmd);

		if ($cmd->{TYPE} eq "error") {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Dumpspecs Failed. Reason: $cmd->{ERR}";
			$default = 1;
			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
		}

		if (($cmd->{TYPE} eq "out") || ($cmd->{TYPE} eq "both")) {
			my $otext = "Dumpspecs was successful.";
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
		@$content = $cmd->{OUT};
		if ($default == 0) {
			my $text = "there was no output?";
			$log->error_message($text);
		}
		if (! open (FILE, "> $specsfile")) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to open $specsfile for dumping, $!";
			$self->text($text);

			$log->error_message($text);
			$self->{'CONTENT'} = undef;
			$self->SUPER::end_element($element);
			return;
		}

		foreach my $line(@$content) {
			$line =~ s/(^\s+|\s+$)//gm;
			if ($line) {
				print FILE "$line\n";
			}
		}
		close (FILE);
		#reset this command
		$self->{DIR} = undef;
		$self->{FLAG} = [];
		$self->{PARAM} = [];
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{ELEMENT} = undef;
		$self->{SPECSFILE} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub specsfile {
	my $self = shift;
	$self->{SPECSFILE} = shift if @_;
	return $self->{SPECSFILE};
}

sub filter_map {
	my $self = shift;
	my $command = shift;
	my %command;
	my @flags;
	my @params;
	my @shells;
	my $stop;

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

touch - reader class filter for the gcc -dumpspecs command.

=head1 version

gcc 2.95+ 

=head1 DESCRIPTION

  A reader class for the gcc-dumpecs command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="gcc_dump_specs">
		<amin:param name="specsfile">/usr/lib/gcc/path/to/specsfile</amin:param>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="gcc_dump_specs">
		<amin:param name="specsfile">/usr/lib/gcc/path/to/specsfile</amin:param>
        </amin:command>>
        <amin:command name="gcc_dump_specs">
		<amin:param name="specsfile">/usr/lib/gcc/path/to/specsfile</amin:param>
        </amin:command>
 </amin:profile>

=back  

=cut

