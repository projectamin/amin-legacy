package Amin::Machine::AdminList;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);

my %attrs;
my (%adminlist, $x, $y, $z);


sub start_element {
	my ($self, $element) = @_;
	$self->element($element);
	%attrs = %{$element->{Attributes}};
	if ($attrs{'{}name'}->{Value}) {
		$self->name($attrs{'{}name'}->{Value});
	}
	$self->attrs(%attrs);
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	my $element = $self->{"ELEMENT"};
	$data = $self->fix_text($data);
	
	if ($element->{LocalName} eq "uri") {
		if ($data ne "") {
			$self->uri($data);
		}
	}
}

sub end_element {
	my ($self, $element) = @_;
	if ($element->{LocalName} eq "server") {
		#don't add empty/bad uris
		if ($self->uri) {
			$x++;
			my $name;
			if ($self->name) {
				$name = $self->name;
			} else {
				$name = "server$x";
			}
			$adminlist{$name} = $self->uri;
			#reset stuff
			$self->{URI} = "";
			$self->{NAME} = "";
			$self->{TYPE} = "map";
		}
	}
	if ($element->{LocalName} eq "profile") {
		#don't add empty/bad uris
		if ($self->uri) {
			$y++;
			my $name;
			if ($self->name) {
				$name = $self->name;
			} else {
				$name = "profile$y";
			}
			$adminlist{$name} = $self->uri;
			#reset stuff
			$self->{URI} = "";
			$self->{NAME} = "";
			$self->{TYPE} = "profile";
		}
	}
	if ($element->{LocalName} eq "adminlist") {
		#catch the root adminlist or some empty
		#adminlist
		if ($self->uri) {
			$z++;
			my $name;
			if ($self->name) {
				$name = $self->name;
			} else {
				$name = "adminlist$z";
			}
			$adminlist{$name} = $self->uri;
			#reset stuff
			$self->{URI} = "";
			$self->{NAME} = "";
			$self->{TYPE} = "adminlist";
		}
	}
}

sub end_document {
	my $self = shift;
	return \%adminlist;
}

sub start_document {
	my $self = shift;

	$x = 0;
	$y = 0;
	$z = 0;
	%adminlist = ();	
}



sub uri {
	my $self = shift;
	$self->{URI} = shift if @_;
	return $self->{URI};
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