package Amin::Command::Ifconfig;

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
	if (!$attrs{'{}name'}->{'Value'}) {
		$attrs{'{}name'}->{'Value'} = "";
	}
	$self->attrs(%attrs);
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "ifconfig")) {
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
	if (($command eq "ifconfig") && ($data ne "")) {
		if ($element->{LocalName} eq "shell") {
			if ($attrs{'{}name'}->{Value} eq "env") {
				$self->env_vars($data);
			}
			if ($attrs{'{}name'}->{Value} eq "dir") {
				$self->dir($data);
			}
		}
		if ($element->{LocalName} eq "flag") {
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->flag(split(/\s+/, $data));
			}
		}

# need to add in hardwaretypes and network protocol options also
 
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "") {
			    $self->param(split(/\s+/, $data));
			}
			if ($attrs{'{}name'}->{Value} eq "interface") {
			    $self->interface($data);
			}
			if ($attrs{'{}name'}->{Value} eq "address") {
			    $self->address($data);
			}
			if ($attrs{'{}name'}->{Value} eq "netmask") {
			    $self->netmask($data);
			}
			if ($attrs{'{}name'}->{Value} eq "state") {
			    $self->state($data);
			}
			if ($attrs{'{}name'}->{Value} eq "tunnel") {
			    $self->tunnel($data);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if (($element->{LocalName} eq "command") && ($self->command eq "ifconfig")) {

		my $dir = $self->{'DIR'};
		my $interface = $self->{'INTERFACE'};
		my $address = $self->{'ADDRESS'};
		my $netmask = $self->{'NETMASK'};
	        my $state = $self->{'STATE'};
		my $xflag = $self->{'FLAG'};
		my $xparam = $self->{'PARAM'};
				
		my (%acmd, @param, @flag, $flag);
		
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
		
		foreach my $ip (@$xflag){
			if (!$ip) {next;};
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
		
		if ($interface) {
			push @param, "$interface";
		}
		if ($address) {
			push @param, "$address";
	        }
		if ($address) {
			push @param, "$netmask";
		}
		if ($address) {
	        	push @param, "$state";
		}
		foreach my $ip (@$xparam) {
			push @param, $ip;
		}

		$acmd{'CMD'} = "ifconfig";
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}
		my $cmd = $self->amin_command(\%acmd);
		
		if ($cmd->{STATUS} != 1) {
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
		#reset this command
		
		$self->{DIR} = undef;
		$self->{FLAG} = [];
		$self->{PARAM} = [];
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{ELEMENT} = undef;
		$self->{INTERFACE} = undef;
		$self->{ADDRESS} = undef;
		$self->{NETMASK} = undef;
		$self->{STATE} = undef;
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

sub version {
	return "1.0";
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

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="ifconfig">
                <amin:param name="interface">eth0:1</amin:param>
                <amin:param name="address">192.168.0.1</amin:param>
                <amin:param name="netmask">255.255.255.0</amin:param>
        </amin:command>

        <amin:command name="ifconfig">
                <amin:param name="interface">eth0:1</amin:param>
                <amin:param name="state">down</amin:param>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="ifconfig">
                <amin:param name="interface">eth0:1000</amin:param>
                <amin:param name="address">192.168.0.1</amin:param>
                <amin:param name="netmask">255.255.255.0</amin:param>
        </amin:command>

	<!--
        <amin:command name="ifconfig">
                <amin:param name="interface">eth0:1000</amin:param>
                <amin:param name="state">down</amin:param>
        </amin:command>
	-->
        <amin:command name="ifconfig">
                <amin:param name="interface">eth0:1001</amin:param>
                <amin:param name="address">192.168.0.1</amin:param>
                <amin:param name="netmask">255.255.255.0</amin:param>
        </amin:command>

	<!--
        <amin:command name="ifconfig">
                <amin:param name="interface">eth0:1001</amin:param>
                <amin:param name="state">down</amin:param>
        </amin:command>
	-->
 </amin:profile>

=back  

=cut

