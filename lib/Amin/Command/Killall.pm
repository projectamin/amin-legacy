package Amin::Command::Killall;

use strict;
use Proc::ProcessTable;
use Amin::Elt;
use vars qw(@ISA);

@ISA = qw(Amin::Elt);

my (%attrs, @target);

sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	if (!$attrs{'{}name'}->{'Value'}) {
		$attrs{'{}name'}->{'Value'} = "";
	}
	$self->attrs(%attrs);
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "killall")) {
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

	if (($self->command eq "killall") && ($data ne "")) {
	
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

	if (($element->{LocalName} eq "command") && ($self->command eq "killall")) {
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
					
		my $killed = 0;
		my $t = new Proc::ProcessTable;
		my $text = "Killall has killed the following processes ";
		my $error;
		foreach my $pat (@pat) {
		foreach my $p (@{$t->table}) {
			if ($p->cmndline =~ /$pat/) {
				next unless $p->pid != $$ || $self;
				if (kill $signal, $p->pid) {
					#killed the process add a message
					#increment meter
					$killed++;
					$text = $text . "killed $pat $p->pid,"; 
				} else {
					$self->{Spec}->{amin_error} = "red";
					$text = $text . "could not kill $pat $p->pid,";
					$error = 1;
				}
			}
		}
		}
		$text = " total number of processes killed $killed.";
		$self->text($text);
		if ($error) {
			$log->error_message($text);
		} else {
			$log->success_message($text);
		}	
	}
}

sub version {
	return "1.0";
}

1;

=head1 NAME

Killall - reader class filter for the amin killall command.

=head1 version

Amin 0.5.0 

=head1 DESCRIPTION

  A reader class for the amin killall command. 
  
=head1 XML

=over 4

=item Full example

	<amin:command name="killall">
		<amin:flag name="signal">9</amin:flag>
		<amin:param>syslogd</amin:param>
	</amin:command>

=back  

=cut