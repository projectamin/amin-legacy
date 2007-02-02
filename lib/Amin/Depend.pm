package Amin::Depend;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

#Amin Depend
use strict;
use vars qw(@ISA);
use Amin;
use Amin::Elt;
use Amin::Machine::Profile::Checker;

use XML::SAX::Writer;
use XML::Generator::PerlData;
use XML::SAX::PurePerl;

@ISA = qw(Amin::Elt);

my $state = 0;
my $pass = 0;
my $fail = 0;
my $machine = 0;
my ($p, $pd, $h, $xmldoc);

sub start_document {
	my $self = shift;
	$state = 0;
	$pass = 0;
	$fail = 0;
	$machine = 0;
	$p = undef;
	$pd = undef;
	$h = undef;
	$xmldoc = undef;
}



#log = 1 Super = 0
sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};
	my $log = $self->{Spec}->{Log};
	
	if (($element->{Prefix} eq "amin") && ($element->{LocalName} eq "depend")) {
		$self->SUPER::start_element($element);
	} elsif ($element->{LocalName} eq "test") {
		#instead of capturing the test xml, 
		#we will let pd recreate it for us
		$h = XML::SAX::Writer->new(Output => \$xmldoc);
		$pd = XML::Generator::PerlData->new(Handler => $h);
		$pd->parse_start();	
		$state = 1;
		$self->SUPER::start_element($element);
	} elsif ($state == 1) {
		#we are parsing test xml
		unless (($element->{LocalName} eq "depend") ||
			($element->{LocalName} eq "test")) {
		#so parse a chunk 
		$pd->parse_chunk($element);	
		$log->driver_start_element($element->{Name}, %attrs);
		}
	} elsif ($element->{LocalName} eq "pass") {
		if ($pass == 1) { 
			#pass passed
			#send it on to the machine for processing
			$self->SUPER::start_element($element);
			$machine = 1;
		} else {
			$log->driver_start_element($element->{Name}, %attrs);
		}	
	} elsif ($element->{LocalName} eq "fail") {
		if ($fail == 1) { 
			#fail passed
			#send it on to the machine for processing
			$self->SUPER::start_element($element);
			$machine = 1;
		} else {
			#fail failed
			$log->driver_start_element($element->{Name}, %attrs);
		}
	} else { 
		#this is where pass, or fail do their thing
		unless (($element->{LocalName} eq "depend") ||
			($element->{LocalName} eq "test") ||
			($element->{LocalName} eq "pass") ||
			($element->{LocalName} eq "fail")) {
			if ($machine == 1) {
				#sending to machine
				$self->SUPER::start_element($element);
			} else {
				$log->driver_start_element($element->{Name}, %attrs);
			}
		}
	}
}

sub characters {
	my ($self, $chars) = @_;
	my $data = $chars->{Data};
	my $log = $self->{Spec}->{Log};
	$data = $self->fix_text($data);
	if (($self->command eq "depend") && ($data ne "")) {
		if ($state == 1) {
			#we are parsing test xml
			#so parse a chunk
			$pd->parse_chunk($chars);	
			$log->driver_characters($data);
		} elsif (($pass == 1) || ($fail == 1) || ($machine == 1)) {
			$self->SUPER::characters($chars);
		} else {
			$log->driver_characters($data);
		}
	}
}

sub end_element {
	my ($self, $element) = @_;
	my $log = $self->{Spec}->{Log};
	
	if ($state == 1) {
		unless (($element->{LocalName} eq "depend") ||
			($element->{LocalName} eq "test")) {
			#we are parsing test xml
			#so parse a chunk
			$pd->parse_chunk($element);	
			$log->driver_end_element($element->{Name});
		}
	} elsif ($element->{LocalName} eq "test") {
		#we are done parsing test xml
		#so bring the parsing to an end
		$pd->parse_end();	
		#which happily byproducts $xmldoc
		#into being, ie all the stuff we just 
		#captured.
		
		#build a mini amin machine
		my $amin = Amin->new();
		
		#should there be normal controller options 
		#here and you pass this as elements into <test>?
		
		$amin->set_machine_spec($self->{Spec});
		
		my $results = $amin->parse_string($xmldoc);
		
		#we have made it this far and something has 
		#happened with the test. Now we need to run 
		#the $results through a Depend checker, which
		#just checks for errors, if so it returns fail,
		#if everything passes it returns pass.
		
		$h = Amin::Machine::Profile::Checker->new();
		$p = XML::SAX::PurePerl->new(Handler => $h);
		my $test = $p->parse_string($results);	
		if ($test) {
			$fail = 1;
		} else {
			$pass = 1;
		}
		#clean up test stuff
		$state = 0;
		$self->SUPER::start_element($element);
	} elsif ($element->{LocalName} eq "depend") {
		$self->SUPER::end_element($element);
	} elsif ($element->{LocalName} eq "fail") {
		if ($fail == 1) {
			#the machine is on turn it off
			$machine = 0;
			$self->SUPER::end_element($element);
		} else {
			$log->driver_end_element($element->{Name});
		}
	} elsif ($element->{LocalName} eq "pass") {
		if ($pass == 1) {
			#the machine is on turn it off
			$machine = 0;
			$self->SUPER::end_element($element);
		} else {
			$log->driver_end_element($element->{Name});
		}
	}
}

sub version {
	return "1.0";
}

1;



=head1 NAME

Depend - reader class filter for an amin depend.

=head1 version

amin 0.5.0

=head1 DESCRIPTION

  ******AAAAATTTTTEEEENNNNNTTTTTIIIIIOOOOOOOONNNNN*******
  
  THIS MODULE HAS NOT BEEN TESTED AND SHOULD BE CONSIDERED BROKEN!!!!!!
  

  A reader class for an amin depend. Please look at the
  example first to understand the rest of this description.
  An amin depend is just a simple runtime dependency administration
  construct. Use anywhere you need to do a depend test or a
  little sanity. :) 
  
  The basic construct of a depend is to perform a test. 
  This test is a "profile" of xml elements that do something.
  You can make your own filters or use normal amin filters.
  ie all normal amin machine/filter rules apply. 
  
  You might make your own exotic test depend namespaced 
  elements like 
  
  	<my:weather name="temperature">
		<my:param name="low">32</my:param>
	</my:weather>
	
   and if the weather outside, is below 32 degrees then
   this test would fail, otherwise it would pass. 
   
   Looking at the normal example below, you will see that this
   depend should pass the first time (ie there is no /tmp/depend_test)
   and will fail the second time because /tmp/depend_test exists.
   
   How this module works is with voodoo magic. So beware, if 
   you go reading the code... 
   
  
  
  
=head1 XML

=over 4

=item Full example

 <amin:profile xmlns:amin='http://projectamin.org/ns/'>
	<amin:depend>
		<amin:test>
			<amin:command name="mkdir">
				<amin:param>/tmp/depend_test</amin:param>
			</amin:command>
		</amin:test>
		<amin:pass>
			<amin:command name="remove">
				<amin:param>/tmp/fail</amin:param>
			</amin:command>
			<amin:command name="touch">
				<amin:param>/tmp/pass</amin:param>
			</amin:command>
		</amin:pass>
		<amin:fail>
			<amin:command name="remove">
				<amin:param>/tmp/pass</amin:param>
			</amin:command>
			<amin:command name="touch">
				<amin:param>/tmp/fail</amin:param>
			</amin:command>
		</amin:fail>
	</amin:depend> 
 </amin:profile>

=back  

=cut


