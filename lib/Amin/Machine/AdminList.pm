package Amin::Machine::Adminlist;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use vars qw(@ISA);
use Amin::Elt;
use Sort::Naturally;
@ISA = qw(Amin::Elt);

sub start_document {
	my $self = shift;
    my $adminlist = $self->adminlist;
	foreach (keys %$adminlist) {
		delete $adminlist->{$_};
	}
    #load up our names
    my @names = qw(uri name);
    $self->doc_name(\@names);
    #load up our types
    my @types = qw(networkmap profile adminlist);
    $self->doc_type(\@types);
}

sub start_element {
	my ($self, $element) = @_;
	$self->element($element);
    my %attrs = %{$element->{Attributes}};
    $self->attrs(\%attrs);
    my $names = $self->element_name;    
    foreach my $name (@$names) {
        my $value = "{}" . $name;
        if ($attrs{$value}->{Value}) {
            $self->$name($attrs{$value}->{Value});
        }
    }
}

sub end_element {
	my ($self, $element) = @_;
    my $vars = $self->doc_var;
    my $types = $self->doc_type;
    my $x = $self->get_x;
    foreach my $type (@$types) {
        if ($element->{LocalName} eq $type) {
            $x++;
            my $adminlist = $self->adminlist;
            my $name;
            if ($self->name) {
                $name = $self->name;
            } else {
                $name = $type . $x;
            }
            $self->get_x($x);
            my %hash;
            $hash{uri} = $self->uri;
            $hash{name} = $name;
            $hash{type} = $type;
            $adminlist->{$name} = \%hash;
            $self->adminlist($adminlist);
            #reset stuff
            $self->{URI} = undef;
            $self->{NAME} = undef;
            $self->{TYPE} = undef;
        }
	}
}

sub end_document {
	my $self = shift;
	return $self->adminlist;
}

sub get_x {
    my $self = shift;
    $self->{X} = shift if @_;
    if ($self->{X}) {
        return $self->{X};
    } else {
        #initial x
        my $x = 0;
        return $x;
    }
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

sub adminlist {
    my $self = shift;
    if (@_) {
        $self->{ADMINLIST} = shift;
    } elsif (! $self->{ADMINLIST}) {
        $self->{ADMINLIST} = {};
    }
    return $self->{ADMINLIST};
}

sub get_adminlists {
    my ($self, $profiles, $adminlists, $networkmap, $map) = @_;
    foreach (@$adminlists) {
        my $adminlist = $self->parse_adminlist($_);
        foreach my $key (nsort keys %$adminlist) {
            if (defined $map) {
                if ($adminlist->{$key}->{'name'} eq $key) {
                    if ($adminlist->{$key}->{'type'} eq "map") {
                        $networkmap = $self->parse_networkmap($adminlist->{$key}->{uri});
                    } elsif ($adminlist->{$key}->{'type'} eq "profile") {
                        push @$profiles, $adminlist->{$key}->{uri};
                    } elsif ($adminlist->{$key}->{'type'} eq "adminlist") {
                        push @$adminlists, $adminlist->{$key}->{uri};
                    }
                }
            } else {
                if ($adminlist->{$key}->{'name'} eq $key) {
                    if ($adminlist->{$key}->{type} eq "map") {
                        $networkmap = $self->parse_networkmap($adminlist->{$key}->{uri});
                    } elsif ($adminlist->{$key}->{type} eq "profile") {
                        push @$profiles, $adminlist->{$key}->{uri};
                    } elsif ($adminlist->{$key}->{type} eq "adminlist") {
                        push @$adminlists, $adminlist->{$key}->{uri};
                    }
                }
            }

        }
    }
    return $profiles, $networkmap;
}

sub get_types {
    my ($self, $types, $adminlist, $key) = @_;
    my ($networkmap, @profiles, @adminlists);
    foreach my $key (nsort keys %$adminlist) {
        #this is a mapping
        if (defined $adminlist->{$key}->{name} eq $key) {
            if ($adminlist->{$key}->{name} eq $key) {
                foreach my $type (@$types) {
                    if ($adminlist->{$key}->{type} eq $type) {
                        if ($type eq "map") {
                            $networkmap = $self->parse_networkmap($adminlist->{$key}->{uri});
                        } elsif ($type eq "profile") {
                            push @profiles, $adminlist->{$key}->{uri};
                        } elsif ($type eq "adminlist") {
                            push @adminlists, $adminlist->{$key}->{uri};
                        }
                    }
                }
            }
        } else {
            foreach my $type (@$types) {
                if ($adminlist->{$key}->{type} eq $type) {
                    if ($type eq "map") {
                        $networkmap = $self->parse_networkmap($adminlist->{$key}->{uri});
                    } elsif ($type eq "profile") {
                        push @profiles, $adminlist->{$key}->{uri};
                    } elsif ($type eq "adminlist") {
                        push @adminlists, $adminlist->{$key}->{uri};
                    }
                }
            }
        }
    }
    return \@profiles, \@adminlists, $networkmap;
}

=head1 NAME

AdminList - reader class filter for adminlists with additional 
            adminlist processing methods

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
  results returned will be a hash that is indexed by profile # or
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
   <amin:profile name="myskuid3" uri="http://projectamin.org/apan/adminlist/fake.xml" />
   <amin:networkmap name="my_box" uri="http://projectamin.org/apan/networkmap/local.xml" />
 </amin:adminlist>

=item Profile

  <amin:profile name="myskuid3" uri="http://projectamin.org/apan/adminlist/fake.xml" />

  uri="uri://" is mandatory
  
  name="myskuid3" is optional. 

=item networkmap

  <amin:networkmap name="my_box" uri="http://projectamin.org/apan/networkmap/local.xml" />
  
  uri="uri://" is mandatory
  
  name="my_box" is optional

=back  

=cut

1;