package Amin;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use Amin::Machine::Machine_Spec;
use Amin::Machine::Filter::XInclude;

my $DefaultSAXHandler ||= 'Amin::Machine::Handler::Writer';
my $DefaultSAXGenerator	||= 'XML::SAX::PurePerl';
my $DefaultLog	||= 'Amin::Machine::Log::Standard';
my $DefaultMachine ||= 'Amin::Machine::Dispatcher';

use vars qw($VERSION);
$VERSION = '0.5.4';

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
	$m->parse_uri( $profile );
	#get rid of the filter list...
	my $fl = $spec->{Filter_List};
	foreach (keys %$fl) {
		delete $fl->{$_};
	}
	$spec->{Filter_List} = $fl;
	my $buffer = $spec->{Handler}->{Spec}->{Buffer};
	$spec->{Handler}->{Spec}->{Buffer} = undef;	
	return $buffer;
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
	$spec = $self->load_spec($spec);
	#build the machine and run it
	eval "require $spec->{Machine_Name}";
	my $m = $spec->{Machine_Name}->new($spec);
	$m->parse_string( $profile );
	#get rid of the filter list...
	my $fl = $spec->{Filter_List};
	foreach (keys %$fl) {
		delete $fl->{$_};
	}
	$spec->{Filter_List} = $fl;
	my $buffer = $spec->{Handler}->{Spec}->{Buffer};
	$spec->{Handler}->{Spec}->{Buffer} = undef;	
	return $buffer;
}

sub machine_spec {
	my ($self, $profile, $uri) = @_;
	my $h;
	if (defined $uri) {	
		$h = Amin::Machine::Machine_Spec->new('URI' => $uri);
	} else {
		$h = Amin::Machine::Machine_Spec->new();
	}
	my $ix = Amin::Machine::Filter::XInclude->new(Handler => $h);
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
	$spec->{Filter_Param} = $self->{Filter_Param}; 
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
	if ($spec->{Log}) {
		#there was a log in the spec use it
		if (! ref($spec->{Log})) {
		no strict 'refs';
		eval "require $spec->{Log}";
		$spec->{Log} = $spec->{Log}->new(Handler => $spec->{Handler} );
		if ($@) {
			my $text = "Machines failed. Could not load a log named $spec->{Log}. Reason $@";
			die $text;
		}
		}
	} else { 
		#there was no log in the spec use the default loaded
		$spec->{Log} = $self->{Log};
	}
	if ($spec->{Machine_Name}) {
		#there was a machine name in the spec use it
		$self->{Machine_Name} = $spec->{Machine_Name};
	} elsif (!$spec->{Machine_Name}) {
		#there was no machine name in the spec use default
		$spec->{Machine_Name} = $self->{Machine_Name};
	}
	#add debug info to the $spec
	if ($self->{Debug}) {
		$spec->{Debug} = $self->{Debug};
	}
	
	return $spec;
}




sub set_handler {
	my $self = shift;
	my $handler = shift;
	$self->{Handler} = $handler;
}

sub get_handler {
	my $self = shift;
	return $self->{Handler};
}

sub set_generator {
	my $self = shift;
	my $generator = shift;
	$self->{Generator} = $generator;
}

sub get_generator {
	my $self = shift;
	return $self->{Generator};
}

sub set_log {
	my $self = shift;
	my $log = shift;
	$self->{Log} = $log;
}

sub get_log {
	my $self = shift;
	return $self->{Log};
}

sub set_networkmap {
	my $self = shift;
	my $networkmap = shift;
	$self->{NetworkMap} = $networkmap;
}

sub get_networkmap {
	my $self = shift;
	return $self->{NetworkMap};
}

sub set_machine_spec {
	my $self = shift;
	my $machine_spec = shift;
	$self->{Machine_Spec} = $machine_spec;
}

sub get_machine_spec {
	my $self = shift;
	return $self->{Machine_Spec};
}

sub set_machine_type {
	my $self = shift;
	my $machine_type = shift;
	$self->{Machine_Type} = $machine_type;
}

sub get_machine_type {
	my $self = shift;
	return $self->{Machine_Type};
}

sub set_filter_param {
	my $self = shift;
	my $filter_param = shift;
	$self->{Filter_Param} = $filter_param;
}

sub get_filter_param {
	my $self = shift;
	return $self->{Filter_Param};
}

sub results {
	my $self = shift;
	if (@_) {push @{$self->{RESULTS}}, @_; }
	return \@{ $self->{RESULTS} };
}

sub set_debug {
	my $self = shift;
	my $debug = shift;
	$self->{Debug} = $debug;
}

sub get_debug {
	my $self = shift;
	return $self->{Debug};
}


