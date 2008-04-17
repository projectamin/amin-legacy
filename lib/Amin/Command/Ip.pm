package Amin::Command::Ip;

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
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "iptables")) {
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
	if (($command eq "iptables") && ($data ne "")) {
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "action") {
		        	$self->action($data);
			}
		}
		if ($element->{LocalName} eq "flag") {
			if ($attrs{'{}name'}->{Value} eq "base") {
				$self->base($data);
			}
			if ($attrs{'{}name'}->{Value} eq "burst") {
			        $self->burst($data);
    			}
    			if ($attrs{'{}name'}->{Value} eq "source") {
    				$self->source($data);
    			}
    			if ($attrs{'{}name'}->{Value} eq "destination") {
    	        		$self->destination($data);
  			}
   			if ($attrs{'{}name'}->{Value} eq "append") {
            			$self->append($data);
    			}
    			if ($attrs{'{}name'}->{Value} eq "chain") {
        			$self->chain($data);
			}
			if ($attrs{'{}name'}->{Value} eq "to") {
        			$self->to($data);
    			}
     			if ($attrs{'{}name'}->{Value} eq "inface") {
      				$self->inface($data);
    			}
    			if ($attrs{'{}name'}->{Value} eq "outface") {
            			$self->outface($data);
    			}
    			if ($attrs{'{}name'}->{Value} eq "protocol") {
            			$self->protocol($data);
    			}
    			if ($attrs{'{}name'}->{Value} eq "dport") {
            			$self->dport($data);
    			}
    			if ($attrs{'{}name'}->{Value} eq "string") {
            			$self->string($data);
    			}
   			if ($attrs{'{}name'}->{Value} eq "sport") {
            			$self->sport($data);
    			}
    			if ($attrs{'{}name'}->{Value} eq "tcpflags") {
            			$self->tcpflags($data);
    			}
    			if ($attrs{'{}name'}->{Value} eq "jump") {
            			$self->jump($data);
    			}
    			if ($attrs{'{}name'}->{Value} eq "rule") {
            			$self->rule($data);
    			}
    			if ($attrs{'{}name'}->{Value} eq "state") {
    			        $self->state($data);
    			}
    			if ($attrs{'{}name'}->{Value} eq "level") {
    			        $self->level($data);
    			}
    			if ($attrs{'{}name'}->{Value} eq "prefix") {
            			$self->prefix($data);
    			}
		}
	}
}

