package Amin::Command::Groupdel;

use strict;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);

my (%attrs, @target);

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

	if ($element->{LocalName} eq "param") {
		if ($attrs{'{}name'}->{Value} eq "") {
			if ($data ne "") {
				my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
				foreach (@things) {
					$self->param($_);
				}
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {
		my $xparam = $self->{'PARAM'};
		my $command = $self->{'COMMAND'};
		my (@param, @flag, $flag);
		my $log = $self->{Spec}->{Log};
		my $xflag = $self->{'FLAG'};
		my $state;
		foreach my $ip (@$xflag){
			if ($state == 0) {
				$flag = "-" . $ip;
				$state = 1;
			} else {
				$flag = " -" . $ip;
			}
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

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to delete group. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		
		my $text = "Deleted the following group(s): ";
		$text .= join (", ", @$xparam);		
		$self->text($text);

		$log->success_message($text);
		if ($cmd->{OUT}) {
			$log->OUT_message($cmd->{OUT});
		}
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub version {
	return "1.0";
}

1;

=head1 NAME

Groupdel - reader class filter for the groupdel command.

=head1 version

Groupdel (coreutils) 

=head1 DESCRIPTION

  A reader class for the groupdel command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="groupdel">
                <amin:param>mynewgroup</amin:param>
        </amin:command>
 </amin:profile>

=back  

=cut