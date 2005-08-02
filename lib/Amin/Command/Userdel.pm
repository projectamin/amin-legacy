package Amin::Command::Userdel;

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
	if ($element->{LocalName} eq "flag") {
		if ($attrs{'{}name'}->{Value} eq "") {
			if ($data ne "") {
				$self->flag($_);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {
		my $flag = $self->{'FLAG'};
		my $xparam = $self->{'PARAM'};
		my $command = $self->{'COMMAND'};
		
		my (@flag, @param);

		my $log = $self->{Spec}->{Log};
		
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
		
		my $cmd = $self->amin_command(\%acmd);

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to run the userdel command. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "Userdel command was successful";
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

sub flag {
	my $self = shift;
	$self->{FLAG} = shift if @_;
	return $self->{FLAG};
}


1;

=head1 NAME

Userdel - reader class filter for the userdel command.

=head1 version

Userdel 

=head1 DESCRIPTION

  A reader class for the userdel command. 
  
=head1 XML

=over 4

=item Full example

        <amin:command name="userdel">
                <amin:param>somename</amin:param>
                <amin:flag>r</amin:flag>
        </amin:command>

=back  

=cut