sub end_element {
	my ($self, $element) = @_;

	if (($element->{LocalName} eq "command") && ($self->command eq "iptables")) {
		my $action = $self->{'ACTION'} || "";
		my $base = $self->{'BASE'} || "";
		my $burst = $self->{'BURST'} || "";
		my $source = $self->{'SOURCE'} || "";
		my $destination = $self->{'DESTINATION'} || "";
		my $append = $self->{'APPEND'} || "";
		my $chain = $self->{'CHAIN'} || "";
		my $to = $self->{'TO'} || "";
		my $inface = $self->{'INFACE'} || "";
		my $dport = $self->{'DPORT'} || "";
		my $sport = $self->{'SPORT'} || "";
		my $state = $self->{'STATE'} || "";
		my $string = $self->{'STRING'} || "";
		my $tcpflags = $self->{'TCPFLAGS'} || "";
		my $jump = $self->{'JUMP'} || "";
		my $rule = $self->{'RULE'} || "";
		my $level = $self->{'LEVEL'} || "";
		my $prefix = $self->{'PREFIX'} || "";
		my $protocol = $self->{'PROTOCOL'} || "";
		my $outface = $self->{'OUTFACE'} || "";
		my $log = $self->{Spec}->{Log} || "";

		my $command = "iptables";
		my (@flag, @param);
		if ($action ne "") {
			if ( $action eq "add" ) {
				push @flag, "-A";
			}
			if ( $action eq "del" ) {
				push @flag, "-D";
			}
			if ( $action eq "new" ) {
				push @flag, "-N";
			}
			if ( $action eq "insert" ) {
				push @flag, "-I";
			}
			if ( $action eq "type" ) {
				push @flag, "-t";
			}
			if ( $action eq "list" ) {
				push @flag, "-L";
			}
			if ( $action eq "flush" ) {
				push @flag, "-F";
			}
			if ( $action eq "delchain" ) {
				push @flag, "-X";
			}
			if ( $action eq "zero" ) {
				push @flag, "-Z";
			}
			if ( $action eq "replace" ) {
				push @flag, "-R";
			}
			#add the chain
			push @flag, $chain;

		}
		if ( $append ne "") {
			if ( $action eq "type" ) {
				push @flag, "-A";
				push @flag, $append;
			}
		}
		if ( $inface ne "") {
			push @flag, "-i";
			push @flag, $inface;
		}
		if ( $outface ne "" ) {
			push @flag, "-o";
			push @flag, $outface;
		}
		if ( $source ne "" ) {
			push @flag, "-s";
			push @flag, $source;
		}
		if ( $destination ne "" ) {
			push @flag, "-d";
			push @flag, $destination;
		}
		if ( $protocol ne "" ) {
			push @flag, "-p";
			push @flag, $protocol;
			if ( $sport ne "" ) {
				push @flag, "--sport";
				push @flag, $sport;
			}
			if ( $dport ne "" ) {
				push @flag, "--dport";
				push @flag, $dport;
			}
			if ( $protocol eq "tcp" and $tcpflags ne "" ) {
				push @flag, "--tcp-flags";
				my ($one, $two) = split (/ /,$tcpflags);
				push @flag, $one;
				push @flag, $two;
			}
		}
		if ( $state ne "") {
			push @flag, "-m";
			if ( $string ne "" ) {
				push @flag, "string";
				push @flag, "--string";
				push @flag, $string;
			}
			if ( $state eq "limit" ) {
				push @flag, "limit";
				if ( $base ne "" ) {
					push @flag, "--limit";
					push @flag, $base;
				}
				if ( $burst ne "" ) {
					push @flag, "--limit-burst";
					push @flag, $burst;
				}
			}
		}
		if ( $jump ne "") {
			push @flag, "-j";
			push @flag, $jump;
			if ( $jump eq "LOG" ) {
				if ( $level ne "" ) {
					push @flag, "--log-level";
					push @flag, $level;
				}
				if ( $prefix ne "" ) {
					push @flag, "--log-prefix";
					push @flag, $prefix;
				}
			}
		}
		if ( $to ne "" ) {
			if ( $jump eq "DNAT" or "SNAT" and $jump ne "REDIRECT" ) {
				push @flag, "--to";
				push @flag, $to;
			}
			if ( $jump eq "REDIRECT" ) {
				push @flag, "--to-port";
				push @flag, $to;
			}
		}

		if ( $rule ne "" ) {
			if ( $action eq "del" or "insert" ) {
				push @param, $rule;
			}
		}

		my %acmd;
		$acmd{'CMD'} = $command;
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		
		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}
		
		my $cmd = $self->amin_command(\%acmd);
		my $default = "0"; #setup the default msg flag

		if ($cmd->{TYPE} eq "error") {
			$self->{Spec}->{amin_error} = "red";
                	my $text = "Unable to execute $command. Reason: $cmd->{ERR}";
			$default = 1;
                        $log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
                }

		if (($cmd->{TYPE} eq "out") || ($cmd->{TYPE} eq "both")) {
			my $otext = "Executing $command";
			my $etext;
			if ($cmd->{ERR}) {
				$etext = " There was also some error text $cmd->{ERR}";
				$etext = $otext . $etext; 
			}
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
		$self->{ACTION} = undef;
		$self->{APPEND} = undef;
		$self->{BASE} = undef;
		$self->{BURST} = undef;
		$self->{SOURCE} = undef;
		$self->{STATE} = undef;
		$self->{STRING} = undef;
		$self->{DESTINATION} = undef;
		$self->{CHAIN} = undef;
		$self->{TO} = undef;
		$self->{INFACE} = undef;
		$self->{OUTFACE} = undef;
		$self->{LEVEL} = undef;
		$self->{PREFIX} = undef;
		$self->{PROTOCOL} = undef;
		$self->{SPORT} = undef;
		$self->{TCPFLAGS} = undef;
		$self->{DPORT} = undef;
		$self->{JUMP} = undef;
		$self->{RULE} = undef;
                $self->SUPER::end_element($element);
        } else {
                $self->SUPER::end_element($element);
	}
}

