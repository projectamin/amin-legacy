package Amin::Machines;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use Amin::Machine::Machine_Spec;

my $DefaultSAXHandler ||= 'Amin::Machine::Handler::Writer';
my $DefaultSAXGenerator	||= 'XML::SAX::PurePerl';
my $DefaultLog	||= 'Amin::Machine::Log::Standard';
my $DefaultMachine ||= 'Amin::Machine::Dispatcher';

sub new {
	my $class = shift;
	my %args = @_;
	my $self;
	
	if ( defined $args{Handler} ) {
		if ( ! ref( $args{Handler} ) ) {
			my $handler_class =  $args{Handler};
			eval "require $handler_class";
			$args{Handler} = $handler_class->new();
		}
	} else {
		eval "require $DefaultSAXHandler";
        	$args{Handler} = $DefaultSAXHandler->new();
	}
	
	if ( defined $args{Generator} ) {
		if ( ! ref( $args{Generator} ) ) {
			my $generator_class =  $args{Generator};
			eval "use $generator_class";
			$args{Generator} = $generator_class->new();
		}
	} else {
	       	eval "use $DefaultSAXGenerator";
		$args{Generator} = $DefaultSAXGenerator->new();
	}
	
	if (!defined $args{Machine_Name} ) {
		$args{Machine_Name} = $DefaultMachine;
	}	
	
	
	if ( defined $args{Log} ) {
		if ( ! ref( $args{Log} ) ) {
			my $log_class =  $args{Log};
			eval "use $log_class";
			$args{Log} = $log_class->new(Handler => $args{Handler}); 
		}
	} else {
	       	eval "use $DefaultLog";
		$args{Log} = $DefaultLog->new(Handler => $args{Handler});
	}
	
	$args{FILTERLIST} ||= [];
	$self = bless \%args, $class;
	return $self;
}

sub parse_uri {
	my ($self, $profile) = @_;
	
	my $spec;
	if ($self->{Machine_Spec}) {
		$spec = $self->machine_spec($profile, $self->{Machine_Spec})
	} else {
		$spec = $self->machine_spec($profile)
	}

	#load modules from the new $spec
	$spec = $self->load_spec($spec);
	
	#build the machine and run it
	eval "require $self->{Machine_Name}";
	my $m = $self->{Machine_Name}->new($spec);
	while ($m->parse_uri( $profile )) {
		if ($spec->{Handler}->{Spec}->{Buffer_End}) {
			return $spec->{Handler}->{Spec}->{Buffer};
			#$self->{Buffer} = $spec->{Handler}->{Spec}->{Buffer};
			#$spec->{Handler}->{Spec}->{Buffer} = ();
			#$self->{Buffer_End} = $spec->{Handler}->{Spec}->{Buffer_End};
			#last;
		}# elsif ($spec->{Handler}->{Spec}->{Buffer}) {
		#	$self->{Buffer} = $spec->{Handler}->{Spec}->{Buffer};
		#	$spec->{Handler}->{Spec}->{Buffer} = ();
		#}
	}
}

sub parse_string {
	my ($self, $profile) = @_;
	
	#parse and add the machine spec
	my $spec;
	if ($self->{Machine_Spec}) {
		$spec = $self->machine_spec($profile, $self->{Machine_Spec})
	} else {
		$spec = $self->machine_spec($profile)
	}

	#load modules from the new $spec
	#my $spec = $self->load_spec($spec);
	
	#build the machine and run it
	eval "require $self->{Machine_Name}";
	my $m = $self->{Machine_Name}->new($spec);
	while ($m->parse_string( $profile )) {
		if ($spec->{Handler}->{Spec}->{Buffer_End}) {
			return $spec->{Handler}->{Spec}->{Buffer};
			#$self->{Buffer} = $spec->{Handler}->{Spec}->{Buffer};
			#$spec->{Handler}->{Spec}->{Buffer} = ();
			#$self->{Buffer_End} = $spec->{Handler}->{Spec}->{Buffer_End};
			#last;
		}# elsif ($spec->{Handler}->{Spec}->{Buffer}) {
		#	$self->{Buffer} = $spec->{Handler}->{Spec}->{Buffer};
		#	$spec->{Handler}->{Spec}->{Buffer} = ();
		#}
	}
}

