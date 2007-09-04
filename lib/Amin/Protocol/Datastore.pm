package Amin::Protocol::Datastore;


use strict;
use vars qw(@ISA);
use XML::SAX::Base;

@ISA = qw(XML::SAX::Base);
my %datastore;

sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};
	$self->element($element);
	if ($element->{LocalName} eq "profile") {
		$self->uri($attrs{'{}name'}->{Value});
		$self->type("profile");
	}
	if ($element->{LocalName} eq "networkmap") {
		$self->uri($attrs{'{}name'}->{Value});
		$self->type("networkmap");
	}
	if ($element->{LocalName} eq "adminlist") {
		$self->uri($attrs{'{}name'}->{Value});
		$self->type("adminlist");
	}
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	my $element = $self->{"ELEMENT"};
	if ($element->{LocalName} eq "checksum") {
		$self->checksum($data);
	}
}

sub end_element {
	my ($self, $element) = @_;
	if ($element->{LocalName} eq "profile") {
		my %hash;
		$hash{checksum} = $self->checksum;
		$hash{uri} = $self->uri;
		$hash{type} = "profile";
		$datastore{$self->name} = \%hash;
		
	}
	if ($element->{LocalName} eq "networkmap") {
		my %hash;
		$hash{checksum} = $self->checksum;
		$hash{uri} = $self->uri;
		$hash{type} = "networkmap";
		$datastore{$self->name} = \%hash;
		
	}
	if ($element->{LocalName} eq "adminlist") {
		my %hash;
		$hash{checksum} = $self->checksum;
		$hash{uri} = $self->uri;
		$hash{type} = "adminlist";
		$datastore{$self->name} = \%hash;
		
	}
}

sub end_document {
	my $self = shift;
	return \%datastore;
}

sub element {
	my $self = shift;
	$self->{ELEMENT} = shift if @_;
	return $self->{ELEMENT};
}

sub checksum {
	my $self = shift;
	$self->{CHECKSUM} = shift if @_;
	return $self->{CHECKSUM};
}

sub uri {
	my $self = shift;
	$self->{URI} = shift if @_;
	return $self->{URI};
}

sub type {
	my $self = shift;
	$self->{TYPE} = shift if @_;
	return $self->{TYPE};
}


=head1 Name

Amin::Protocol::Datastore - simple datastore for checksums

=head1 Example

soon

=head1 Description

This SAX Filter will read an ainit networkmap datastore file. 
This file looks like

  <datastore>
     <profile uri="http://adistro.com/apan/profile.xml">   
	<checksum>mfewkfewtjwerj3werjtkwerjk</checksum>
     </profile>	
     <networkmap uri="http://adistro.com/apan/networkmap.xml">   
	<checksum>bncvcxnbvmxnmxcnmvhe32322</checksum>
     </networkmap>	
     <adminlist uri="http://adistro.com/apan/adminlist.xml">   
	<checksum>eiro3ir30-493943io2dsnxjsd8=sss</checksum>
     </adminlist>	
  </datastore>

and will return a hash reference that looks like


	$datastore = {
		http://adistro.com/apan/apache.xml => {
			uri => http://adistro.com/apan/profile.xml,
			checksum => mfewkfewtjwerj3werjtkwerjk,
			type => profile
		}
		http://adistro.com/apan/networkmap.xml => {
			uri => http://adistro.com/apan/networkmap.xml,
			checksum => bncvcxnbvmxnmxcnmvhe32322,
			type => networkmap
		}
		http://adistro.com/apan/adminlist.xml => {
			uri => http://adistro.com/apan/adminlist.xml,
			checksum => eiro3ir30-493943io2dsnxjsd8=sss,
			type => adminlist
	};
	
=head1 Methods 

=over 4

=item none

Amin::Protocol::Datastore has no methods as it is a SAX filter and
the methods are SAX methods not methods you call directly.
   
=back

=cut

1;