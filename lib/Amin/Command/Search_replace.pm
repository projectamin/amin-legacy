package Amin::Command::Search_replace;

use strict;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);
my %attrs;

sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	$self->attrs(%attrs);
	if ($element->{LocalName} eq "command") {
		$self->command($attrs{'{}name'}->{Value});
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

	if ($data ne "") {
		if ($element->{LocalName} eq "shell") {
			if ($attrs{'{}name'}->{Value} eq "dir") {
				$self->dir($data);
			}
		}
	
		if ($element->{LocalName} eq "flag") {
			if ($attrs{'{}name'}->{Value} eq "find") {
				$self->find($data);
			}
			
			if ($attrs{'{}name'}->{Value} eq "replace") {
				$self->replace($data);
			}
		}
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "target") {
				$self->target($data);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {

		my $find = $self->{'FIND'};
		my $replace = $self->{'REPLACE'};
		my $dir = $self->{'DIR'};
		my $target = $self->{'TARGET'};
		my @targets;
		my $log = $self->{Spec}->{Log};

		if (! chdir $dir) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to change directory to $dir. Reason: $!";
			$self->text($text);

			$log->error_message($text);
			$self->SUPER::end_element($element);
			return;
		}

		push @targets, glob($target);
		
		foreach $target (@targets) {	
		
		if (! open (FILE, "+< $target")) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to open $target, $!";
			$self->text($text);

			$log->error_message($text);
			$self->SUPER::end_element($element);
			return;
		}
		flock(FILE, 2);

		my $out = '';
		while(<FILE>) {
			s/\Q$find\E/$replace/g;
			$out .= $_;
		};

		seek(FILE, 0, 0);
		print FILE $out;
		truncate(FILE, tell(FILE));
		close(FILE);

		my $text = "Searching $target in $dir and replacing: $find with $replace";
		$self->text($text);
		$log->success_message($text);
		}
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}


sub find {
	my $self = shift;
	$self->{FIND} = shift if @_;
	return $self->{FIND};
}

sub replace {
	my $self = shift;
	$self->{REPLACE} = shift if @_;
	return $self->{REPLACE};
}

sub target {
	my $self = shift;
	$self->{TARGET} = shift if @_;
	return $self->{TARGET};
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
				$param{"name"} = "target";
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

Search_replace - reader class filter for the search_replace command.

=head1 version

amin 0.5.0

=head1 DESCRIPTION

  A reader class for the search_replace command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="search_replace">
                <amin:param name="target">pass</amin:param>
                <amin:flag name="find">root</amin:flag>
                <amin:flag name="replace">0</amin:flag>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut
