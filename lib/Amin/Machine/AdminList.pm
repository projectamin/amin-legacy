package Amin::Machine::AdminList;

use strict;
use vars qw(@ISA);
use XML::SAX::Base;
use Amin::Elt;

@ISA = qw(XML::SAX::Base Amin::Elt);

my (%networkmap, $x);
my %attrs;

sub start_element {
	my ($self, $element) = @_;
	$self->element($element);
	%attrs = %{$element->{Attributes}};
	$self->attrs(%attrs);
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	my $element = $self->{"ELEMENT"};
	$data = $self->fix_text($data);
	my $attrs = $self->{"ATTRS"};
	my $element = $self->{"ELEMENT"};
	if ($attrs{'{}name'}->{Value} eq "name") {
		if ($data ne "") {
			$self->name($data);
		}
	}
	if ($element->{LocalName} eq "FullPath") {
		if ($data ne "") {
			$self->fullpath($data);
		}
	}

}

sub end_element {
	my ($self, $element) = @_;
	if ($element->{LocalName} eq "server") {
		$x++;
		my $name;
		if ($self->name) {
			$name = $self->name;
		} else {
			$name = "server$x";
		}
		$networkmap{$name} = $self->fullpath;
		#reset stuff
		$self->{FULLPATH} = "";
		$self->{NAME} = "";
	}
	if ($element->{LocalName} eq "profile") {
		$x++;
		my $name;
		if ($self->name) {
			$name = $self->name;
		} else {
			$name = "profile$x";
		}
		$networkmap{$name} = $self->fullpath;
		#reset stuff
		$self->{FULLPATH} = "";
		$self->{NAME} = "";
	}
}

sub end_document {
	my $self = shift;
	return \%networkmap;
}

sub start_document {
	my $self = shift;
	#reset some stuff
	%networkmap = {};
	$x = 0;
}

sub fullpath {
	my $self = shift;
	$self->{FULLPATH} = shift if @_;
	return $self->{FULLPATH};
}

sub name {
	my $self = shift;
	$self->{NAME} = shift if @_;
	return $self->{NAME};
}

=head1 NAME

AdminList - reader class filter for AdminLists

=head1 Example

  use Sort::Naturally; #optional see below
  use Amin::Machine::Adminlist;
  use XML::SAX::PurePerl;
  
  my $uri = "http://someurihere/to/adminlist.xml";
  
  my $h = Amin::Machine::Adminlist->new();
  my $p = XML::SAX::PurePerl->new(Handler => $h);
  my $adminlist = $p->parse_uri($uri);
  
  #example way to sort default adminlist index
  #see name="" optional xml below for other indexing ideas
  
  #this nsort will sort the $adminmap by default as
  #profile1, profile2, etc and then server1, server2
  foreach my $key (nsort keys %$adminlist) {
    if ($key =~ /profile/) {
    	#do something with $adminlist{$key} here
    }
  }
  
=head1 DESCRIPTION

  This is a reader class for an Amin AdminList. By default the 
  results returned will be a hash that is indexed by profile# or
  server#. # is the order this particular profile/server element
  appears in the adminlist from a read order of top/down.
   
  name="" is optional and if supplied, the adminlist will be 
  indexed by the values in name="". Each name="" must be unique, 
  or it will be clobbered by the next similiar name="". Profile/server
  elements with no name="" in the same adminlist with name="something" 
  elements will still receive the default profile# or server# indexes.
  
=head1 XML

=over 4

=item Full example

 <amin:adminlist xmlns:amin="http://projectamin.org/ns/">
   <amin:profile name="myskuid3">
     <amin:uri>http://projectamin.org/apan/adminlist/fake.xml</amin:uri>
   </amin:profile>
   <amin:server name="my_box">
     <amin:uri>http://projectamin.org/apan/networkmap/local.xml</amin:uri>
   </amin:server>
 </amin:adminlist>

=item Profile

  <amin:profile name="myskuid3">
    <amin:uri>http://projectamin.org/apan/adminlist/fake.xml</amin:uri>
  </amin:profile>

  <amin:uri> is mandatory
  
  name="myskuid3" is optional. 

=item Server

  <amin:server name="my_box">
    <amin:uri>http://projectamin.org/apan/networkmap/local.xml</amin:uri>
  </amin:server>
  
  <amin:uri> is mandatory
  
  name="my_box" is optional

=back  

=cut

1;