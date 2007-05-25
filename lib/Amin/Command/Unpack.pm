package Amin::Command::Unpack;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use warnings;
use vars qw(@ISA);
use Amin::Elt;

@ISA = qw(Amin::Elt);

my (%attrs, $cmd, $OUT);

sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	if (!$attrs{'{}name'}->{'Value'}) {
		$attrs{'{}name'}->{'Value'} = "";
	}
	$self->attrs(%attrs);
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command") && ($attrs{'{}name'}->{Value} eq "unpack")) {
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
	my $command = $self->command;
	if (($command eq "unpack") && ($data ne "")) {
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "archive") {
				$self->archive($data);
			}
			if ($attrs{'{}name'}->{Value} eq "target") {
				$self->target($data);
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if (($element->{LocalName} eq "command") && ($self->command eq "unpack")) {
	
	my $log = $self->{Spec}->{Log};
	my $archive = $self->{'ARCHIVE'};
	my $target = $self->{'TARGET'};
	my $dir;
        
	my (@aparam, @aflag, %archive);
	$archive{'CMD'} = "pwd";
	$archive{'PARAM'} = \@aparam;
	push @aflag, "-L";
	$archive{'FLAG'} = \@aflag;
	my $arcmd = $self->amin_command(\%archive);
	my $ardir = $arcmd->{OUT};
	
	
	if (! -f $archive) {
		$self->{Spec}->{amin_error} = "red";
		my $text = "Unable to unpack $archive. Reason: No such file";
		$self->text($text);
		$log->error_message($text);
		$self->SUPER::end_element($element);
		return;
        }
	if (($archive =~ /\.tar\.gz$/) || ($archive =~ /\.tgz$/)) {
		if ($archive =~ /^.\//) {
			$archive = $ardir . "/" . $archive;
		}
		if (! chdir $target) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to change directory to $target. Reason: $!";
			$self->text($text);

			$log->error_message($text);
			$self->SUPER::end_element($element);
			return;
		}

		my (%acmd, @flag, @param);

		push @flag, "-xzf";
		push @param, $archive;

		$acmd{'CMD'} = "tar";
		$acmd{'PARAM'} = \@param;
		$acmd{'FLAG'} = \@flag;

		$cmd = $self->amin_command(\%acmd);

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to unpack $archive. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}
		
	} elsif ($archive =~ /\.tar\.bz2$/) {
		if ($archive =~ /^.\//) {
			$archive = $ardir . "/" . $archive;
		}
		if (! chdir $target) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to change directory to $target. Reason: $!";
			$self->text($text);

			$log->error_message($text);
			$self->SUPER::end_element($element);
			return;
		}

		my (%acmd, @flag, @param);

                push @flag, "-xjf";
                push @param, $archive;

                $acmd{'CMD'} = "tar";
                $acmd{'PARAM'} = \@param;
                $acmd{'FLAG'} = \@flag;

		$cmd = $self->amin_command(\%acmd);

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to unpack $archive. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}


        } elsif ($archive =~ /\.gz$/) {
		my $basename = $archive;
                $basename =~ s/\.gz$//;
                $basename =~ s/.*\///;

		if ($archive =~ /^.\//) {
			$archive = $ardir . "/" . $archive;
		}
		if (! chdir $target) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to change directory to $target. Reason: $!";
			$self->text($text);

			$log->error_message($text);
			$self->SUPER::end_element($element);
			return;
		}

		my (%acmd, @flag, @param);

		push @param, $archive;

		my $special = ">";
		my %bcmd;
		$bcmd{'CMD'} = $basename;

		$acmd{'CMD'} = "zcat";
		$acmd{'PARAM'} = \@param;
		$acmd{'FLAG'} = \@flag;

		$cmd = $self->amin_command(\%acmd, $special, \%bcmd);


		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to unpack $archive. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

        } elsif ($archive =~ /\.bz2$/) {
		my $basename = $archive;
                $basename =~ s/\.bz2$//;
                $basename =~ s/.*\///;

		if ($archive =~ /^.\//) {
			$archive = $ardir . "/" . $archive;
		}
		if (! chdir $target) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to change directory to $target. Reason: $!";
			$self->text($text);

			$log->error_message($text);
			$self->SUPER::end_element($element);
			return;
		}

		my (%acmd, @flag, @param);

		push @param, $archive;

		my $special = ">";
		my %bcmd;
		$bcmd{'CMD'} = $basename;

		$acmd{'CMD'} = "bzcat";
		$acmd{'PARAM'} = \@param;
		$acmd{'FLAG'} = \@flag;

		$cmd = $self->amin_command(\%acmd, $special, \%bcmd);

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to unpack $archive. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

        } else {
		$self->{Spec}->{amin_error} = "red";
		my $text = "Unable to unpack $archive. Reason: Not supported file type";
		$self->text($text);
		$log->error_message($text);
		$self->SUPER::end_element($element);
		return;
        }

		my $text = "Unpacking : $archive Destination : $target";
		$self->text($text);
		$log->success_message($text);
		if ($cmd->{OUT}) {
			$log->OUT_message($cmd->{OUT});
		}
		#reset this command
		
		$self->{DIR} = undef;
		$self->{FLAG} = [];
		$self->{PARAM} = [];
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{ELEMENT} = undef;
		$self->{ARCHIVE} = undef;
		$self->{TARGET} = undef;
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub archive {
	my $self = shift;
	$self->{ARCHIVE} = shift if @_;
	return $self->{ARCHIVE};
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
		#it is either a param, command name
		my $x = 1; 
		if ($_ =~ /^.*=.*$/) {
			my %shell;
			#it is an env variable 
			$shell{"name"} = 'env';
			$shell{"char"} = $_;
			push @shells, \%shell;
		} else {
			if (!$command{name}) {
				$command{name} = $_;
			} else {
				my %param;
				$param{"char"} = $_;
			
				if ($x == 1) {
					$param{"name"} = "target";
				} elsif ($x == 2) {
					$param{"name"} = "archive";
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

1;

=head1 NAME

Unpack - reader class filter for the unpack command.

=head1 version

amin 0.5.0

=head1 DESCRIPTION

  A reader class for the unpack command. Unpack is a 
  tar, gzip, bzip unpacker. Supported formats .tar.gz,
  .tgz, .tar.bz2, .gz, and .bz2
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:download>
                <amin:param name="uri">http://projectamin.org/apan/tester/command/fake-0.01.tar.bz2</amin:param>
                <amin:param name="file">/tmp/amin-tests/fake-0.01.tar.bz2</amin:param>
        </amin:download>
        <amin:command name="unpack">
                <amin:param name="target">/tmp/amin-tests/</amin:param>
                <amin:param name="archive">/tmp/amin-tests/fake-0.01.tar.bz2</amin:param>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:download>
                <amin:param name="uri">http://projectamin.org/apan/tester/command/fake-0.01.tar.bz2</amin:param>
                <amin:param name="file">/tmp/amin-tests/fake-0.01.tar.bz2</amin:param>
        </amin:download>
        <amin:command name="unpack">
                <amin:param name="target">/tmp/amin-tests/</amin:param>
                <amin:param name="archive">/tmp/amin-tests/fake-0.01.tar.bz2</amin:param>
        </amin:command>
       <amin:download>
                <amin:param name="uri">http://projectamin.org/apan/tester/command/fake-0.01.tar.bz2</amin:param>
                <amin:param name="file">/tmp/amin-tests2/fake-0.01.tar.bz2</amin:param>
        </amin:download>
        <amin:command name="unpack">
                <amin:param name="target">/tmp/amin-tests2/</amin:param>
                <amin:param name="archive">/tmp/amin-tests2/fake-0.01.tar.bz2</amin:param>
        </amin:command>
 </amin:profile>

=back  

=cut