sub machine_spec {
	my ($self, $profile, $uri) = @_;
	my $h;
	
	if (defined $uri) {	
		$h = Amin::Machine::Machine_Spec->new('URI' => $uri);
	} else {
		$h = Amin::Machine::Machine_Spec->new();
	}
	
	my $ix = XML::Filter::XInclude->new(Handler => $h);
	my $p = XML::SAX::PurePerl->new(Handler => $ix);
	
	my $spec;
	if ($profile =~ /^</) {
		$spec = $p->parse_string($profile);
	} else {
		$spec = $p->parse_uri($profile);
	}
	unless ($spec) {
		$spec = {};
	}
	

	return $spec;
}



sub load_spec {
	my ($self, $spec) = @_;

	#stick in our filter params
	if (!$spec->{Filter_Param}) { $spec->{Filter_Param} = $self->{Filter_Param}; }
	
	#load up the generator, handler and the log mechanisms if not already loaded
	#ie they came from the spec. 
	
	if ($spec->{Generator}->{name}) {
		#there was a generator in the spec use it
		no strict 'refs';
		eval "require $spec->{Generator}";
		$spec->{Generator} = $spec->{Generator}->new();
		if ($@) {
			my $text = "Machines failed. Could not load a generator named $spec->{Generator}. Reason $@";
			die $text;
		}
		
	} else { 
		#there was no generator in the spec use the default loaded
		$spec->{Generator} = $self->{Generator}; 
	}
	
	if ($spec->{FHandler}->{name}) {
		#there was a Handler in the spec use it
		no strict 'refs';
		eval "require $spec->{FHandler}->{name}";
		
		if ($spec->{FHandler}->{out}) {
			$spec->{Handler} = $spec->{FHandler}->{name}->new(Output => $spec->{FHandler}->{out});
		} else {		
			$spec->{Handler} = $spec->{FHandler}->{name}->new();
		}
		
		if ($@) {
			my $text = "Machines failed. Could not load a handler named $spec->{FHandler}. Reason $@";
			die $text;
		}
		
	} else { 
		#there was no Handler in the spec use the default loaded
		$spec->{Handler} = $self->{Handler};
	}
	
	if ($spec->{Log}->{name}) {
		#there was a log in the spec use it
		no strict 'refs';
		eval "require $spec->{Log}";
		$spec->{Log} = $spec->{Log}->new(Handler => $spec->{Handler} );
		if ($@) {
			my $text = "Machines failed. Could not load a log named $spec->{Log}. Reason $@";
			die $text;
		}
		
	} else { 
		#there was no log in the spec use the default loaded
		$spec->{Log} = $self->{Log};
	}
	
	return $spec;
	
}





1;

__END__

=head1 Name

Amin::Machines - base module for all Amin Machines

=head1 Example

	my $m = Amin::Machines->new (
				Machine_Name => $self->{Machine_Name}, 
				Machine_Spec => $self->{Machine_Spec},
				Generator => $self->{Generator},
				Handler => $self->{Handler},
				Filter_Param => $self->{Filter_Param},
				Log => $self->{Log}
    	);
	my $mout = $m->parse_uri($profile);

=head1 Description

Amin::Machines is the base module for all Amin Machines.
Use this module to access the various Amin Machines. 

An Amin Machine is a collection of simple/complex SAX 
chains that are controlled by a machine spec. A machine
spec is feed to Amin Machines via a xml document or 
by the internal default Amin machine spec. This entire
module is based on supplying the proper spec to the 
correct machine. See the methods for more info.

=head1 Methods 

=over 4

=item *new

this method has several options and these ex. options 
are also the defaults

	Handler => 'XML::SAX::Writer',
	Generator => 'XML::SAX::PurePerl',
	Machine_Name => 'Amin::Machine::Dispatcher',
	Log => 'Amin::Machine::Log::Standard'
	
=item *parse_uri

	this method will get the Machine_Spec set up via new.
	this method will parse the spec and will add other 
	elements like Generator, Handler, Filter_Param, etc.
	if it is not definied in the spec. 
	
	the method then will build and run the machine.
	
	finally it will return the machine's output.
	
=item *parse_string

	this method is the same as parse_uri except
	it accepts a string of xml instead of a uri to xml.

=item *machine_spec

	this is more of an internal method, but you can 
	use it, if you are remaking your own machines....
	it accepts two arguments, the profile to be parsed
	and the machine_spec. It will load the machine 
	spec and check against the profiles using 
	Amin::Machine::Machine_Spec. Please see that module
	for more details. This method also uses XML::Filter::XInclude
	so that XIncludes work in a machine_spec.
	
=back

=cut