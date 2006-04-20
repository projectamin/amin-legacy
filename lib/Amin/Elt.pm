package Amin::Elt;

use strict;
use IPC::Run qw( run harness);
use XML::SAX::Base;
use vars qw(@ISA);
use warnings;

@ISA = qw(XML::SAX::Base);

#generic parts of an element

sub attrs {
	my $self = shift;
	$self->{ATTRS} = shift if @_;
	return $self->{ATTRS};
}

sub command {
        my $self = shift;
        $self->{COMMAND} = shift if @_;
       	if (!$self->{COMMAND}) {
		$self->{COMMAND} = "";
	}
	return $self->{COMMAND};
}

#default <amin:param>

sub param {
	my $self = shift;
	if (@_) {push @{$self->{PARAM}}, @_; }
	return @{ $self->{PARAM} };
}

sub target {
	my $self = shift;
	if (@_) {push @{$self->{TARGET}}, @_; }
	return @{ $self->{TARGET} };
}

#default <amin:flag>

sub flag {
	my $self = shift;
	if (@_) {push @{$self->{FLAG}}, @_; }
	return @{ $self->{FLAG} };
}


#these are defaults for <amin:shell>

sub dir {
	my $self = shift;
	$self->{DIR} = shift if @_;
	return $self->{DIR};
}

sub env_vars {
	my $self = shift;
	if (@_) {push @{$self->{ENV_VARS}}, @_; }
	return @{ $self->{ENV_VARS} };
}

#element name
sub name {
	my $self = shift;
	$self->{NAME} = shift if @_;
	return $self->{NAME};
}

#element itself
sub element {
	my $self = shift;
	$self->{ELEMENT} = shift if @_;
	return $self->{ELEMENT};
}

#other subs
sub fix_text {
	my ($self, $text) = @_;
	$text =~ s/(^\s+|\s+$)//gm;
	return $text;
}


sub text {
	my $self = shift;
	$self->{TEXT} = shift if @_;
	return $self->{TEXT};
}



sub amin_command {

	my $self = shift;
	my $cmd = shift;
	my $special = shift || "";
	my $cmd2 = shift || ();
	my $debug = $self->{Spec}->{Filter_Param} || "";
	
	my ($in, $out, $err, $status, $command, $flag, $param, @cmd2, $flag2, $param2, @cmd);
	if ($special ne "shell") {
		$command = $cmd->{'CMD'};
		$flag = $cmd->{'FLAG'} || "";
		$param = $cmd->{'PARAM'} || "";
		@cmd2 = $cmd2->{'CMD'} || [];
		$flag2 = $cmd2->{'FLAG'} || "";
		$param2 = $cmd2->{'PARAM'} || "";

		push @cmd, $command;
		if ($flag ne "") {
			foreach (@$flag) {
				if (!defined $_) {
					next;
				}
				push @cmd, $_;
			}
		}

		if ($param ne "") {
			foreach (@$param) {
				if (!defined $_) {
					next;
				}
				push @cmd, $_;
			}
		}

		if ($cmd2 ne "") {

			if ($flag2 ne "") {
				foreach (@$flag2) {
					if (!defined $_) {
						next;
					}
					push @cmd2, $_;
				}
			}

			if ($param2 ne "") {
				foreach (@$param2) {
					if (!defined $_) {
						next;
					}
					push @cmd2, $_;
				}
			}
		}
		if (defined $cmd->{'ENV_VARS'}) {
			my $vars = $cmd->{'ENV_VARS'};
			foreach (@$vars) {
				my ($name, $value) = split(/=/, $_, 2);
				#define a local %ENV setting for this command
				$ENV{$name} = $value;
			}
		}
	}

	if ($special eq "|") {
		my $h = harness \@cmd, $special, \@cmd2, \$in, \$out, \$err;
		run $h ;
		$status = $h->result;
	} elsif ($special eq ">") {
		#this should be changed cause its not right for
		#@cmd > @cmd2
		my $file = shift @cmd2;
		my $h = harness \@cmd, $special, $file, \$in, \$out, \$err;
		run $h ;
		$status = $h->result;

	} elsif ($special eq "shell") {
		my $h = harness [ "sh", "-c", $cmd ], \$in, \$out, \$err;
		run $h ;
		$status = $h->result;
	} else {
		my $h = harness \@cmd, \$in, \$out, \$err;
		if ($debug eq "ac") {
			print ":@cmd:";
		}
		run $h ;
		$status = $h->result;
	}

	if ($special ne "shell") {
		if (defined $cmd->{'ENV_VARS'}) {
			my $vars = $cmd->{'ENV_VARS'};
			foreach (@$vars) {
				#undefine our %ENV setting
				my ($name, $value) = split(/=/, $_, 2);
				delete $ENV->{'$name'};
			}
		}
	}



	my %rcmd;
	$rcmd{OUT} = $out;
	$rcmd{ERR} = $err;
	$rcmd{STATUS} = $status;


	return \%rcmd;
}

1;

=head1 NAME

Amin::Elt - base library class for all Amin modules

