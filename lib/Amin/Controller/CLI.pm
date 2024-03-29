package Amin::Controller::CLI;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use LWP::UserAgent;
use Getopt::Long;
sub new {
	my $class = shift;
	my %args = @_;
	my $self;
	$self = bless \%args, $class;
	return $self;
}

sub get_opts {
    my $cli = shift;
    my ($help, $uri, $profile, $adminlist, $networkmap, $machine_spec, 
        $machine_type, $machine_name, $generator, $handler, $log, 
        $filter_param, $version, $type, $adminlist_map, $packagelist, 
        $packagelist_map, $debug);
    my $opts_ok = &GetOptions( "h|help"    => \$help,
                   "u|uri=s"     => \$uri,
                   "p|profile=s" => \$profile,
                   "a|adminlist=s" => \$adminlist,
                   "b|adminlist_map=s" => \$adminlist_map,
                   "n|networkmap=s" => \$networkmap,
                   "m|machine_spec=s" => \$machine_spec,
                   "o|machine_name=s" => \$machine_name,
                   "d|debug=s" => \$debug,
                   "g|generator=s" => \$generator,
                   "ha|handler=s" => \$handler,
                   "l|log=s" => \$log,
                   "x|filter_param=s" => \$filter_param,
                   "t|machine_type=s" => \$type,
                   "v|version" => \$version,
                   "pa|packagelist=s" => \$packagelist,
                   "pal|packagelist_map=s" => \$packagelist_map,
    );

    if ( $help ) {
            $cli->print_help();
            exit 1;
    }
    if ($uri) {
        $cli->uri($uri);
    } 
    if ($profile) {
        $cli->profile($profile);
    } 
    if ($adminlist) {
        $cli->adminlist($adminlist);
    } 
    if ($adminlist_map) {
        $cli->adminlist_map($adminlist_map);
    } 
    if ($networkmap) {
        $cli->networkmap($networkmap);
    }
    if ($machine_spec) {
        $cli->machine_spec($machine_spec);
    } 
    if ($debug) {
        $cli->debug($debug);
    } 
    if ($filter_param) {
        $cli->filter_param($filter_param);
    } 
    if ($machine_type) {
        $cli->machine_type($machine_type);
    } 
    if ($machine_name) {
        $cli->machine_name($machine_name);
    } 
    if ($generator) {
        $cli->generator($generator);
    } 
    if ($handler) {
        $cli->handler($handler);
    } 
    if ($log) {
        $cli->log($log);
    } 
    if ($packagelist) {
        $cli->packagelist($packagelist);
    } 
    if ($packagelist_map) {
        $cli->packagelist_map($packagelist_map);
    }
    if ($version) {
        $cli->print_version();
                exit 1;
    } 
    if (!$opts_ok) {
            $cli->print_usage();
            exit 1;
    };
    if ((!$uri) && (!$profile) && (!$adminlist) && 
        (!$networkmap) && (!$version) && (!$help)) {    
        $cli->print_usage();
        exit  1;
    }
}

sub load_profile {
	my ($self, $uri) = @_;
	my $ua = LWP::UserAgent->new();
	$ua->agent("Amin/v1.0"); #Our kewl browser
	my $request = HTTP::Request->new(GET => $uri);
	my $response = $ua->request($request);
	my $profile=$response->content();
	return $profile;
}

sub print_version {
	my $self = shift;
	my $version = shift || $self->version;
	my $head = "Version: $version";
	print $head,  "\n";
}

sub print_usage {
	my $self = shift;
	my $usage = shift || $self->usage;
        my $head = "Usage: $0 ";
        print $head,   "\n\n";
        print $usage, "\n";
}

sub print_help {
	my $self = shift;
	my $help = shift || $self->help;
	my $head = "Help: ";
	print $head, "\n";
	print $help, "\n";
}

sub networkmap {
	my $self = shift;
	if (@_) { $self->{NETWORKMAP} = shift;}
	return $self->{NETWORKMAP};
}

