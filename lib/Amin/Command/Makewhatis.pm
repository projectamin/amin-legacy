package Amin::Command::Makewhatis;

use strict;
use vars qw(@ISA);
use Amin::Command::Elt;
use Amin::Dispatcher;

@ISA = qw(Amin::Command::Elt Amin::Dispatcher);

my (%attrs, @target);

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

	if ($attrs{'{}name'}->{Value} eq "sections") {
		if ($data ne "") {
			$self->sections($data);
		}
	}
	if ($attrs{'{}name'}->{Value} eq "catpath") {
		if ($data ne "") {
			$self->catpath($data);
		}
	}
	if ($element->{LocalName} eq "flag") {
		if ($attrs{'{}name'}->{Value} eq "") {
			if ($data ne "") {
				$self->flag(split(/\s+/, $data));
			}
		}
	}
	if ($element->{LocalName} eq "param") {
		if ($data ne "") {
			my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
			foreach (@things) {
				$self->param($_);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {
		my $sections = $self->{'SECTIONS'};
		my $catpath = $self->{'CATPATH'};
		my $xflag = $self->{'FLAG'};
		my $command = $self->{'COMMAND'};
		my ($flag, @flag);
		my $log = $self->{Spec}->{Log};

		my $state;
		foreach my $ip (@$xflag){
			if ($state == 0) {
				$flag = "-" . $ip;
				$state = 1;
			} else {
				$flag = " -" . $ip;
			}
			push @flag, $flag;
		}
		if ($sections) {
			$flag = "-s " . $sections;
			push @flag, $flag;
		}

		if ($catpath) {
			$flag = "-c " . $catpath;
			push @flag, $flag;
		}

		my %acmd;
		$acmd{'CMD'} = $command;
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@target;
		
		my $cmd = $self->amin_command(\%acmd);

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to makewhatis. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "Makewhatis was successful";
		$self->text($text);

		$log->success_message($text);
		if ($cmd->{OUT}) {
			$log->OUT_message($cmd->{OUT});
		}
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}


sub sections {
	my $self = shift;
	$self->{SECTIONS} = shift if @_;
	return $self->{SECTIONS};
}

sub catpath {
	my $self = shift;
	$self->{CATPATH} = shift if @_;
	return $self->{CATPATH};
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
		if (($_ =~ /^-.*$/) || ($_ =~ /^--.*$/) || ($scratch{name})) {
			#it is a flag
			my %flag;
			my $char;
			$_ =~ s/-//;
			$_ =~ s/--//;
			if ($scratch{name}) {
				#this completes the -s 5 crap
				if ($_ =~ /\d+/) {
					$char = $_;
				} else {
					my %param;
					$param{"char"} = $_;
					push @params, \%param;
				}
				$_ = $scratch{name};
				#undefine stuff
				$stop = undef;
				%scratch = {};
			} else {
				if ($_ =~ /^.*=.*$/) {
					($_, $char) = split (/=/, $_);
				} elsif ($_ eq "s") {
					$scratch{name} = $_;
					$stop = 1;
				} elsif ($_ eq "c") {
					$scratch{name} = $_;
					$stop = 1;
				} else  {
					#its just a flag
					$char = $_;
					$_ = undef;
				}
			}
			
			if (!$stop) {
				if ($_) {
					$flag{"name"} = $_;
				}
			
				$flag{"char"} = $char;
				push @flags, \%flag;
			}
		
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

1;


=head1 NAME

Makewhatis - reader class filter for the makewhatis command.

=head1 version

makewhatis (coreutils) 5.0 March 2003

=head1 DESCRIPTION

  A reader class for the makewhatis command. 
  
=head1 XML

=over 4

=item Full example

        <amin:command name="makewhatis">
                <amin:param name="s">5</amin:param>
                <amin:flag>w</amin:flag>
        </amin:command>

=back  

=cut