=head1 Example

  use Amin::Elt;
  use vars qw(@ISA);
  @ISA = qw(Amin::Elt);

  $data = $self->fix_text($data);


  my $cmd = $self->amin_command(\%acmd);
  
  if ($cmd->{STATUS} != 0) {
  	#command failed
  }
  print $cmd->{OUT};
  

  #other methods available, see below

=head1 DESCRIPTION

Amin::Elt is the base library class for all Amin modules.
This contain the most common subroutines shared by all 
filters. It also contains two methods that do something
useful besides just store data. Those two methods are

fix_text and amin_command
  

=head1 Methods

=over 4

=item fix_text

Fix_text removes leading and trailing whitespace
from the $text supplied to the method.

  $data = $self->fix_text($data);



=item generic parts of an element

the attrs and command methods provide 
single item containers for all the 
attributes provided in a sax stream
and a command name.

	sub start_element {
		my ($self, $element) = @_;
		%attrs = %{$element->{Attributes}};
		$self->attrs(%attrs);
		$self->command($attrs{'{}name'}->{Value});
		....
	}

later you can use 

my $attrs = $self->{"ATTRS"};

etc.



=item default <amin:param> methods


parameters - this a generic parameters catch all method. 

ex. usage	     	     
        
	if ($element->{LocalName} eq "param") {
                if ($attrs{'{}name'}->{Value} eq "") {
                        if ($data ne "") {
                                my @things = $data =~ m/([\+\.\w=\/-]+|'[^']+')\s*/g;
                                foreach (@things) {
                                        $_ =~ s/(^'|'$)//gm;
                                        $self->param($_);
                                }
                        }
                }
        }


target - parameters typically have multiple target
         This method just defines multiple parameters
	 as targets instead of generic parameters.
	
ex. usage	     	     
	
	if ($attrs{'{}name'}->{Value} eq "target") {
		if ($data ne "") {
			my @things = $data =~ m/([\*\+\.\w=\/-]+|'[^']+')\s*/g;
			foreach (@things) {
				$self->target($_);
			}
		}
	}


=item default <amin:flag> methods


parameters - this is a generic flag catch all method. 


ex. usage	     	     
	
	if ($element->{LocalName} eq "flag") {
		if ($attrs{'{}name'}->{Value} eq "") {
			if ($data ne "") {
				$self->flag(split(/\s+/, $data));
			}
		}
	}


=item default <amin:shell> methods

       
dir - single container for a dir. 

ex. usage	     	     
       
       if ($attrs{'{}name'}->{Value} eq "dir") {
                if ($data ne "") {
                        $self->dir($data);
                }
        }


env_vars - multiple enviroment variable container. 

ex. usage	     	     

        if ($attrs{'{}name'}->{Value} eq "env") {
                if ($data ne "") {
                        $self->env_vars($data);
                }
        }



=item container for a sax element

element - container for the current sax element. 

ex. usage	     	     

	sub start_element {
	        my ($self, $element) = @_;
	        $self->element($element);
	}

=item handy text container for text

$self->text($my_text);


=item amin_command

This method tries to provide a simple interface
in amin terms to the complex IPC::Run possibilities. 

This is a typical usage scenario. 

  my $cmd = $self->amin_command(\%acmd);
  
  if ($cmd->{STATUS} != 0) {
  	#command failed
	my $text = "Unable to create directory. Reason: $cmd->{ERR}";
	$self->text($text);
	$self->error_message($text);
	if ($cmd->{ERR}) {
		$self->ERR_message($cmd->{ERR});
	}
	#stop the machine, return and so on
  }
  print $cmd->{OUT};
  print $cmd->{ERR};
  print $cmd->{IN};
  
A typical %acmd usage scenario.
  
  my %acmd;
  $acmd{'CMD'} = $command;
  $acmd{'FLAG'} = \@flag;
  $acmd{'PARAM'} = \@target;
  if ($self->{'ENV_VARS'}) {
    $acmd{'ENV_VARS'} = $self->{'ENV_VARS'};
  }
  my $cmd = $self->amin_command(\%acmd);
  
A more complicated scenario. Two commands and a shell pipe.
Any special shell character is applicable, but only "|" and
">" are implemented at this time.

 the command - bzcat somepackage.tar.bz2 | tar xv
  
  my (@param, @flag);
  my %acmd;
  my $archive = "somepackage.tar.bz2";
  push @param, $archive;
  $acmd{'CMD'} = "bzcat";
  $acmd{'PARAM'} = \@param;
  $acmd{'FLAG'} = "";

  my %bcmd;
  push @flag, "xv";
  $bcmd{'CMD'} = "tar";
  $bcmd{'FLAG'} = \@flag;
  $bcmd{'PARAM'} = "";

  my $special = "|";


  $cmd = $self->amin_command(\%acmd, $special, \%bcmd);
  

when all else fails

  If none of the amin_command scenarios work for you,
  you can always use the shell passthru scenario.   
  
  my $special = "shell";
  $cmd = $self->amin_command($cmd, $special);

  When you do this, amin_command will try to run 
  
  sh -c $cmd
  
  Good luck. :) 
 
=back  

=cut








