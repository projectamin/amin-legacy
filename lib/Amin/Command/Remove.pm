package Amin::Command::Remove;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use warnings;
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
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command")) {
		if (($attrs{'{}name'}->{Value} eq "remove") || ($attrs{'{}name'}->{Value} eq "rm")) {
			$self->command($attrs{'{}name'}->{Value});
	}
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
	if (($command eq "remove") || ($command eq "rm")) {
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
			#if ($attrs{'{}name'}->{Value} eq "target") {
				my @things = $data =~ m/([\[\*\+\.\w=\/-]+|'[^']+')\s*/g;
				foreach (@things) {
					$self->target($_);
				}
			#}
		}
		if ($element->{LocalName} eq "flag") {
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->flag(split(/\s+/, $data));
			}
		}
	}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {
	if (($self->command eq "rm") || ($self->command eq "remove")) {
		my $xflag = $self->{'FLAG'};
		my $target = $self->{'TARGET'};
		my $dir = $self->{'DIR'};
		my $command = "rm";
		my ($flag, @flag, @param);
		my $log = $self->{Spec}->{Log};

		foreach my $ip (@$xflag){
			if (!$ip) {next;};
			if (($ip =~ /^-/) || ($ip =~ /^--/)) {
				push @flag, $ip;
			} else {	
				$flag = "-" . $ip;
				push @flag, $flag;
			}
		}

		foreach my $ip (@$target){
			#this is needed if the file is [ because a glob will kill it
			if ($ip =~ /\[/) {
				push @param, $ip;
			} else {
				push @param, glob($ip);
			}
		}

		my $default = "0"; #setup the default msg flag
		if ($dir) {
			if (! chdir $dir) {
				$self->{Spec}->{amin_error} = "red";
				my $text = "Unable to change directory to $dir. Reason: $!";
				$default = 1;
				$log->error_message($text);
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

		if ($cmd->{TYPE} eq "error") {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to execute $command in $dir. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
		}
		if (($cmd->{TYPE} eq "out") || ($cmd->{TYPE} eq "both")) {
			my $otext;
			if ($dir) {
				$otext = "Removed " . join (", ", @$target) . " from $dir";
			} else {
				$otext = "Removed " . join (", ", @$target);
			}
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
		$self->{TARGET} = [];
		$self->{PARAM} = [];
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{ELEMENT} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
	} else {
		$self->SUPER::end_element($element);
	}
}

sub version {
	return "1.0";
}

1;

=head1 NAME

Remove - reader class filter for the remove(rm) command.

=head1 version

rm (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the remove(rm) command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="remove">
                <amin:param name="target">limits hg linked_thing touchfile touchfile2</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="remove">
                <amin:param name="target">limits hg linked_thing touchfile touchfile2</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
        <amin:command name="remove">
                <amin:param name="target">limits hg linked_thing touchfile touchfile2</amin:param>
                <amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut
