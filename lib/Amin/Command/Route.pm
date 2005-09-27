package Amin::Command::Route;

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
	
	if ($attrs{'{}name'}->{Value} eq "env") {
		if ($data ne "") {
			$self->env_vars($data);
		}
	}
	if ($element->{LocalName} eq "flag") {
		if ($attrs{'{}name'}->{Value} eq "") {
			if ($data ne "") {
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

	if ($element->{LocalName} eq "command") {

		my $interface = $self->{'INTERFACE'};
		my $address = $self->{'ADDRESS'};
		my $netmask = $self->{'NETMASK'};
	        my $state = $self->{'STATE'};
	        my $metric = $self->{'METRIC'};
	        my $type = $self->{'TYPE'};
		my $flag = $self->{'FLAG'};
		
		my (%acmd, @flag, @param);
		
		my $log = $self->{Spec}->{Log};
	
	        push @param, "$state";
		push @param, "$type";
		push @param, "$address";
	        push @param, "$netmask";
	        push @param, "$interface";
	        push @param, "$metric";

		$acmd{'CMD'} = "route";
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}
		my $cmd = $self->amin_command(\%acmd);
	        die Dumper(@param);
		if ($cmd->{STATUS} != 1) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Could not set $type route to $address. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
			    $log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "New $type route created to $address with netmask of $netmask.";
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

1;

=head1 NAME

ROUTE - utility to show / manipulate the IP routing table

=head1 version

route 1.98 (2001-04-15)

=head1 DESCRIPTION

  A reader class for the route command. 
  
=head1 XML

=over 4

=item Full example

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

=back  

=cut