sub machine_spec {
	my $self = shift;
	if (@_) { $self->{MACHINE_SPEC} = shift;}
	return $self->{MACHINE_SPEC};
}

sub help {
	my $self = shift;
	if (@_) { $self->{HELP} = shift;}
	return $self->{HELP};
}

sub usage {
	my $self = shift;
	if (@_) { $self->{USAGE} = shift;}
	return $self->{USAGE};
}

sub version {
	my $self = shift;
	if (@_) { $self->{VERSION} = shift;}
	return $self->{VERSION};
}

sub profile {
	my $self = shift;
	if (@_) { $self->{PROFILE} = shift;}
	return $self->{PROFILE};
}

sub machine_type {
	my $self = shift;
	if (@_) { $self->{MACHINE_TYPE} = shift;}
	return $self->{MACHINE_TYPE};
}

sub machine_name {
	my $self = shift;
	if (@_) { $self->{MACHINE_NAME} = shift;}
	return $self->{MACHINE_NAME};
}

sub debug {
	my $self = shift;
	if (@_) { $self->{Debug} = shift;}
	return $self->{Debug};
}

sub arg {
	my $self = shift;
	if (@_) { $self->{ARG} = shift;}
	return $self->{ARG};
}

#this is here for ainit or other controllers that
#do not use a setup like amin does for it's get_opts
#ie it's a loop for ainit pid 1 or not and not just
#options from the cli interface used...
sub good {
	my $self = shift;
	if (@_) { $self->{GOOD} = shift;}
	return $self->{GOOD};
}


sub argname {
	my $self = shift;
	if (@_) { $self->{ARGNAME} = shift;}
	return $self->{ARGNAME};
}




sub generator {
	my $self = shift;
	if (@_) { $self->{GENERATOR} = shift;}
	return $self->{GENERATOR};
}

sub handler {
	my $self = shift;
	if (@_) { $self->{HANDLER} = shift;}
	return $self->{HANDLER};
}

sub log {
	my $self = shift;
	if (@_) { $self->{LOG} = shift;}
	return $self->{LOG};
}

sub uri {
	my $self = shift;
	if (@_) { $self->{URI} = shift;}
	return $self->{URI};
}

sub filter_param {
	my $self = shift;
	if (@_) { $self->{FILTER_PARAM} = shift;}
	return $self->{FILTER_PARAM};
}

sub adminlist {
	my $self = shift;
	if (@_) { $self->{ADMINLIST} = shift;}
	return $self->{ADMINLIST};
}

sub adminlist_map {
	my $self = shift;
	if (@_) { $self->{ADMINLIST_MAP} = shift;}
	return $self->{ADMINLIST_MAP};
}

sub packagelist {
    my $self = shift;
    if (@_) { $self->{PACKAGELIST} = shift;}
    return $self->{PACKAGELIST};
}

sub packagelist_map {
    my $self = shift;
    if (@_) { $self->{PACKAGELIST_MAP} = shift;}
    return $self->{PACKAGELIST_MAP};
}

1;

__END__


=head1 Name

Amin::Controller::CLI - base library class for Amin CLI controllers

=head1 Methods 

=over 4

=item *new

this method will accept any arguments you
supply to the object. Use this to create 
options for your controller that are not 
already available in this module. 

=item *load_profile

this method is a convenient way to read a profile
into a string, from any uri. supply the method a 
profile via a uri and the method will return you a 
string version of said profile from that uri

=item *print_version 

this method will print out the version supplied
in a CLI format.

=item *print_usage 

this method will print out the usage supplied
in a CLI format. Also the program's name is 
referenced through $0.

=item *print_help 

this method will print out the help supplied
in a CLI format.

=item *filter_param 

this method will collect multiple filter_param items

=item *single item helper methods

All of these methods below are helper methods for common
amin controller options. Each item stores a single
item. 

=over 8 

=item *networkmap 

=item *machine_spec 

=item *help

=item *usage

=item *version

=item *profile

=item *machine_type

=item *uri

=item *adminlist

=item *adminlist_map

=back

=back

=cut
