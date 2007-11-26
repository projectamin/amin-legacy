package Amin::Protocol::Login;

use strict;
use vars qw(@ISA);
use Amin::Elt;
@ISA = qw(Amin::Elt);

my %login;
my $state;

sub start_element {
	my ($self, $element) = @_;
	$self->element($element);
	if ($element->{LocalName} eq "profile") {
		$state = "on";
	}
	if ($state eq "on") {
		$self->SUPER::start_element($element);
	}
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	my $element = $self->{"ELEMENT"};
	$data = $self->fix_text($data);

	if ($data ne "") {
		if ($element->{LocalName} eq "uri") {
			$self->uri($data);
		}

		if ($element->{LocalName} eq "username") {
			$self->username($data);
		}
		if ($element->{LocalName} eq "password") {
			$self->passwd($data);
		}
		if ($element->{LocalName} eq "profile") {
			$self->profile($data);
		}
		if ($state eq "on") {
			$self->SUPER::characters($chars);
		}
	}
}

sub end_element {
	my ($self, $element) = @_;
	if ($element->{LocalName} eq "login") {
		$login{uri} = $self->uri;
		$login{username} = $self->username;
		$login{passwd} = $self->passwd;
		$login{profile} = $self->profile;
	}
	if ($state eq "on") {
		$self->SUPER::end_element($element);
	}
	if ($element->{LocalName} eq "profile") {
		$state = "off";
	}

}

sub end_document {
	my $self = shift;
	return \%login;
}

sub element {
	my $self = shift;
	$self->{ELEMENT} = shift if @_;
	return $self->{ELEMENT};
}

sub uri {
	my $self = shift;
	$self->{URI} = shift if @_;
	return $self->{URI};
}

sub username {
	my $self = shift;
	$self->{USERNAME} = shift if @_;
	return $self->{USERNAME};
}

sub profile {
	my $self = shift;
	$self->{PROFILE} = shift if @_;
	return $self->{PROFILE};
}

sub passwd {
	my $self = shift;
	$self->{PASSWD} = shift if @_;
	return $self->{PASSWD};
}


1;
