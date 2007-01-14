package Amin::Command::Kill;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use Amin::Elt;
use Proc::ProcessTable;
use vars qw(@ISA);

@ISA = qw(Amin::Elt);

my %attrs;
sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	if (!$attrs{'{}name'}->{'Value'}) {
		$attrs{'{}name'}->{'Value'} = "";
	}
	$self->attrs(%attrs);
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "kill")) {
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

	if (($command eq "kill") && ($data ne "")) {
		if ($element->{LocalName} eq "param") {
			my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
			foreach (@things) {
				$self->param($_);
			}
		}
		if ($element->{LocalName} eq "flag") {
			if ($attrs{'{}name'}->{Value} eq "signal") {
				$self->flag($data);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if (($element->{LocalName} eq "command") && ($self->command eq "kill")) {
		my $xparam = $self->{'PARAM'};
		my $command = $self->{'COMMAND'};
		my $signal = $self->{'FLAG'};
		my $log = $self->{Spec}->{Log};
		my $state;
		my @pat;
		
		foreach (@$xparam) {
			push @pat, $_;
		}

		#signal check
		if (!$signal) {
			$signal = "9";
		}
					
		my $t = new Proc::ProcessTable;
		my $text = "Kill has killed the following processes";
		my $error;
		
		my $count;
		
		
		foreach my $pat (@pat) {
		foreach my $p (@{$t->table}) {
			my $npat = $p->cmndline;
			$npat = $self->fix_text($npat);
			if ($npat =~ /^$pat$/) {
				next unless $p->pid != $$ || $self;
				my $lpid = $p->pid;
				if (kill $signal, $p->pid) {
					#killed the process add a message
					$count=1;
					$text = $text . " $pat pid $lpid"; 
					last;
				} else {
					$self->{Spec}->{amin_error} = "red";
					$text = $text . "could not kill $pat $lpid,";
					$error = 1;
				}
			}
		}
		}
		if (!$count) {
			$text = "Kill could not find the following processes";
			foreach (@pat) {
				$text = $text . " $_,";
			}
		}
		$self->text($text);
		if ($error) {
			$log->error_message($text);
		} else {
			$log->success_message($text);
		}
		
		#reset this command
		
		$self->{DIR} = undef;
		$self->{FLAG} = undef;
		$self->{PARAM} = [];
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{NAME} = undef;
		$self->{ELEMENT} = undef;

		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub version {
	return "1.0";
}

sub flag {
        my $self = shift;
        $self->{FLAG} = shift if @_;
        return $self->{FLAG};
}


1;

=head1 NAME

Kill - reader class filter for the kill command.

=head1 version

kill Taken from BSD 4.4.

=head1 DESCRIPTION

  A reader class for the kill command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="kill">
                <amin:flag name="signal">9</amin:flag>
                <amin:param name="signal">syslogd</amin:param>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="kill">
                <amin:flag name="signal">9</amin:flag>
                <amin:param>syslogd</amin:param>
        </amin:command>
        <amin:command name="kill">
                <amin:flag name="signal">9</amin:flag>
                <amin:param>klogd</amin:param>
        </amin:command>
 </amin:profile>

=back  

=cut
