test2
testing again 

testing again 
moo!
adding crud here to test 
lets hope this works k, this time :)
add some omre stuff in here 
updated to full path due to lack of $PATH hope this works 
  
package Amin;

use strict;
use Amin::Controller::Filters;
use XML::Filter::XInclude;
use XML::SAX::Writer;
use XML::SAX::PurePerl;

use Amin::Machines qw( :all );

#use XML::SAX::Expat;
#use Data::Dumper;

use vars qw($VERSION $DefaultSAXHandler $DefaultSAXGenerator $DefaultLog $DefaultMachine);

$VERSION = '0.5.0';
#defaults
$DefaultSAXHandler	||= 'XML::SAX::Writer';
$DefaultSAXGenerator	||= 'XML::SAX::PurePerl';
#$DefaultSAXGenerator	||= 'XML::SAX::Expat';
$DefaultLog		||= 'Amin::Log::Standard';
$DefaultMachine		||= 'Dispatcher';

my $xswout;

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
        	$args{Handler} = $DefaultSAXHandler->new(Output => \$xswout);
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
	if ( defined $args{Machine_Type} ) {
		if ( ! ref( $args{Machine_Type} ) ) {
			my $machine = $args{Machine_Type};
			$args{Machine_Type} = $machine;
			$args{Machine} = eval "use Amin::Machines qw($machine)";
		}
	} else {
		$args{Machine_Name} = $DefaultMachine;
		$args{Machine} = eval "use Amin::Machines qw($DefaultMachine)";
	}	
	
	#if ( defined $args{Log} ) {
	#	if ( ! ref( $args{Log} ) ) {
	#		my $log_class =  $args{Log};
	#		eval "use $log_class";
	#		$args{Log} = $log_class->new();
	#	}
	#} else {
	#       	eval "use $DefaultLog";
	#	$args{Log} = $DefaultLog->new();
	#}
	
	$args{FILTERLIST} ||= [];
	$self = bless \%args, $class;
	return $self;
}

sub parse {
	my ($self, $to_be_parsed) = @_;
	my @filterlist = @{$self->{Filterlist}};
	my $m;
	{
	no strict 'refs';
	$m = $self->{Machine_Name} ((@filterlist),$self->{Handler});
	}
    	$self->{Generator}->set_handler( $m );
	
	#figure out what type of item it is
	
	my $type = 
	

	if ($type eq "uri") {
		$self->{Generator}->parse_uri( $to_be_parsed );
	} elsif ($type eq "adminlist") {
	 	$self->parse_adminlist( $to_be_parsed );
	} else {
		$self->{Generator}->parse_string( $to_be_parsed );
	}
	return \$xswout;
}


sub parse_string {
	my ($self, $to_be_parsed) = @_;
	my @filterlist = @{$self->{Filterlist}};
	my $m;
	{
	no strict 'refs';
	$m = $self->{Machine_Name} ((@filterlist),$self->{Handler});
	}
    	$self->{Generator}->set_handler( $m );
	$self->{Generator}->parse_string( $to_be_parsed );
	return \$xswout;
}


sub parse_uri {
	my ($self, $to_be_parsed) = @_;
	my @filterlist = @{$self->{Filterlist}};
	my $m;
	{
	no strict 'refs';
	$m = $self->{Machine_Name} ((@filterlist),$self->{Handler});
	}
    	$self->{Generator}->set_handler( $m );
	$self->{Generator}->parse_uri( $to_be_parsed );
	return \$xswout;
}










sub set_filter {
	my $self = shift;
	if (@_) {push @{$self->{Filterlist}}, @_; }
}

sub set_handler {
    my $self = shift;
    my $handler = shift;
    my $options = shift;
    
    if ( defined( $handler ) ) {
        if ( ! ref( $handler ) ) {
            my $handler_class =  $handler;
            eval "use $handler_class";
	    if (defined($options)) {
	    	$self->{Handler} = $handler_class->new($options);
	    } else {
	    	$self->{Handler} = $handler_class->new();
            }
	}
        else {
            $self->{Handler} = $handler;
        }
    }
}

