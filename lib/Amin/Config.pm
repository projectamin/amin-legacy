package Apackage::Config;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://adistro.com
use strict;
use vars qw(@ISA);
use XML::SAX::Base;

@ISA = qw(XML::SAX::Base);
my %config;

sub start_element {
    my ($self, $element) = @_;
    my %attrs = %{$element->{Attributes}};
    $self->element($element);
    if ($element->{LocalName} eq "uri") {
        $self->name($attrs{'{}name'}->{Value});
    }
}

sub characters {
    my ($self, $chars) = @_;
    my $data = $chars->{Data};
    my $element = $self->{"ELEMENT"};
    if ($element->{LocalName} eq "uri") {
        $self->uri($data);
    }
}

sub end_element {
    my ($self, $element) = @_;
    if ($element->{LocalName} eq "uri") {
        my %hash;
        $hash{name} = $self->name;
        $hash{uri} = $self->uri;
        $config{$self->name} = \%hash;
    }
}

sub end_document {
    my $self = shift;
    return \%config;
}

sub element {
    my $self = shift;
    $self->{ELEMENT} = shift if @_;
    return $self->{ELEMENT};
}

sub name {
    my $self = shift;
    $self->{NAME} = shift if @_;
    return $self->{NAME};
}

sub uri {
    my $self = shift;
    $self->{URI} = shift if @_;
    return $self->{URI};
}


=head1 Name

Amin::Config - simple config.xml reader

=head1 Description

This SAX Filter will read a configuration file. This
file looks like

  <config>
     <uri name="apache">http://adistro.com/apan/apache.xml</uri>
  </config>

and will return a hash reference that looks like

    $config = {
        apache => {
            uri => http://adistro.com/apan/apache.xml,
            name => apache,
        }
    };
    
=head1 Methods 

=over 4

=item none

Amin::Config has no methods as it is a SAX filter and the methods 
are SAX methods not methods you call directly.
   
=back

=cut








1;