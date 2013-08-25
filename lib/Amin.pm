package Amin;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use Amin::Machine::Machine_Spec;
use Amin::Machine::Filter::XInclude;
use Amin::URI qw(is_uri);

use vars qw($VERSION);
$VERSION = '0.6.0';

sub new {
	my $class = shift;
	my %args = @_;
	my $self;

    my %defaults = (
        'Handler' => 'Amin::Machine::Handler::Writer',
        'Generator' => 'XML::SAX::PurePerl',
        'Log'  => 'Amin::Machine::Log::Standard',
        'Machine_Name' => 'Amin::Machine::Dispatcher'
    );

    my @types = qw(Handler Generator Machine_Name Log);
    foreach my $type (@types) {
        if (($type eq "Machine_Name") && (!defined $args{Machine_Name})) {
            $args{Machine_Name} = $defaults{$type};
        } else {
            if ( defined $args{$type} ) {
                if ( ! ref( $args{$type} ) ) {
                    eval "require $args{$type}";
                    $args{$type} = $args{$type}->new();
                }
            } else {
                eval "require $defaults{$type}";
                $args{$type} = $defaults{$type}->new();
            }
        }
    }

	$args{FILTERLIST} ||= [];
	$self = bless \%args, $class;
	return $self;
}


sub parse {
	my ($self, $profile) = @_;
    #load the spec parts that are involved in this machine parse
    my $uri = is_uri($profile);
    my $h;
    if ($uri) {
        $h = Amin::Machine::Machine_Spec->new('URI' => $uri);
    } else {
        $h = Amin::Machine::Machine_Spec->new();
    }
    my $ix = Amin::Machine::Filter::XInclude->new(Handler => $h);
    my $p = XML::SAX::PurePerl->new(Handler => $ix);
    my $spec = {};
    if ($uri) {
        $spec = $p->parse_uri($uri);
    } else {
        $spec = $p->parse_string($profile);
    }
    my @names = qw(Machine_Name Filter_Param Debug);
    foreach my $name (@names) {
        if ($spec->{$name}) {
            #there was a name in the spec use it
            $self->{$name} = $spec->{$name};
        } else {
            #there was no name in the spec use default
            $spec->{$name} = $self->{$name};
        }
    }
    #stick in our filter params
    $spec->{Filter_Param} = $self->{Filter_Param}; 
    #add debug info to the $spec
    if ($self->{Debug}) {
        $spec->{Debug} = $self->{Debug};
    }
    #add in the rest of the parts
    my @parts = qw(Generator Handler Log);
    foreach my $part (@parts) {
        if ($spec->{$part}->{name}) {
            if (! ref($spec->{$part})) {
                #there was a part in the spec use it
                no strict 'refs';
                eval "require $spec->{$part}";
                if ($spec->{$part}->{out}) {
                    $spec->{$part} = $spec->{$part}->{name}->new(Output => $spec->{$part}->{out});
                } else {
                    $spec->{$part} = $spec->{$part}->{name}->new();
                }
                if ($@) {
                    my $text = "Could not load a $part named $spec->{$part}. Reason $@";
                    die $text;
                }
            }
        } else { 
            #there was no part in the spec use the default
            $spec->{$part} = $self->{$part}; 
        }
    }
	#build the machine and run it
	eval "require $self->{Machine_Name}";
	my $m = $self->{Machine_Name}->new($spec);
	$m->parse_uri($profile);
	#cleanup this machine
    $m->finish();
	return $spec->{Buffer};
}

sub parse_adminlist {
    my ($self, $cli) = @_;
    my $h = Amin::Machine::AdminList->new;
    my $p = XML::SAX::PurePerl->new(Handler => $h);
    return $p->parse_uri($cli->adminlist);
}

sub parse_networkmap {
    my ($self, $networkmap) = @_;
    my $n = Amin::Machine::NetworkMap->new();
    my $np = XML::SAX::PurePerl->new(Handler => $n);
    return $np->parse_uri($networkmap);
}

sub parse_CLIOutput {
    my ($self, $clioutput) = @_;
    my $h = Amin::Controller::CLIOutput->new();
    my $p = XML::SAX::PurePerl->new(Handler => $h);
    return $p->parse_string($clioutput);
}

sub parse_adminlistmap {
    my ($self, $adminlist_map) = @_;
    my $h = Amin::Machine::AdminList::Name->new();
    my $p = XML::SAX::PurePerl->new(Handler => $h);
    return $p->parse_uri($adminlist_map);
}

sub handler {
    my $self = shift;
    $self->{Handler} = shift if @_;
    return $self->{Handler};
}

sub generator {
    my $self = shift;
    $self->{Generator} = shift if @_;
    return $self->{Generator};
}

sub log {
    my $self = shift;
    $self->{Log} = shift if @_;
    return $self->{Log};
}

sub network_map {
    my $self = shift;
    $self->{Network_Map} = shift if @_;
    return $self->{Network_Map};
}

sub machine_spec {
    my $self = shift;
    $self->{Machine_Spec} = shift if @_;
    return $self->{Machine_Spec};
}

sub machine_type {
    my $self = shift;
    $self->{Machine_Type} = shift if @_;
    return $self->{Machine_Type};
}

sub filter_param {
    my $self = shift;
    $self->{Filter_Param} = shift if @_;
    return $self->{Filter_Param};
}

sub results {
	my $self = shift;
	if (@_) {push @{$self->{RESULTS}}, @_; }
	return @{ $self->{RESULTS} };
}

sub debug {
    my $self = shift;
    $self->{Debug} = shift if @_;
    return $self->{Debug};
}

sub adminlist_map {
    my $self = shift;
    $self->{Adminlist_Map} = shift if @_;
    return $self->{Adminlist_Map};
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
  Amin and Amin machine types.

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


=item *adminlist_map

This method will get or set the adminlist_map 
uri reference. See Amin::Machine::AdminList::Map
for more information.

=item *handler

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

=item *log

The set_log and get_log methods will set or get the log mechanism
for the machine. The default Amin machine log is Amin::Log::Standard.   

=item *machine_spec

The set_machine_spec and get_machine_spec methods will set or get 
the default machine spec. The default Amin machine spec is the
core Amin filter set, with the other defaults mentioned here. For
more information look at Amin::Machine::Machine_Spec.

=item *machine_type

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
