package Amin::Command::Tail;

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
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "tail")) {
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
	if (($command eq "tail") && ($data ne "")) {
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "") {
				my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
				foreach (@things) {
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
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->flag($_);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if (($element->{LocalName} eq "command") && ($self->command eq "tail")) {
		my $flag = $self->{'FLAG'};
		my $xparam = $self->{'PARAM'};
		my $command = $self->{'COMMAND'};
		my $dir = $self->{'DIR'};
		
		my (@param, @flag);

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
		
		if ($flag) {	
			$flag = "-" . $flag;
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

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to run the tail command. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "Tail command was successful";
		$self->text($text);

		$log->success_message($text);
		if ($cmd->{OUT}) {
			$log->OUT_message($cmd->{OUT});
		}
		#reset this command
		
		$self->{DIR} = undef;
		$self->{FLAG} = undef;
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

sub flag {
	my $self = shift;
	$self->{FLAG} = shift if @_;
	return $self->{FLAG};
}

sub version {
	return "1.0";
}


1;

=head1 NAME

Tail - reader class filter for the tail command.

=head1 version

Tail 

=head1 DESCRIPTION

  A reader class for the tail command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="tail">
                <amin:param>hg</amin:param>
		<amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="tail">
                <amin:param>hg</amin:param>
		<amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
        <amin:command name="tail">
                <amin:param>hg</amin:param>
		<amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut