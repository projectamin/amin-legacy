package Amin::Download;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use vars qw(@ISA);
use LWP::UserAgent;
use Amin::Elt;

@ISA = qw(Amin::Elt);

my (%attrs);

sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	$self->attrs(%attrs);
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "download")) {
		$self->command("download");
	}

	
	$self->element($element);
	$self->SUPER::start_element($element);
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	$data = $self->fix_text($data);
	my $attrs = $self->{"ATTRS"};
	my $element = $self->{"ELEMENT"};
	
	if (($self->command eq "download") && ($data ne "")) {
		if (!$attrs{'{}name'}->{'Value'}) {
			$attrs{'{}name'}->{'Value'} = "";
		}

		if ($attrs{'{}name'}->{Value} eq "uri") {
				$self->uri($data);
		}
		if ($attrs{'{}name'}->{Value} eq "file") {
			$self->file($data);
		}
		if ($attrs{'{}name'}->{Value} eq "alt") {
			$self->alt($data);
		}
	}	
		
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if (($element->{LocalName} eq "download") && ($self->command eq "download")) {
		
		my $uri = $self->{'URI'};
		my $file = $self->{'FILE'};
		my $alt = $self->{'ALT'} || ();
		my @alt;
		my $log = $self->{Spec}->{Log};
		unshift @$alt, $uri;	
		my $ua = LWP::UserAgent->new;
		my $text;
		my $last = pop @$alt;
		push @$alt, $last;
		foreach (@$alt) {
			if (-e $file) {
				$text .= "$file already exists.";
				$log->success_message($text);
				last;		
			} else {
				my $req = HTTP::Request->new(GET => $_);
				my $res = $ua->request($req, $file);
				if ($res->is_success) {
					$text .= " Downloaded $_ to $file.";
					$log->success_message($text);
					last;
				} else {
					$text .= " Unable to download $_. Trying an alternate.";
					if ($last eq $_) {
						$text .= " No more uris available.";
						$log->error_message($text);
						last;
					}
				}
			}
		}
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub version {
	return "1.0";
}

sub uri {
	my $self = shift;
	$self->{URI} = shift if @_;
	return $self->{URI};
}

sub file {
	my $self = shift;
	$self->{FILE} = shift if @_;
	return $self->{FILE};
}

sub alt {
	my $self = shift;
	if (@_) {push @{$self->{ALT}}, @_; }
	return @{ $self->{ALT} };
}

1;



=head1 NAME

Download - reader class filter for the internal amin download command.

=head1 version

amin 0.5.0

=head1 DESCRIPTION

  A reader class for the internal amin download element. This
  is a simple d/l xml reader class. Any download has two primary
  <param>s. A uri and a file. The uri specifies what to download
  and file specifies what to call it and where locally. The optional
  "alt" param allows you to specify alternate download locations to 
  try before giving up as a failure. 
  
  If a file already exists, download will not try again. If you
  have a corrupted download, delete it to get this module to function
  properly again. We do this to prevent wasting bandwidth by 
  re-downloading files that already exist. 
  
=head1 XML

=over 4

=item Full example

       <amin:download>
                <amin:param name="uri">http://example1.com/gnu/glibc/glibc-2.3.2.tar.gz</amin:param>
                <amin:param name="alt">http://example2.com/gnu/glibc/glibc-2.3.2.tar.gz</amin:param>
                <amin:param name="alt">http://example3.com/pub/gnu/glibc/glibc-2.3.2.tar.gz</amin:param>
                <amin:param name="file">/usr/src/glibc-2.3.2.tar.gz</amin:param>
        </amin:download>

=back  

=cut

