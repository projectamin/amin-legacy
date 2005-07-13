package Amin::Command::Pconfigure;

use strict;
use vars qw(@ISA);
use Amin::Elt;
use Data::Dumper;

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

	if ($attrs{'{}name'}->{Value} eq "dir") {
		if ($data ne "") {
			$self->dir($data);
		}
	}
        if ($attrs{'{}name'}->{Value} eq "bootstrap") {
	        if ($data ne "") {
		        $self->bootstrap($data);
		}
	}
	if ($attrs{'{}name'}->{Value} eq "env") {
		if ($data ne "") {
			$self->env_vars($data);
		}
	}
	if ($attrs{'{}name'}->{Value} eq "param") {
		if ($data ne "") {
			$self->param($data);
		}
	}
	if ($element->{LocalName} eq "flag") {
		if ($attrs{'{}name'}->{Value} eq "") {
			if ($data ne "") {
				$self->flag(split(/\s+/, $data));
			}
		}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;

	if ($element->{LocalName} eq "command") {
                my $command;
		my $dir = $self->{'DIR'};
		my $xflag = $self->{'FLAG'};
		my $param = $self->{'PARAM'};
	        my $bootstrap = $self->{'BOOTSTRAP'};
		my ($flag, @flag, @param, $bootstrap);
		my $log = $self->{Spec}->{Log};

		foreach my $ip (@$xflag){
			if (($ip =~ /^-/) || ($ip =~ /^--/)) {
				push @flag, $ip;
			} else {	
				$flag = "--" . $ip;
				push @flag, $flag;
			}
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
                if ($bootstrap eq "yes") {
		my $command = "./configure.gnu -Dstatic_ext='IO Fcntl POSIX'";
	        
		   } else {
		    
		my $command = "./configure.gnu";
		       }
		
		my %acmd;    
		$acmd{'CMD'} = \$command;
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
                # die Dumper($command);
	    
		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}
		
		my ($name, $value);
		
		my $cmd = $self->amin_command(\%acmd);

		if ($cmd->{STATUS} != 0) {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to execute configure.gnu in $dir. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
			$self->SUPER::end_element($element);
			return;
		}

		my $text = "Executing Configure ";
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
		$self->SUPER::end_element($element);
	} else {
		$self->SUPER::end_element($element);
	}
}

sub bootstrap {
        my $self = shift;
        $self->{BOOTSTRAP} = shift @_;
        return $self->{BOOTSTRAP};
}

1;

=head1 NAME

Perl Configure - reader class filter for the Perl equivalent to the configure command.

=head1 version


=head1 DESCRIPTION

  A reader class for the Perl equivalent to the configure command. 
  
=head1 XML

=over 4

=item Full example

        <amin:command name="pconfigure">
                <amin:flag>
                prefix=/usr
                </amin:flag>
                <amin:param name='bootstrap'>yes</amin:param>
                <amin:shell name="dir">/usr/src/perl-5.8.6</amin:shell>
        </amin:command>
 
=back  

=cut
