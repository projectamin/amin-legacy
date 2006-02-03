package Amin::Command::Configure;

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

		if ($element->{LocalName} eq "shell") {
			if ($attrs{'{}name'}->{Value} eq "dir") {
				$self->dir($data);
			}
			if ($attrs{'{}name'}->{Value} eq "env") {
				$self->env_vars($data);
			}
		}
		if ($element->{LocalName} eq "param") {
			if ($attrs{'{}name'}->{Value} eq "config") {
				$self->config($data);
			}
			if ($attrs{'{}name'}->{Value} eq "") {
				my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
				foreach (@things) {
					$self->param($_);
				}
			}
		}
		if ($element->{LocalName} eq "flag") {
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->flag(split(/\s+/, $data));
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {

		my $dir = $self->{'DIR'};
		my $xflag = $self->{'FLAG'};
		my $param = $self->{'PARAM'};
		my $command = $self->{'CONFIG'} || "./configure";
		my ($flag, @flag, @param);
		my $log = $self->{Spec}->{Log};

		foreach my $ip (@$xflag){
			if (($ip =~ /^-/) || ($ip =~ /^--/)) {
				push @flag, $ip;
			} else {	
				$flag = "--" . $ip;
				push @flag, $flag;
			}
		}

		foreach my $ip (@$param){
			push @param, $ip;
		}

		if ($dir) {
			if (! chdir $dir) {
				$self->{Spec}->{amin_error} = "red";
				my $text = "Unable to change directory to $dir. Reason: $!";
				$self->text($text);

				$log->error_message($text);
				$self->SUPER::end_element($element);
				return;
			}
		}

		my %acmd;
		$acmd{'CMD'} = $command;
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;

		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}
		
		my $cmd = $self->amin_command(\%acmd);

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to execute $command in $dir. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "Executing $command ";
		if (@flag) {
			$text = $text . join (", ", @flag)
		}
		if (@param) {
			$text = $text .  " " . join (", ", @param);
		}
		$text = $text . " in $dir";
		$self->text($text);
		$log->success_message($text);
		if ($cmd->{OUT}) {
			$log->OUT_message($cmd->{OUT});
		}
		#reset this command
		
		$self->{DIR} = undef;
		$self->{CONFIG} = undef;
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

sub config {
	my $self = shift;
	$self->{CONFIG} = shift if @_;
	return $self->{CONFIG};
}

sub version {
	return "1.0";
}

1;

=head1 NAME

Configure - reader class filter for the configure command.

=head1 version


=head1 DESCRIPTION

  A reader class for the configure command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
	<amin:command name="configure"> 
		<amin:flag>prefix=/usr</amin:flag> 
		<amin:shell name="dir">/tmp/amin-tests/fake-0.01</amin:shell> 
	</amin:command>
        <!-- more complicated example
	<amin:command name="configure">
                <amin:param name="config">../glibc-2.3.2/configure</amin:param>
                <amin:flag>
                        prefix=/usr
                        disable-profile
                        with-tls
                        without-__thread
                        enable-add-ons
                        libexecdir=/usr/bin
                        infodir=/usr/share/info
                        with-headers=/usr/include
                </amin:flag>
                <amin:shell name="dir">/usr/src/glibc-build</amin:shell>
        </amin:command>
	-->
 </amin:profile>
 
=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'> 
	<amin:command name="configure"> 
		<amin:flag>prefix=/usr</amin:flag> 
		<amin:shell name="dir">/tmp/amin-tests/fake-0.01</amin:shell> 
	</amin:command>
	<amin:command name="configure"> 
		<amin:flag>prefix=/usr</amin:flag> 
		<amin:shell name="dir">/tmp/amin-tests2/fake-0.01</amin:shell> 
	</amin:command>
 </amin:profile>

=back  

=cut
