package Amin::Command::Ip;

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
			if ($attrs{'{}name'}->{Value} eq "device") {
			    $self->device($data);
			}
			if ($attrs{'{}name'}->{Value} eq "state") {
			    $self->state($data);
			}
			if ($attrs{'{}name'}->{Value} eq "arp") {
			    $self->arp($data);
			}
			if ($attrs{'{}name'}->{Value} eq "multicast") {
			    $self->multicast($data);
			}
			if ($attrs{'{}name'}->{Value} eq "dynamic") {
			    $self->dynamic($data);
			}
			if ($attrs{'{}name'}->{Value} eq "name") {
			    $self->name($data);
			}
			if ($attrs{'{}name'}->{Value} eq "txqlen") {
			    $self->txqlen($data);
			}
			if ($attrs{'{}name'}->{Value} eq "mtu") {
			    $self->mtu($data);
			}
			if ($attrs{'{}name'}->{Value} eq "address") {
			    $self->address($data);
			}
			if ($attrs{'{}name'}->{Value} eq "broadcast") {
			    $self->broadcast($data);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if (($element->{LocalName} eq "command") && ($self->command eq "ip")) {

		my $dir = $self->{'DIR'};
		my $device = $self->{'DEVICE'};
		my $state = $self->{'STATE'};
		my $arp = $self->{'ARP'};
	        my $multicast = $self->{'MULTICAST'};
		my $dynamic = $self->{'DYNAMIC'};
		my $name = $self->{'NAME'};
		my $txqlen = $self->{'TXQLEN'}
		my $mtu = $self->{'MTU'};
		my $address = $self->{'ADDRESS'};
		my $broadcast = $self->{'BROADCAST'};
		my $xflag = $self->{'FLAG'};
		my $xparam = $self->{'PARAM'};
		my (%acmd, @param, @flag, $flag);
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
		if ($device) {
			push @param, "$device";
		}
		if ($state) {
			push @param, "$state";
	        }
		if ($arp) {
			push @param, "$arp";
		}
		if ($multicast) {
	        	push @param, "$multicast";
		}
		if ($dynamic) {
			push @param, "$dynamic";
		}
		if ($name) {
			push @param, "$name";
		}
		if ($txqlen) {
			push @param, "$txqlen";
		}
		if ($mtu) {
			push @param, "$mtu";
		}
		if ($address) {
			push @param, "$address";
		}
		if ($broadcast) {
			push @param, "$broadcast";
		}
		foreach my $ip (@$xparam) {
			push @param, $ip;
		}
		$acmd{'CMD'} = "ip";
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}
		my $cmd = $self->amin_command(\%acmd);
		if ($cmd->{TYPE} eq "error") {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Could not set $address on $interface. Reason: $cmd->{ERR}";
			$default = 1;
			$log->error_message($text);
			if ($cmd->{ERR}) {
			    $log->ERR_message($cmd->{ERR});
			}
		}

		if (($cmd->{TYPE} eq "out") || ($cmd->{TYPE} eq "both")) {
			my $otext;
			if ($state eq "down") {
				$otext = "Interface $interface has been brought down";
			} else {
				$otext = "New interface created as $interface with IP of $address and netmask of $netmask.";
			}
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
		if ($default == 0) {
			my $text = "there was no messages?";
			$log->error_message($text);
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