sub set_generator {
    my $self = shift;
    my $generator = shift;
    if ( defined( $generator ) ) {
        if ( ! ref( $generator ) ) {
            my $generator_class =  $generator;
            eval "use $generator_class";
            $self->{Generator} = $generator_class->new();
        }
        else {
            $self->{Generator} = $generator;
        }
    }
}

sub set_log {
    my $self = shift;
    my $log = shift;
    if ( defined( $log ) ) {
        if ( ! ref( $log ) ) {
            my $log_class =  $log;
            eval "use $log_class";
            $self->{Log} = $log_class->new();
        }
        else {
            $self->{Log} = $log;
        }
    }
}

sub set_machine {
	my $self = shift;
	my $machine = shift;
	$self->{Machine_Name} = $machine;
	$self->{Machine} = eval "use Amin::Machines qw( $machine)";
}

sub get_log {
	my $self = shift;
	return $self->{Log};
}

sub get_machine {
	my $self = shift;
	return $self->{Machine};
}

sub get_generator {
	my $self = shift;
	return $self->{Generator};
}

sub get_handler {
	my $self = shift;
	return $self->{Handler};
}

sub get_filter {
	my $self = shift;
	return @{ $self->{Filterlist} };
}

sub type {
	my $self = shift;
	$self->{Type} = shift if @_;
	return $self->{Type};
}

sub PM_TYPE {
	my $self = shift;
	if (@_) { $self->{PM_TYPE} = shift;}
	return $self->{PM_TYPE};
}

sub PM_PROFILE {
	my $self = shift;
	if (@_) { $self->{PM_PROFILE} = shift;}
	return $self->{PM_PROFILE};
}

sub load_filters {

	my ($self, $profile, $type, $uri) = @_;

	#this runs a simple sax process to collect all
	#the element->{LocalNames}. It also checks against
	#its internal list as not to return localnames that
	#are child xml and not Filters. It also checks for repeats
	#
	#lists may not be internal anymore and internal is only
	#used as the fallback, otherwise look for filters.xml files
	#they contain config info and follow amin config rules
	my $h;
	if (defined $uri) {	
		$h = Amin::Controller::Filters->new('Amin_Filters' => $uri);
	} else {
		$h = Amin::Controller::Filters->new();
	}
	my $ix = XML::Filter::XInclude->new(Handler => $h);
	my $p = XML::SAX::PurePerl->new(Handler => $ix);
	#my $p = XML::SAX::Expat->new(Handler => $h);
	my $filters;
	if ($type eq "uri") {
		$filters = $p->parse_uri($profile);
	} else {
		$filters = $p->parse_string($profile);
	}
	unless (@$filters) {
		$filters = [];
	}
	return @$filters;
}

1;


__END__

=head1 NAME

Amin - base class for Amin machines

=head1 SYNOPSIS

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

=head1 DESCRIPTION

  This is the base class for an Amin controller. This 
  module is used by a contoller to set various machine 
  settings, and to send/receive an Amin profile. 
  
  How a controller is designed, what standards, protocols,
  etc. it conforms to is left to the designer. Amin will 
  help provide you with all the normal machine options, 
  and helper modules for your controller. 
  
  It is a good idea to review SAX and XML::SAX::Machines
  before you get lost in Amin and Amin::Machines.

=head1 Methods 

=over 4

=item *new
   
=item *parse

=item *parse_uri

=item *parse_string

=item *parse_adminlist
   
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
more information look at Amin::Controller::Filters.

=item *set_machine_type/get_machine_type

The set_machine and get_machine methods will set or get the 
default machine type.The default Amin machine type is 
Dispatcher. The complete list of machine types is

=over 8 

=item *Dispatcher

=item *ByRecord

=item *Tap

=back  
 
There will be more machine types in the future.   

=item *load_filters

=back

=cut
