package Amin::Machine::NetworkMap;

use strict;
use vars qw(@ISA);
use XML::SAX::Base;
use Amin::Elt;

@ISA = qw(XML::SAX::Base Amin::Elt);

my (%maps, %attrs);

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

	if ($element->{LocalName} eq "ip") {
		if ($data ne "") {
			$self->ip($data);
		}
	}

	if ($element->{LocalName} eq "port") {
		if ($data ne "") {
			$self->port($data);
		}
	}
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "server") {
		my %server;
		$server{name} = $self->name;
		$server{ip} = $self->ip;
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
	%maps = undef;
	%attrs = {};
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

1;