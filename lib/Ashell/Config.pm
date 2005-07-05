package Ashell::Config;

use strict;
use vars qw(@ISA);
use XML::SAX::Base;

@ISA = qw(XML::SAX::Base);

my %config;

sub start_element {
	my ($self, $element) = @_;
	$self->element($element);
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	my $element = $self->{"ELEMENT"};

	if ($element->{LocalName} eq "namespace_uri") {
		$self->namespace_uri($data);
	}
	if ($element->{LocalName} eq "namespace") {
		$self->namespace($data);
	}
	if ($element->{LocalName} eq "log_dir") {
		$self->log_dir($data);
	}

}

sub end_element {
	my ($self, $element) = @_;
	if ($element->{LocalName} eq "config") {
		$config{namespace_uri} = $self->namespace_uri;
		$config{namespace} = $self->namespace;
		$config{log_dir} = $self->log_dir;
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

sub namespace_uri {
	my $self = shift;
	$self->{NAMESPACE_URI} = shift if @_;
	return $self->{NAMESPACE_URI};
}

sub namespace {
	my $self = shift;
	$self->{NAMESPACE} = shift if @_;
	return $self->{NAMESPACE};
}

sub log_dir {
	my $self = shift;
	$self->{LOG_DIR} = shift if @_;
	return $self->{LOG_DIR};
}


=head1 Name

Ashell::Config - simple config.xml reader for ashell

=head1 Example

	my $home = $ENV{'HOME'};
	my $userdir = "$home/.amin";
	my $config_file = "$userdir/ashell.xml";

	if (-e $config_file) {
		$config = read_config();
	} else {
		#make a new config file
		$config = make_config();
		write_config($config);
	}

	sub read_config {
		my $home = $ENV{'HOME'};
		my $h = Ashell::Config->new();
		my $p = XML::SAX::PurePerl->new(Handler => $h);
		my $config = $p->parse_uri($config_file);
		return $config;
	}

	sub write_config {
		my $config = shift;
		my $answer;
		if ($config) {	
			my $h = XML::SAX::Writer->new(Output => $config_file);
			my $d  = XML::Generator::PerlData->new(
				rootname => 'config',
				namespacemap => {'http://projectamin.org/ns/' => 'config'},
				namespaces =>  {'http://projectamin.org/ns/' => 'amin' },
				Handler => $h,
			);
			$d->parse($config);
			$answer = "ok";
		}
		return $answer;
	}

=head1 Description

This SAX Filter will read an ashell configuration file. This
file looks like

	<config>
		<namespace_uri>http://projectamin.org/ns/</namespace_uri>
		<namespace>amin</namespace>
		<log_dir>file://tmp/logs/</log_dir>
	</config>

and will return a hash reference that looks like


	$config = {
		namespace_uri => http://projectamin.org/ns/,
		namespace => amin,
		log_dir => file://tmp/logs,
		};
	
=head1 Methods 

=over 4

=item none

Ashell::Config has no methods as it is a SAX filter and
the methods are SAX methods not methods you call directly.
   
=back

=cut








1;