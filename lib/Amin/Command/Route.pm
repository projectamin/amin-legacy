package Amin::Command::Route;

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
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "route")) {
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
	if (!$command) {
		$command = "";
	}
	if (($command eq "route") && ($data ne "")) {
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
				$self->flag($data);
			}
		}
 
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
			if ($attrs{'{}name'}->{Value} eq "type") {
			    $self->type($data);
			}
			if ($attrs{'{}name'}->{Value} eq "metric") {
			    $self->metric($data);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if (($element->{LocalName} eq "command") && ($self->command eq "route")) {

		my $dir = $self->{'DIR'};
		my $interface = $self->{'INTERFACE'} || "";
		my $address = $self->{'ADDRESS'} || "";
		my $netmask = $self->{'NETMASK'} || "";
	        my $state = $self->{'STATE'} || "";
	        my $metric = $self->{'METRIC'} || "";
	        my $type = $self->{'TYPE'} || "";
		my $flag = $self->{'FLAG'};
		
		my (%acmd, @flag, @param);
		
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

		if ($state) {	
		        push @param, "$state";
		}
		if ($type) {	
			push @param, "$type";
		}
		if ($address) {	
			push @param, "$address";
		}
		if ($netmask) {	
		        push @param, "$netmask";
		}
		if ($interface) {	
		        push @param, "$interface";
		}
		if ($metric) {	
		        push @param, "$metric";
		}
		$acmd{'CMD'} = "route";
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}
		my $cmd = $self->amin_command(\%acmd);
		if ($cmd->{TYPE} eq "error") {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Could not set $type route to $address. Reason: $cmd->{ERR}";
			$default = 1;
			$log->error_message($text);
			if ($cmd->{ERR}) {
			    $log->ERR_message($cmd->{ERR});
			}
		}
		if (($cmd->{TYPE} eq "out") || ($cmd->{TYPE} eq "both")) {
			my $Otext = "New $type route created to $address with netmask of $netmask.";
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
		$self->{TYPE} = undef;
		$self->{METRIC} = undef;
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

sub type {
        my $self = shift;
        $self->{TYPE} = shift if @_;
        return $self->{TYPE};
}

sub metric {                                                                                                     
            my $self = shift;                                                                                      
            $self->{METRIC} = shift if @_;                                                                          
            return $self->{METRIC};                                                                                 
    }

sub version {
	return "1.0";
}

1;

=head1 NAME

ROUTE - util show / manipulate the IP routing table

=head1 version

route 1.98 (2001-04-15)

=head1 DESCRIPTION

  A reader class for the route command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="route">
                <amin:param name="state">add</amin:param>
                <amin:param name="type">default gw</amin:param>
                <amin:param name="address">192.168.0.1</amin:param>
                <amin:param name="netmask">0.0.0.0</amin:param>
                <amin:param name="metric">1</amin:param>
        </amin:command>

        <amin:command name="route">
                <amin:param name="state">del</amin:param>
                <amin:param name="type">default</amin:param>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="route">
                <amin:param name="state">add</amin:param>
                <amin:param name="type">default gw</amin:param>
                <amin:param name="address">192.168.0.1</amin:param>
                <amin:param name="netmask">0.0.0.0</amin:param>
                <amin:param name="metric">1</amin:param>
        </amin:command>

        <amin:command name="route">
                <amin:param name="state">del</amin:param>
                <amin:param name="type">default</amin:param>
        </amin:command>
        <amin:command name="route">
                <amin:param name="state">add</amin:param>
                <amin:param name="type">default gw</amin:param>
                <amin:param name="address">192.168.0.2</amin:param>
                <amin:param name="netmask">0.0.0.0</amin:param>
                <amin:param name="metric">1</amin:param>
        </amin:command>

        <amin:command name="route">
                <amin:param name="state">del</amin:param>
                <amin:param name="type">default</amin:param>
        </amin:command>
 </amin:profile>

=back  

=cut

