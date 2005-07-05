package Amin::Machines;

use strict;
use Amin::Machine::Machine_Spec;


my $DefaultSAXHandler ||= 'XML::SAX::Writer';
my $DefaultSAXGenerator	||= 'XML::SAX::PurePerl';
#my $DefaultSAXGenerator ||= 'XML::SAX::Expat';
my $DefaultLog	||= 'Amin::Machine::Log::Standard';
my $DefaultMachine ||= 'Amin::Machine::Dispatcher';
my $mout;

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
        	$args{Handler} = $DefaultSAXHandler->new(Output => \$mout);
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
		$args{Log} = $DefaultLog->new();
	}
	
	$args{FILTERLIST} ||= [];
	$self = bless \%args, $class;
	return $self;
}

sub parse_uri {
	my ($self, $profile) = @_;
	
	#parse and add the machine spec
	my $spec;
	if ($self->{Machine_Spec}) {
		$spec = $self->machine_spec($profile, $self->{Machine_Spec})
	} else {
		$spec = $self->machine_spec($profile)
	}

	#prep the spec	
	if (!$spec->{Handler}) { $spec->{Handler} = $self->{Handler}; }
	if (!$spec->{Filter_Param}) { $spec->{Filter_Param} = $self->{Filter_Param}; }
	if (!$spec->{Generator}) { $spec->{Generator} = $self->{Generator}; }

	
	if (!$spec->{Log}) { $spec->{Log} = $self->{Log}; }
	#re-adjust the log
	$spec->{Log}->{Spec} = $spec;

		
	#build the machine and run it
	eval "require $self->{Machine_Name}";
	my $m = $self->{Machine_Name}->new($spec);
	$m->parse_uri( $profile );
	
	return \$mout;
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

	#prep the spec	
	if (!$spec->{Handler}) { $spec->{Handler} = $self->{Handler}; }
	if (!$spec->{Log}) { $spec->{Log} = $self->{Log}; }
	if (!$spec->{Filter_Param}) { $spec->{Filter_Param} = $self->{Filter_Param}; }
	if (!$spec->{Generator}) { $spec->{Generator} = $self->{Generator}; }
	
	#build the machine and run it
	eval "require $self->{Machine_Name}";
	my $m = $self->{Machine_Name}->new($spec);
	$m->parse_string( $profile );
	return \$mout;
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
	#my $p = XML::SAX::Expat->new(Handler => $h);
	
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