package Amin::Machine::NetworkMap;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use vars qw(@ISA);
use Amin::Elt;
use Amin::Protocol::Standard;

@ISA = qw(Amin::Elt);

my (%maps, %attrs);

sub start_document {
	my $self = shift;
	%maps = {};
	%attrs = {};
}

sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	if ($element->{LocalName} eq "server") {
		$self->name($attrs{'{}name'}->{Value});
	}
	$self->element($element);
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	my $element = $self->{"ELEMENT"};
	$data = $self->fix_text($data);

	if ($data ne "") {
		if ($element->{LocalName} eq "ip") {
			$self->ip($data);
		}
		if ($element->{LocalName} eq "auth") {
			$self->auth($data);
		}
		if ($element->{LocalName} eq "protocol") {
			$self->protocol($data);
		}
		if ($element->{LocalName} eq "port") {
			$self->port($data);
		}
		if ($element->{LocalName} eq "user") {
			$self->user($data);
		}
		if ($element->{LocalName} eq "key") {
			$self->key($data);
		}
		if ($element->{LocalName} eq "password") {
			$self->password($data);
		}
	}
}

sub end_element {
	my ($self, $element) = @_;
	

	if ($element->{LocalName} eq "server") {
		
		#get/load the protocol
		my $protocol;
		if ($self->protocol) {
			#load the protocol
			$protocol = $self->protocol;
			eval "require $protocol"; 
			if ($@) {
				die "Protocol loading failed. Reason $@";
			}				
			$protocol = $protocol->new();
		} else {
			#load the standard protocol
			$protocol = Amin::Protocol::Standard->new();
		}
		
		#get/load the auth module
		my $auth;
		if ($self->auth) {
			#load the auth
			eval "require $self->auth;"; 
			if ($@) {
				my $log = $self->{Spec}->{Log};
				$self->{Spec}->{amin_error} = "red";
				my $text = "Auth loading failed. Reason $@";
				$log->error_message($text);
			}				
			$auth = $self->auth->new();
		}
		
		my %server;
		$server{name} = $self->name;
		$server{ip} = $self->ip;
		$server{protocol} = $protocol;
		$server{'user'} = $self->user;
		$server{'key'} = $self->key;
		$server{'password'} = $self->password;
		if ($self->auth) {
			$server{auth} = $auth;
		}
		$server{port} = $self->port;
		$maps{$server{name}} = \%server;
	}
}

sub end_document {
	my $self = shift;
	return \%maps;
}

sub start_document {
	my $self = shift;
	%maps = ();
	%attrs = ();
}

sub element {
	my $self = shift;
	$self->{ELEMENT} = shift if @_;
	return $self->{ELEMENT};
}

sub ip {
	my $self = shift;
	$self->{IP} = shift if @_;
	return $self->{IP};
}

sub auth {
	my $self = shift;
	$self->{AUTH} = shift if @_;
	return $self->{AUTH};
}

sub protocol {
	my $self = shift;
	$self->{PROTOCOL} = shift if @_;
	return $self->{PROTOCOL};
}

sub name {
	my $self = shift;
	$self->{NAME} = shift if @_;
	return $self->{NAME};
}

sub port {
	my $self = shift;
	$self->{PORT} = shift if @_;
	return $self->{PORT};
}

sub user {
	my $self = shift;
	$self->{USER} = shift if @_;
	return $self->{USER};
}

sub password {
	my $self = shift;
	$self->{PASSWORD} = shift if @_;
	return $self->{PASSWORD};
}

sub key {
	my $self = shift;
	$self->{KEY} = shift if @_;
	return $self->{KEY};
}



1;


=head1 NAME

NetworkMap - reader class filter for NetworkMaps

=head1 Example

  use Sort::Naturally; #optional see below
  use Amin::Machine::NetworkMap;
  use XML::SAX::PurePerl;
  
  #this nsort will sort the $adminlist by default as
  #profile1, profile2, etc and then server1, server2
  foreach my $key (nsort keys %$adminlist) {
    if ($key =~ m/server/) {
      #process this networkmap
      my $h = Amin::Machine::NetworkMap->new();
      my $p = XML::SAX::PurePerl->new(Handler => $h);
      my $networkmap = $p->parse_uri($adminlist->{$key});
      #now do something with it
      foreach (keys %$networkmap) {
    	#do something with $networkmap->{$_} here
      }


=head1 DESCRIPTION

This module will read Amin network maps and return 
a simple hash that is keyed on the <server name=""> 
attributes. So in the example 

$networkmap->{$_} would be jerry 

$networkmap->{$_}->{port} is 8000 

and so on. 
  
=head1 XML

=over 4

=item Full example

 <amin:networkmap xmlns:amin="http://projectamin.org/ns/">
   <amin:server name="jerry">
     <amin:ip>192.168.1.1</amin:ip>
     <amin:port>8000</amin:port>
   </amin:server>
     <!--and so on -->
 </amin:networkmap>


=back  

=cut