sub action {
	my $self = shift;
	$self->{ACTION} = shift if @_; 
	return $self->{ACTION};
}
sub append {
	my $self = shift;
	$self->{APPEND} = shift if @_; 
	return $self->{APPEND};
}
sub base {
	my $self = shift;
	$self->{BASE} = shift if @_; 
	return $self->{BASE};
}
sub burst {
	my $self = shift;
	$self->{BURST} = shift if @_; 
	return $self->{BURST};
}
sub source {
	my $self = shift;
	$self->{SOURCE} = shift if @_; 
	return $self->{SOURCE};
}
sub state {
	my $self = shift;
	$self->{STATE} = shift if @_; 
	return $self->{STATE};
}
sub string {
	my $self = shift;
	$self->{STRING} = shift if @_; 
	return $self->{STRING};
}
sub destination {
	my $self = shift;
	$self->{DESTINATION} = shift if @_; 
	return $self->{DESTINATION};
}sub chain {
	my $self = shift;
	$self->{CHAIN} = shift if @_; 
	return $self->{CHAIN};
}
sub to {
	my $self = shift;
	$self->{TO} = shift if @_; 
	return $self->{TO};
}
sub inface {
	my $self = shift;
	$self->{INFACE} = shift if @_; 
	return $self->{INFACE};
}
sub outface {
	my $self = shift;
	$self->{OUTFACE} = shift if @_; 
	return $self->{OUTFACE};
}
sub level {
	my $self = shift;
	$self->{LEVEL} = shift if @_; 
	return $self->{LEVEL};
}
sub prefix {
	my $self = shift;
	$self->{PREFIX} = shift if @_; 
	return $self->{PREFIX};
}
sub protocol {
	my $self = shift;
	$self->{PROTOCOL} = shift if @_; 
	return $self->{PROTOCOL};
}
sub sport {
	my $self = shift;
	$self->{SPORT} = shift if @_; 
	return $self->{SPORT};
}
sub tcpflags {
	my $self = shift;
	$self->{TCPFLAGS} = shift if @_; 
	return $self->{TCPFLAGS};
}
sub dport {
	my $self = shift;
	$self->{DPORT} = shift if @_; 
	return $self->{DPORT};
}
sub jump {
	my $self = shift;
	$self->{JUMP} = shift if @_; 
	return $self->{JUMP};
}
sub rule {
	my $self = shift;
	$self->{RULE} = shift if @_; 
	return $self->{RULE};
}

sub version {
	return "1.0";
}

1;

=head1 NAME

Iptables - reader class filter for the iptables command.

=head1 version

iptables


