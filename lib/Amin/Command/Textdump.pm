package Amin::Command::Textdump;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

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
		if ($element->{LocalName} eq "param") {
		
			if ($attrs{'{}name'}->{Value} eq "content") {
				$self->content($data);
			}
			if ($attrs{'{}name'}->{Value} eq "target") {
				$self->target($data);
			}
		}
		if ($element->{LocalName} eq "shell") {
			if ($attrs{'{}name'}->{Value} eq "dir") {
				$self->dir($data);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {
		my $target = $self->{'TARGET'};
		my $dir = $self->{'DIR'};
		my $content = $self->{'CONTENT'};
		my @content;
		
		my $log = $self->{Spec}->{Log};

		if (! chdir $dir) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to change directory to $dir. Reason: $!";
			$self->text($text);

			$log->error_message($text);
			$self->{'CONTENT'} = undef;
			$self->SUPER::end_element($element);
			return;
		}

		if (! open (FILE, ">> $target")) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to open $target for dumping, $!";
			$self->text($text);

			$log->error_message($text);
			$self->{'CONTENT'} = undef;
			$self->SUPER::end_element($element);
			return;
		}

		foreach my $line(@$content) {
			$line =~ s/(^\s+|\s+$)//gm;
			if ($line) {
				print FILE "$line\n";
			}
		}
		close (FILE);

		my $text = "Dumping text to $target in $dir";
		$self->text($text);
		$log->success_message($text);
		$self->{'CONTENT'} = undef;
		#reset this command
		
		$self->{DIR} = undef;
		$self->{TARGET} = undef;
		$self->{CONTENT} = [];
		$self->{FLAG} = [];
		$self->{PARAM} = [];
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{ELEMENT} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub dir {
	my $self = shift;
	$self->{DIR} = shift if @_;
	return $self->{DIR};
}

sub content {
	my $self = shift;
	if (@_) {push @{$self->{CONTENT}}, @_; }
	return @{ $self->{CONTENT} };
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
		if ($_ =~ /^.*=.*$/) {
			my %shell;
			#it is an env variable 
			$shell{"name"} = 'env';
			$shell{"char"} = $_;
			push @shells, \%shell;
		} else {
			#it is either a param, command name
			my $x = 1; 
			if (!$command{name}) {
				$command{name} = $_;
			} else {
				my %param;
				$param{"char"} = $_;
				
				if ($x == 1) {
					$param{"name"} = "target";
				} elsif ($x == 2) {
					$param{"name"} = "content";
				}
				$x++;
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

;

=head1 NAME

Textdump - reader class filter for the textdump command.

=head1 version

amin 0.5.0

=head1 DESCRIPTION

  A reader class for the textdump command. Textdump by 
  default will append to the target file or will create 
  the target file if it does not exist.
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="textdump">
                <amin:param name="target">pass</amin:param>
                <amin:param name="content">root</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
        <amin:command name="textdump">
                <amin:param name="target">hg</amin:param>
                <amin:param name="content">Hello
                                Does This
                        all
        line
                up
right?
		</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
        <amin:command name="textdump">
                <amin:param name="target">pass</amin:param>
                <amin:param name="content">root</amin:param>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
	<amin:command name="textdump">
		<amin:param name="target">hg</amin:param>
		<amin:param name="content">Hello
				Does This
			all
	line
		up
right?
		</amin:param>
		<amin:shell name="dir">/tmp/amin-tests/</amin:shell>
	</amin:command>
        <amin:command name="textdump">
                <amin:param name="target">pass</amin:param>
                <amin:param name="content">root</amin:param>
                <amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
        </amin:command>
	<amin:command name="textdump">
		<amin:param name="target">hg</amin:param>
		<amin:param name="content">Hello
				Does This
			all
	line
		up
right?
		</amin:param>
		<amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
	</amin:command>
 </amin:profile>

=back  

=cut

