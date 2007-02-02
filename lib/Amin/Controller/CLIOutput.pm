package Amin::Controller::CLIOutput;

use strict;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);


my $doc;
my $level = 0;


sub start_document {
	my $self = shift;
	$doc = undef;
	$level = 0;
}

	
sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};
	my $el = '<' . $element->{Name};
	for my $k (keys %attrs) {
		$el .= " " . $attrs{$k}->{Name} . "=\"" . $attrs{$k}->{Value} . "\"";
	}
	$el .= ">";
	#bump the level
	$level++;
	if ($level == 1) {
		$doc .= $el . "\n";
	} else {
		#add in the tabbed levels
		my $tabs = "";
		my $tabber = "   ";
		my $tlevel;
		for ($tlevel = $level; $tlevel > 1; $tlevel--) {		
			$tabs .= $tabs . $tabber;
		}
		$el = $tabs . $el . "\n";
		$doc .= $el;
	}
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	my $element = $self->{"ELEMENT"};
	$data = $self->fix_text($data);
	if ($data ne "") {
		my $tabs = "";
		my $tabber = "   ";
		my $tlevel;
		#my $tabber2 = "  ";
		for ($tlevel = $level; $tlevel > 1; $tlevel--) {		
			$tabs .= $tabs . $tabber; # . $tabber2;
		}
		$data = $tabs . $data . "\n";
		$doc .= $data;
	}
}

sub end_element {
	my ($self, $element) = @_;
    	my $el = '</' . $element->{Name} . '>';
	if ($level == 1) {
		$doc .= $el . "\n";
	} else {
		#add in the tabbed levels
		my $tabs = "";
		my $tlevel;
		my $tabber = "   ";
		for ($tlevel = $level; $tlevel > 1; $tlevel--) {		
			$tabs .= $tabs . $tabber;
		}
		$el = $tabs . $el . "\n";
		$doc .= $el;
	}
	$level--;
}


sub comment {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	$data = $self->fix_text($data);
	if ($data ne "") {
		my $tabs = "";
		my $tlevel;
		my $tabber = "   ";
		for ($tlevel = $level; $tlevel == 1; $tlevel--) {		
			$tabs .= $tabs . $tabber;
		}
		$data = $tabs . $data . "\n";
		$doc .= $data;
	}
}

sub comment {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	$data = $self->fix_text($data);
	if ($data ne "") {
		my $tabs = "";
		my $tlevel;
		my $tabber = "   ";
		for ($tlevel = $level; $tlevel == 1; $tlevel--) {		
			$tabs .= $tabs . $tabber;
		}
		$data = $tabs ."<!--" . $data . "-->" . "\n";
		$doc .= $data;
	}
}



sub end_document {
	my $self = shift;
	return $doc;
}

sub element {
	my $self = shift;
	$self->{ELEMENT} = shift if @_;
	return $self->{ELEMENT};
}

1;

=head1 NAME

CLIOutput - reader and formatter filter for any controller

=head1 version

cat (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  This module is still a work in progress. This module is 
  used by a controller to format for CLI Output the results
  from an amin machine. 
  
=head1 Example

=over 4

=item In a controller.....

	$amin->parse_uri($cli->uri); 
	my $results = $amin->results;
	foreach (@$results) {
		my $h = Amin::Controller::CLIOutput->new();
		my $p = XML::SAX::PurePerl->new(Handler => $h);
		my $text = $p->parse_string($_);
		print $text;
	}

=back  

=cut