=head1 DESCRIPTION

  A reader class for the iptables command. This command
  lets you specify all your iptable parameters. Who 
  needs a firewall script, when you have firewall profiles?
  This command has not been used as much as it should have
  been in the past, so we are reposting full examples, in 
  hope people will expand/use this command....
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
	
	<!-- Add a new rule to a already existing chain -->
    <amin:command name="iptables">
        <amin:param name="chain">INPUT</amin:param>
        <amin:flag name="action">add</amin:flag>
        <amin:param name="inface">ppp0</amin:param>
        <amin:param name="protocol">tcp</amin:param>
        <amin:param name="dport">80</amin:param>
        <amin:param name="jump">DROP</amin:param>
    </amin:command>

	<!-- Delete a rule from an already existing chain -->
    <amin:command name="iptables">
        <amin:param name="chain">INPUT</amin:param>
        <amin:flag name="action">del</amin:flag>
        <amin:param name="rule">1</amin:param>
    </amin:command>

	<!-- Insert a rule into an already existing chain -->
    <amin:command name="iptables">
        <amin:param name="chain">OUTPUT</amin:param>
        <amin:flag name="action">insert</amin:flag>
        <amin:param name="rule">1</amin:param>
    </amin:command>

	<!-- List all the rules of a given chain, if no chain is
     specified all chains are listed              -->
    <amin:command name="iptables">
        <amin:param name="chain">INPUT</amin:param>
        <amin:flag name="action">list</amin:flag>
    </amin:command>
    
	<!-- Flush all rules from a given chain, if no chain is
     specified then all rules from all chains are deleted -->
    <amin:command name="iptables">
        <amin:param name="chain">userdefined</amin:param>
        <amin:flag name="action">flush</amin:flag>
    </amin:command>

	<!-- Used for actions related to the kernel packet matching 
     tables. Used most commonly for NAT Network Address Translation -->

	<!-- Basic Masquerading -->
    <amin:command name="iptables">
        <amin:param name="chain">nat</amin:param>
        <amin:flag name="action">type</amin:flag>
        <amin:param name="append">POSTROUTING</amin:param>
        <amin:param name="outface">ppp0</amin:param>
        <amin:param name="jump">MASQUERADE</amin:param>
    </amin:command>

	<!-- Basic XMAS scan drop  -->
    <amin:command name="iptables">
        <amin:param name="chain">nat</amin:param>
        <amin:flag name="action">type</amin:flag>
        <amin:param name="append">PREROUTING</amin:param>
        <amin:param name="protocol">tcp</amin:param>
        <amin:param name="tcpflags">ALL ALL</amin:param>
        <amin:param name="jump">DROP</amin:param>
    </amin:command>

	<!-- Basic NULL scan drop  -->
    <amin:command name="iptables">
        <amin:param name="chain">nat</amin:param>
        <amin:flag name="action">type</amin:flag>
        <amin:param name="append">PREROUTING</amin:param>
        <amin:param name="protocol">tcp</amin:param>
        <amin:param name="tcpflags">ALL NONE</amin:param>
        <amin:param name="jump">DROP</amin:param>
    </amin:command>

	<!-- Destination NAT, changes the destination addy from example.com to
     192.168.0.100 port 80.  NB the port is optional  -->
    <amin:command name="iptables">
        <amin:param name="chain">nat</amin:param>
        <amin:flag name="action">type</amin:flag>
        <amin:param name="append">POSTROUTING</amin:param>
        <amin:param name="protocol">tcp</amin:param>
        <amin:param name="destination">example.com</amin:param>
        <amin:param name="dport">8080</amin:param>
        <amin:param name="jump">DNAT</amin:param>
        <amin:param name="to">192.168.0.100:80</amin:param>
    </amin:command>

	<!-- Port redirection, commonly used for tranparent proxy/cache -->
    <amin:command name="iptables">
        <amin:param name="chain">nat</amin:param>
        <amin:flag name="action">type</amin:flag>
        <amin:param name="append">PREROUTING</amin:param>
        <amin:param name="inface">eth1</amin:param>
        <amin:param name="protocol">tcp</amin:param>
        <amin:param name="dport">80</amin:param>
        <amin:param name="jump">REDIRECT</amin:param>
        <amin:param name="to">3128</amin:param>
    </amin:command>

	<!-- Stateful limits, using a SYN-FLOOD example  -->
    <amin:command name="iptables">
        <amin:param name="chain">nat</amin:param>
        <amin:flag name="action">type</amin:flag>
        <amin:param name="append">syn-flood</amin:param>
        <amin:param name="state">limit</amin:param>
        <amin:param name="base">12/s</amin:param>
        <amin:param name="burst">24</amin:param>
        <amin:param name="jump">RETURN</amin:param>
    </amin:command>

	<!-- filtering based on string matching   -->
    <amin:command name="iptables">
        <amin:param name="chain">filter</amin:param>
        <amin:flag name="action">type</amin:flag>
        <amin:param name="append">INPUT</amin:param>
        <amin:param name="inface">eth1</amin:param>
        <amin:param name="protocol">tcp</amin:param>
        <amin:param name="dport">80</amin:param>
        <amin:param name="state">string</amin:param>
        <amin:param name="string">/default.ida?</amin:param>
        <amin:param name="jump">DROP</amin:param>
    </amin:command>

	<!-- LOGing based on string matching   -->
    <amin:command name="iptables">
        <amin:param name="chain">filter</amin:param>
        <amin:flag name="action">type</amin:flag>
        <amin:param name="append">INPUT</amin:param>
        <amin:param name="inface">eth1</amin:param>
        <amin:param name="protocol">tcp</amin:param>
        <amin:param name="dport">80</amin:param>
        <amin:param name="state">string</amin:param>
        <amin:param name="string">/default.ida?</amin:param>
        <amin:param name="jump">LOG</amin:param>
        <amin:param name="level">1</amin:param>
        <amin:param name="prefix">HACKERS</amin:param>
    </amin:command>


	<!-- Creates a new chain for you to add rules too -->
    <amin:command name="iptables">
        <amin:param name="chain">FTP</amin:param>
        <amin:flag name="action">new</amin:flag>
    </amin:command>

	<!-- Deletes a chain you have created, there must be no references
     to the chain anywhere in the entire table   -->
    <amin:command name="iptables">
        <amin:param name="chain">FTP</amin:param>
        <amin:flag name="action">delchain</amin:flag>
    </amin:command>

	<!-- Zero's the packet and byte counters for all chains -->
    <amin:command name="iptables">
        <amin:param name="chain">INPUT</amin:param>
        <amin:flag name="action">zero</amin:flag>
    </amin:command>
 </amin:profile>
   
=back  

=cut

