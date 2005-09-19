package Amin;

use strict;
use XML::Filter::XInclude;
use XML::SAX::Writer;
use XML::SAX::PurePerl;
use Amin::Machines;
use Amin::Machine::AdminList;
use Amin::Machine::NetworkMap;
#use Amin::Machine::AdminList::Map;
use Sort::Naturally;

#use XML::SAX::Expat;

use vars qw($VERSION);
$VERSION = '0.5.0';


#defaults
my $DefaultSAXHandler ||= 'XML::SAX::Writer';
my $DefaultSAXGenerator	||= 'XML::SAX::PurePerl';
#my $DefaultSAXGenerator ||= 'XML::SAX::Expat';
my $DefaultLog	||= 'Amin::Machine::Log::Standard';
my $DefaultMachine ||= 'Amin::Machine::Dispatcher';


sub new {
	my $class = shift;
	my %args = @_;
	my $self;
	if (!defined $args{Machine_Name} ) {
		$args{Machine_Name} = $DefaultMachine;
	}	
	if (!defined $args{Generator} ) {
		$args{Generator} = $DefaultSAXGenerator;
	}
	if (!defined $args{Handler} ) {
        	$args{Handler} = $DefaultSAXHandler;
	}
	if (!defined $args{Log} ) {
		$args{Log} = $DefaultLog;
	}
	$self = bless \%args, $class;
	return $self;
}

sub parse_adminlist {
	my $self = shift;
	my $adminlist = shift;

	my @networkmap;
	my @adminlists;
	my @profiles;
	my $simplemap;
	
	my $h = Amin::Machine::AdminList->new();
	my $p = XML::SAX::PurePerl->new(Handler => $h);
	my $adminlist = $p->parse_uri($adminlist);
	
	#get/parse/load the adminlist/class map
	#this is used for when people name="" their 
	#adminlists and then use the map to specify
	#which names they want to run.
	#my $h = Amin::Machine::AdminList::Name->new();
	#my $h;
	#my $p = XML::SAX::PurePerl->new(Handler => $h);
	#my $adminlist_map = $p->parse_uri($self->{adminlist_map});
	
	foreach my $key (nsort keys %$adminlist) {
#		if (($key =~ m/server/) || ($adminlist_map->{key})) {
		if ($key =~ m/server/) {
			my $n = Amin::Machine::NetworkMap->new();
			my $np = XML::SAX::PurePerl->new(Handler => $n);
			$simplemap = $np->parse_uri($adminlist->{$key});
			foreach my $map (@$simplemap) {
				if ($map eq undef) {
					next;
				} else {
					push @networkmap, $map;
				}
			}
		}
#		if (($key =~ m/profile/) || ($adminlist_map->{key})) {
		if ($key =~ m/profile/) {
			push @profiles, $adminlist->{$key};
		}
#		if (($key =~ m/adminlist/) || ($adminlist_map->{key})) {
		if ($key =~ m/adminlist/) {
			push @adminlists, $adminlist->{$key};
		}
	}
		
	#deal with adminlists within adminlists
	#we have to repeat ourselves for a while....
	foreach (@adminlists) {
		my $ih = Amin::Machine::AdminList->new();
		my $ip = XML::SAX::PurePerl->new(Handler => $ih);
		my $iadminlist = $ip->parse_uri($_);
		
		foreach my $key (nsort keys %$iadminlist) {
	#		if (($key =~ m/server/) || ($adminlist_map->{key})) {
			if ($key =~ m/server/) {
				my $n = Amin::Machine::NetworkMap->new();
				my $np = XML::SAX::PurePerl->new(Handler => $n);
				$simplemap = $np->parse_uri($iadminlist->{$key});
				foreach my $map (@$simplemap) {	
					if ($map eq undef) {
						next;
					} else {
						push @networkmap, $map;
					}
				}
			}
	#		if (($key =~ m/profile/) || ($adminlist_map->{key})) {
			if ($key =~ m/profile/) {
				push @profiles, $iadminlist->{$key};
			}
	#		if (($key =~ m/adminlist/) || ($adminlist_map->{key})) {
			if ($key =~ m/adminlist/) {
				push @adminlists, $iadminlist->{$key};
			}
		}
	}
	
	my $mout;
	if (@networkmap) {
		foreach my $networkmap (@networkmap) {
			my $protocol = $networkmap->{protocol};
			foreach my $profile (@profiles) {
				if ($profile =~ /^</) {
				#	$mout = $protocol->parse_string($nm->{$networkmap}, $profile, $adminlist_map);
				} else {
				#	$mout = $protocol->parse_uri($nm->{$networkmap}, $profile, $adminlist_map);
				}
			}
		}
	} else {
		foreach my $profile (@profiles) {
			if ($profile =~ /^</) {
				$mout = $self->parse_string($profile);
			} else {
				$mout = $self->parse_uri($profile);
			}
		}
	}
}

sub parse_string {
	my ($self, $profile) = @_;
	my $m = Amin::Machines->new (
				Machine_Name => $self->{Machine_Name}, 
				Machine_Spec => $self->{Machine_Spec},
				Generator => $self->{Generator},
				Handler => $self->{Handler},
				Filter_Param => $self->{Filter_Param},
				Log => $self->{Log}
    	);
	my $mout;
	if ($self->{NetworkMap}) {
		my $h = Amin::Machine::NetworkMap->new();
		my $p = XML::SAX::PurePerl->new(Handler => $h);
		my $nm = $p->parse($self->{NetworkMap});
		
		#my @networkmap;	
		foreach my $networkmap (keys %$nm) {
			my $protocol = $networkmap->{protocol};
			$mout = $protocol->parse_string($nm->{$networkmap},$profile);
		}
	} else {
		$mout = $m->parse_string($profile);
	}
	return \$mout;
}

sub parse_uri {
	my ($self, $uri) = @_;
	my $m = Amin::Machines->new (
				Machine_Name => $self->{Machine_Name}, 
				Machine_Spec => $self->{Machine_Spec},
				Generator => $self->{Generator},
				Handler => $self->{Handler},
				Filter_Param => $self->{Filter_Param},
				Log => $self->{Log}
    	);
	my $mout;
	if ($self->{NetworkMap}) {
		my $h = Amin::Machine::NetworkMap->new();
		my $p = XML::SAX::PurePerl->new(Handler => $h);
		my $nm = $p->parse_uri($self->{NetworkMap});
		
		#my @networkmap;	
		foreach my $networkmap (keys %$nm) {
			my $protocol = $nm->{$networkmap}->{protocol};
			$mout = $protocol->parse_uri($nm->{$networkmap}, $uri);
		}
	
	} else {
		$mout = $m->parse_uri($uri);
	}
	return \$mout;
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
