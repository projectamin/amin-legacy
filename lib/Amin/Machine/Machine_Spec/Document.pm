package Amin::Machine::Machine_Spec::Document;

use strict;
use vars qw(@ISA);
use XML::SAX::Base;

@ISA = qw(XML::SAX::Base);

my %filter;
my @filters;
my @bundle;
my %filters;
my %bundle;

sub start_element {
	my ($self, $element) = @_;
	$self->element($element);
	my %attrs = %{$element->{Attributes}};
	if (($element->{LocalName} eq "filter") || ($element->{LocalName} eq "bundle")) {
		$self->module($attrs{'{}name'}->{Value});	
	}
}
sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	$data =~ s/(^\s+|\s+$)//gm;
	my $element = $self->{"ELEMENT"};

	if ($element->{LocalName} eq "element") {
		if ($data ne "") {
			$self->element_name($data);
		}
	}
	if ($element->{LocalName} eq "namespace") {
		if ($data ne "") {
			$self->namespace($data);
		}
	}
	if ($element->{LocalName} eq "name") {
		if ($data ne "") {
			$self->name($data);
		}
	}
	if ($element->{LocalName} eq "position") {
		if ($data ne "") {
			$self->position($data);
		}
	}
	if ($element->{LocalName} eq "download") {
		if ($data ne "") {
			$self->download($data);
		}
	}
	if ($element->{LocalName} eq "version") {
		if ($data ne "") {
			$self->version($data);
		}
	}
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "bundle") {	
		my %mparent = (
			element => $self->{ELEMENT_NAME},
			namespace => $self->{NAMESPACE},
			name => $self->{NAME},
			position => $self->{POSITION},
			download => $self->{DOWNLOAD},
			version => $self->{VERSION},
			module => $self->{MODULE},
		);
		$bundle{$mparent{module}} = \%mparent;
	}
	if ($element->{LocalName} eq "filter") {	
		my %mparent = (
			element => $self->{ELEMENT_NAME},
			namespace => $self->{NAMESPACE},
			name => $self->{NAME},
			position => $self->{POSITION},
			download => $self->{DOWNLOAD},
			version => $self->{VERSION},
			module => $self->{MODULE},
		);
		$filters{$mparent{module}} = \%mparent;
	}
	if ($element->{LocalName} eq "machine") {
		$filter{Filter} = \%filters;
		$filter{Bundle} = \%bundle;
	}
}

sub end_document {
	my $self = shift;
	return \%filter;
}

sub element {
	my $self = shift;
	$self->{ELEMENT} = shift if @_;
	return $self->{ELEMENT};
}

sub mparent {
	my $self = shift;
	if (@_) {push @{$self->{MPARENT}}, @_; }
	return @{ $self->{MPARENT} };
}

sub name {
	my $self = shift;
	$self->{NAME} = shift if @_;
	return $self->{NAME};
}

sub position {
	my $self = shift;
	$self->{POSITION} = shift if @_;
	return $self->{PSOITION};
}

sub namespace {
	my $self = shift;
	$self->{NAMESPACE} = shift if @_;
	return $self->{NAMESPACE};
}

sub download {
	my $self = shift;
	$self->{DOWNLOAD} = shift if @_;
	return $self->{DOWNLOAD};
}

sub element_name {
	my $self = shift;
	$self->{ELEMENT_NAME} = shift if @_;
	return $self->{ELEMENT_NAME};
}
		
sub module {
	my $self = shift;
	$self->{MODULE} = shift if @_;
	return $self->{MODULE};
}
		
sub version {
	my $self = shift;
	$self->{VERSION} = shift if @_;
	return $self->{VERSION};
}



=head1 NAME

Machine_Spec::Document - reader class filter for Machine_Spec Documents

=head1 Example

  use Amin::Machine::Machine_Spec::Document;
  use XML::SAX::PurePerl;

  my $h = Amin::Machine::Machine_Spec::Document->new();
  my $x = XML::Filter::XInclude->new(Handler => $h);
  my $p = XML::SAX::PurePerl->new(Handler => $x);
  my $spec = $p->parse_uri($some_uri);	
  
  #do something with $spec here

=head1 DESCRIPTION

  This is a reader class for an Amin Machine_Spec document. 
  Please see Amin::Machine::Machine_Spec for full details
  about this reader, and the xml used/returned.
   
=cut

1;
