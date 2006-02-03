package Amin::Command::Hostname;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

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
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->param($data);
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
		my $xflag = $self->{'FLAG'};
		my $command = $self->{'COMMAND'};
		my $param = $self->{'PARAM'};
		my ($flag, @flag, @param);
		my $log = $self->{Spec}->{Log};

		my $state;
		foreach my $ip (@$xflag){
			if ($state == 0) {
				$flag = "--" . $ip;
				$state = 1;
			} else {
				$flag = " --" . $ip;
			}
			push @flag, $flag;
		}

		push @param, $param;
		my %acmd;
		$acmd{'CMD'} = $command;
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		
		my $cmd = $self->amin_command(\%acmd);

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to run hostname. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text;
		if ($param) {
			$text = "Hostname has been set to $param.";
		} else {
			$text = "Hostname is $cmd->{OUT}";
		}
		$self->text($text);

		$log->success_message($text);
		if ($cmd->{OUT}) {
			$log->OUT_message($cmd->{OUT});
		}
		#reset this command
		
		$self->{DIR} = undef;
		$self->{FLAG} = [];
		$self->{PARAM} = undef;
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{ELEMENT} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub param {
	my $self = shift;
	$self->{PARAM} = shift if @_;
	return $self->{PARAM};
}


sub version {
	return "1.0";
}

1;

=head1 NAME

Hostname - reader class filter for the hostname command.

=head1 version

hostname (coreutils) 

=head1 DESCRIPTION

  A reader class for the hostname command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="hostname"/>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="hostname">
		<amin:param>bbb</amin:param>
	</amin:command>
        <amin:command name="hostname"/>
 </amin:profile>

=back  

=cut