sub set_adminlist_map {
	my $self = shift;
	my $adminlist_map = shift;
	$self->{AdminList_Map} = $adminlist_map;
}

sub get_adminlist_map {
	my $self = shift;
	return $self->{AdminList_Map};
}

1;

__END__

=head1 Name

Amin - base class for Amin controllers

=head1 Example

  sample cli controller

  #!/usr/bin/perl

  use Amin;
  use Amin::Controller::CLI; 
  use Getopt::Long;
  use strict;

  my $profile;
  # A:C:C is just a helper/storage object not mandatory
  my $cli = Amin::Controller::CLI->new();
  my $help = (<<END);
  help here
  END
  # define help
  $cli->help($help);

  # define usage
  my $usage = (<<END);
  usage here
  END
  $cli->usage($usage);

  # define version
  my $version = "2.0";
  $cli->version($version);

  # pass the $cli object to the controller's 
  # get_profile function.
  #
  # this function will use Getopt::Long to get all 
  # the details from the command line to change the 
  # $cli object

  get_profile($cli);

  # initialize Amin
  my $amin = Amin->new();

  # $cli->profile exists from the get_profile function
  $results = $amin->parse_string($cli->profile);

  # or say your setup was uri based

  # $cli->uri exists from the get_profile function
  $results = $amin->parse_uri($cli->uri);

  # you can always try
  $results = $amin->parse($cli->whatever);
  #and let Amin figure it out
    
  print $results;

=head1 Description

  This is the base class for an Amin controller. This 
  module is used by a contoller to set various machine 
  settings, and to send/receive an Amin profile. 
  
  How a controller is designed, what standards, protocols,
  etc. it conforms to is left to the designer. Amin will 
  help provide you with all the normal machine options, 
  and helper modules for your controller. 
  
  It is a good idea to review SAX before you get lost in 
  Amin and Amin::Machines.

=head1 Methods 

=over 4

=item *new
   
=item *parse_uri

accepts any standard URI usable by LWP. ie 
http://, https://, file://, ftp:// etc.

will return the machine output as a scalar reference

ex. 

my $mout = $amin->parse_uri($my_uri);

print $mout;

=item *parse_string

similiar to parse_uri but accepts a xml document
as a string instead of a uri.

will return the machine output as a scalar reference

ex. 

my $mout = $amin->parse_string($my_string);

print $mout;

=item *parse_adminlist

accepts any adminlist from a standard uri. ie like
parse_uri. This method will parse the original adminlist.
It will parse any additional networkmaps and adminlist(s)
within that original adminlist. This will continue on 
ad-infitum, and if you hook adminlists in a circle link
fashion will continue to process the adminlists within
adminlists that link to each other forever....

So don't do it. Want to see how fast Amin can take down
your machine? Then do it... :)

This method also uses the adminlist_map internal method
to check for the correcting mappings during adminlist 
processing. See adminlist_map or Amin::Machine::AdminList::Map
for more information.


=item *set_adminlist_map/get_adminlist_map

This method will get or set the adminlist_map 
uri reference. See Amin::Machine::AdminList::Map
for more information.

=item *set_filter/get_filter

The set_filter and get_filter methods will set or get
the list of filters for the machine. There are no default 
filters.

=item *set_handler/get_handler

The set_handler and get_handler methods will set or get
the handler for the machine. The default Amin machine handler is 
XML::SAX::Writer(Output => \$xswout) and $xswout is return from
any parse_methods. If you want the Amin machine to not use $xswout
and instead just return machine output to STDOUT, then do this

$amin->set_handler('XML::SAX::Writer');

Any parse_methods will still return $xswout, but it will
be undefined. 
   
=item *set_generator/get_generator

The set_generator and get_generator methods will set or 
get the generator for the machine. The default Amin machine 
handler is XML::SAX::PurePerl.   

=item *set_log/get_log

The set_log and get_log methods will set or get the log mechanism
for the machine. The default Amin machine log is Amin::Log::Standard.   

=item *set_machine_spec/get_machine_spec

The set_machine_spec and get_machine_spec methods will set or get 
the default machine spec. The default Amin machine spec is the
core Amin filter set, with the other defaults mentioned here. For
more information look at Amin::Machine::Machine_Spec.

=item *set_machine_type/get_machine_type

The set_machine and get_machine methods will set or get the 
default machine type.The default Amin machine type is 
Dispatcher. The complete list of machine types is

=over 8 

=item *Dispatcher

=back  
 
You call these machine types by using their full module names, ie.

=over 8 

=item *Amin::Machine::Dispatcher

=back 

You may also design your own machines and supply 
their full module names. Please see Amin::Machine 
for more details on building your own machine...

There will be more machine types in the future.   

=item *load_filters

=back

=cut
