package Amin::Command::Ifconfig;

use strict;
use vars qw(@ISA);
use Amin::Elt;
use Data::Dumper;

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
	
	if ($attrs{'{}name'}->{Value} eq "interface") {
		if ($data ne "") {
			$self->interface($data);
		}
	}
	if ($attrs{'{}name'}->{Value} eq "address") {
		if ($data ne "") {
			$self->address($data);
		}
	}
	if ($attrs{'{}name'}->{Value} eq "netmask") {
		if ($data ne "") {
			$self->netmask($data);
		}
	}
        if ($attrs{'{}name'}->{Value} eq "state") {
	        if ($data ne "") {
		        $self->state($data);
		    }
	    }
	if ($attrs{'{}name'}->{Value} eq "env") {
		if ($data ne "") {
			$self->env_vars($data);
		}
	}
	if ($element->{LocalName} eq "flag") {
		if ($attrs{'{}name'}->{Value} eq "") {
			if ($data ne "") {
				$self->flag(split(/\s+/, $data));
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {

		my $interface = $self->{'INTERFACE'};
		my $address = $self->{'ADDRESS'};
		my $netmask = $self->{'NETMASK'};
	        my $state = $self->{'STATE'};
		my $xflag = $self->{'FLAG'};
		
		my (%acmd, @param, @flag, $flag);
		
		my $log = $self->{Spec}->{Log};
	    
		foreach my $ip (@$xflag){
			if (($ip =~ /^-/) || ($ip =~ /^--/)) {
				push @flag, $ip;
			} else {	
				if ($state == 0) {
					if ($ip eq "bind") {
						$flag = "--" . $ip;
					} else {
						$flag = "-" . $ip;
					}
					$state = 1;
				} else {
					if ($ip eq "bind") {
						$flag = " --" . $ip;
					} else {
						$flag = " -" . $ip;
					}
				}
				push @flag, $flag;
			}
		}
	
		push @param, "$interface";
		push @param, "$address";
	        push @param, "$netmask";
	        push @param, "$state";

		$acmd{'CMD'} = "ifconfig";
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}
		my $cmd = $self->amin_command(\%acmd);
	        # die Dumper($cmd);
		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Could not set $address on $interface. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
			    $log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "New interface created as $interface with IP of $address and netmask of $netmask.";
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

sub interface {
	my $self = shift;
	$self->{INTERFACE} = shift if @_;
	return $self->{INTERFACE};
}

sub address {
	my $self = shift;
	$self->{ADDRESS} = shift if @_;
	return $self->{ADDRESS};
}

sub netmask {
	my $self = shift;
	$self->{NETMASK} = shift if @_;
	return $self->{NETMASK};
}

sub state {
        my $self = shift;
        $self->{STATE} = shift if @_;
        return $self->{STATE};
}


1;

=head1 NAME

IFCONFIG - reader class filter for the ifconfig command.

=head1 version

ifconfig 1.42 (2001-04-13) 

=head1 DESCRIPTION

  A reader class for the ifconfig command. 
  
=head1 XML

=over 4

=item Full example

        <amin:command name="ifconfig">
                <amin:param name="interface">eth0:1</amin:param>
                <amin:param name="address">192.168.0.1</amin:param>
                <amin:param name="netmask">255.255.255.0</amin:param>
        </amin:command>

        <amin:command name="ifconfig">
                <amin:param name="interface">eth0:1</amin:param>
                <amin:param name="state">down</amin:param>
        </amin:command>

=back  

=cut

