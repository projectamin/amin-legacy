package Amin::Command::Amin;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use warnings;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);
my %attrs;

sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	$self->attrs(%attrs);
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "amin")) {
		$self->command($attrs{'{}name'}->{Value});
	}
	$self->element($element);
	$self->SUPER::start_element($element);
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	my $element = $self->element;
	my $attrs = $self->{"ATTRS"};
	$data = $self->fix_text($data);
	my $command = $self->command;
	if (($command eq "amin") && ($data ne "")) {
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "version") {
				$self->iversion($data);
			}
		}
	}
	$self->SUPER::characters($chars);

}

sub end_element {
	my ($self, $element) = @_;
	if (($element->{LocalName} eq "command") && ($self->command eq "amin")) {
		my $log = $self->{Spec}->{Log};
		my $version = $self->iversion;
		chomp $version;
		
		#reset this command
		$self->{IVERSION} = undef;
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ELEMENT} = undef;
		if ($version eq "") {
			$self->{Spec}->{amin_error} = "red";
			my $text = "You must supply version information";
			$self->text($text);
			
			$log->error_message($text);
			$self->SUPER::end_element($element);
		} else {
			my $text = "Starting Amin. Profile version $version";
			$self->text($text);

			$log->success_message($text);
			$self->SUPER::end_element($element);
		}
	} else {
		$self->SUPER::end_element($element);
	}
}

sub iversion {
	my $self = shift;
	$self->{IVERSION} = shift if @_;
	return $self->{IVERSION};
}



sub filter_map {
	my $self = shift;
	my $command = shift;
	my %command;
	my @flags;
	my @params;
	my @shells;
	my @things = split(/([\*\+\.\w=\/-]+|'[^']+')\s*/, $command);

	my %scratch;
	my $stop;
	foreach (@things) {
	#check for real stuff
	if ($_) {
		#check for flag
		if (($_ =~ /^-.*$/) || ($_ =~ /^--.*$/)) {
			#it is a flag
			my %flag;
			my $char;
			$_ =~ s/-//;
			$_ =~ s/--//;
			if ($_ =~ /^.*=.*$/) {
				#check for stuff like -m=0755 crap
				($_, $char) = split (/=/, $_);
			} else  {
				#its just a flag
				$char = $_;
				$_ = undef;
			}
			
			if ($_) {
				$flag{"name"} = $_;
			}
			$flag{"char"} = $char;
			push @flags, \%flag;
		} elsif ($_ =~ /^.*=.*$/) {
			my %shell;
			#it is an env variable 
			$shell{"name"} = 'env';
			$shell{"char"} = $_;
			push @shells, \%shell;
		} else {
			#it is either a param, command name
			if (!$command{name}) {
				$command{name} = $_;
			} else {
				my %param;
				$param{"char"} = $_;
				$param{"name"} = "version";
				push @params, \%param;
			}
		}
	}
	}
	
	if (@shells) {
		$command{shell} = \@shells;
	}
	if (@flags) {
		$command{flag} = \@flags;
	}
	if (@params) {
		$command{param} = \@params;
	}
	
	my %fcommand;
	$fcommand{command} = \%command;
	return \%fcommand;	
}

sub version {
	return "1.0";
}

1;

=head1 NAME

Amin - reader class filter for the amin command.

=head1 version 

amin  0.5.0 

=head1 DESCRIPTION

  A reader class for the amin command. 
  
  Has one child element 
  
  <amin:param name="version">someversionhere</amin:param>
  
  Will return a profile version. 
  
  Useful for your own profile versioning in your profiles, 
  so your xml log outputs provides you useful profile version info....
  
  
=head1 XML

=over 4

=item Full example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
	<amin:command name="amin">
                <amin:param name="version">0.5.0</amin:param>
        </amin:command>
 </amin:profile>

=item Double example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="amin">
                <amin:param name="version">0.5.0</amin:param>
        </amin:command>
        <amin:command name="amin">
                <amin:param name="version">0.5.1</amin:param>
        </amin:command>
 </amin:profile>

=back  

=cut
