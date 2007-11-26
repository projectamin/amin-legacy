package Amin::Command::Link;

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
	if (!$attrs{'{}name'}->{'Value'}) {
		$attrs{'{}name'}->{'Value'} = "";
	}
	$self->attrs(%attrs);
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "command")) {
		if (($attrs{'{}name'}->{Value} eq "link") || ($attrs{'{}name'}->{Value} eq "ln")) {
			$self->command($attrs{'{}name'}->{Value});
	}
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
	if (($command eq "link") || ($command eq "ln")) {
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
			if ($attrs{'{}name'}->{Value} eq "source") {
				$self->source($data);
			}
			if ($attrs{'{}name'}->{Value} eq "target") {
				$self->target($data);
			}
		}
	
		if ($element->{LocalName} eq "flag") {
			if ($attrs{'{}name'}->{Value} eq "type") {
				$self->type($data);
			}
			if ($attrs{'{}name'}->{Value} eq "") {
				$self->flag(split(/\s+/, $data));
			}
		}
	}
	}
	$self->SUPER::characters($chars);
}

sub end_element {
	my ($self, $element) = @_;
	my $debug = $self->{Spec}->{Debug} || "";

	if ($element->{LocalName} eq "command") {
	if (($self->command eq "link") || ($self->command eq "ln")) {
		my $source = $self->{'SOURCE'};
		my $dir = $self->{'DIR'};
		my $target = $self->{'TARGET'};
		my $xflag = $self->{'FLAG'};
		my $command = "ln";
		my ($flag, @flag, @param);
		my $log = $self->{Spec}->{Log};

		foreach my $ip (@$xflag){
			if (!$ip) {next;};
			if (($ip =~ /^-/) || ($ip =~ /^--/)) {
				push @flag, $ip;
			} else {	
				$flag = "-" . $ip;
				push @flag, $flag;
			}
		}

		if ($dir) {
			if (($debug eq "dir") || ($debug eq "all")) {
				print ":dir = $dir:\n";
			}
			if (! chdir $dir) {
				$self->{Spec}->{amin_error} = "red";
				my $text = "Unable to change directory to $dir. Reason: $!";
				$self->text($text);

				$log->error_message($text);
				$self->SUPER::end_element($element);
				return;
			}
		}

		push @param, $source;
		push @param, $target;

		my %acmd;
		$acmd{'CMD'} = $command;
		$acmd{'FLAG'} = \@flag;
		$acmd{'PARAM'} = \@param;
		if ($self->{'ENV_VARS'}) {
			$acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
		}

		my $cmd = $self->amin_command(\%acmd);
		
		if ($cmd->{TYPE} eq "error") {
			$self->{Spec}->{amin_error} = "red";
			my $text = "Unable to create symbolic link $target to $source. Reason: $cmd->{ERR}";
			$self->text($text);

			$log->error_message($text);
			if ($cmd->{ERR}) {
				$log->ERR_message($cmd->{ERR});
			}
		}
		if (($cmd->{TYPE} eq "out") || ($cmd->{TYPE} eq "both")) {
			my $otext = "Creating a $command link from ";
			if (defined($dir)) {
				$otext .=  "$dir/";
			}
			$otext .= "$target to $source.";
			my $etext = " There was also some error text $cmd->{ERR}";
			$etext = $otext . $etext; 
			if ($cmd->{TYPE} eq "out") {
				$log->success_message($otext);
				$log->OUT_message($cmd->{OUT});
			} else {
				$log->success_message($etext);
				$log->OUT_message($cmd->{OUT});
				$log->ERR_message($cmd->{ERR});
				
			}
		}
		#reset this command
		$self->{DIR} = undef;
		$self->{FLAG} = [];
		$self->{PARAM} = [];
		$self->{COMMAND} = undef;
		$self->{ATTRS} = undef;
		$self->{ENV_VARS} = [];
		$self->{ELEMENT} = undef;
		$self->{SOURCE} = undef;
		$self->{TYPE} = undef;
		$self->{TARGET} = undef;
		$self->SUPER::end_element($element);
	}else {
		$self->SUPER::end_element($element);
	}
	} else {
		$self->SUPER::end_element($element);
	}
}

sub source {
	my $self = shift;
	$self->{SOURCE} = shift if @_;
	return $self->{SOURCE};
}

sub type {
	my $self = shift;
	$self->{TYPE} = shift if @_;
	return $self->{TYPE};
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
		if (($_ =~ /^-.*$/) || ($_ =~ /^--.*$/) || ($scratch{name})) {
			#it is a flag
			my %flag;
			my $char;
			$_ =~ s/-//;
			$_ =~ s/--//;
			if ($scratch{name}) {
				#this completes the -S suffix crap
				if ($_ =~ /\w+\d+/) {
					$char = $_;
				} else {
					#this is a param and their -m is 0000
					#why they want this is unknown :)
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
					#check for stuff like -S=0755 crap
					($_, $char) = split (/=/, $_);
				} elsif ($_ eq "S") {
					#check for stuff like -S 0755 crap
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

sub version {
	return "1.0";
}

1;


=head1 NAME

Link - reader class filter for the gnu ln/Link command.

=head1 version
	
ln (coreutils) 5.0 March 2003


=head1 DESCRIPTION

  A reader class for the ln command. 
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="link">
                <amin:param name="source">original_thing</amin:param>
                <amin:param name="target">linked_thing</amin:param>
                <amin:flag>sf</amin:flag>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
 </amin:profile>

=item Double example
 
 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
       <amin:command name="link">
                <amin:param name="source">original_thing</amin:param>
                <amin:param name="target">linked_thing</amin:param>
                <amin:flag>sf</amin:flag>
                <amin:shell name="dir">/tmp/amin-tests/</amin:shell>
        </amin:command>
       <amin:command name="link">
                <amin:param name="source">original_thing</amin:param>
                <amin:param name="target">linked_thing</amin:param>
                <amin:flag>sf</amin:flag>
                <amin:shell name="dir">/tmp/amin-tests2/</amin:shell>
        </amin:command>
 </amin:profile>

=back  

=cut


