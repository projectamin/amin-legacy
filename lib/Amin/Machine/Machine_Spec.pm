package Amin::Machine::Machine_Spec;

use strict;
use vars qw(@ISA);
use XML::SAX::Base;
use Amin::Machine::Machine_Spec::Document;
use XML::Filter::XInclude;
use XML::SAX::PurePerl;
use IPC::Run qw( run );

@ISA = qw(XML::SAX::Base);

#parent is defined in one of four ways
#1. uri
#2. /etc/amin/machine_spec.xml
#3. ~/.amin/machine_spec.xml
#4. the %filters dataset below

my $home = $ENV{'HOME'};
my $configfile = "$home/.amin/machine_spec.xml";
my $spec;
my @machine_filters;
my @machine_bundle;
my %control;

sub start_document {
	my $self = shift;

	
if ($self->{URI}) {
	#process the uri
	my $h = Amin::Machine::Machine_Spec::Document->new();
	my $x = XML::Filter::XInclude->new(Handler => $h);
	my $p = XML::SAX::PurePerl->new(Handler => $x);
	$spec = $p->parse_uri($self->{URI});	
	$control{ICONTROL} = "yes";
} elsif (-f '/etc/amin/machine_spec.xml') {
	#check if %filters is set
	unless ($control{ICONTROL}) {
		my $uri = "file://etc/amin/machine_spec.xml";
		#process /etc/amin/machine_spec.xml
		my $h = Amin::Machine::Machine_Spec::Document->new();
		my $x = XML::Filter::XInclude->new(Handler => $h);
		my $p = XML::SAX::PurePerl->new(Handler => $x);
		$spec = $p->parse_uri($uri);	
		$control{ICONTROL} = "yes";
	}
} elsif (-f $configfile) {
	#check if %filters is set
	unless ($control{ICONTROL}) {
		my $uri = "file:/" . $configfile;
		#process ~/.amin/machine_spec.xml
		my $h = Amin::Machine::Machine_Spec::Document->new();
		my $x = XML::Filter::XInclude->new(Handler => $h);
		my $p = XML::SAX::PurePerl->new(Handler => $x);
		$spec = $p->parse_uri($uri);	
		$control{ICONTROL} = "yes";
	}


} else {
	#check if %filters is set
	unless ($control{ICONTROL}) {
		#define the parents ie Filters
		
		my %parent;
		my %mkdir = (   
				'module' => 'Amin::Command::Mkdir',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'mkdir',
				'position' => 'middle',
				'version' => '1.0',
				
		);
		#add it
		$parent{$mkdir{module}} = \%mkdir;
	
		my %mount = (
				'module' => 'Amin::Command::Mount',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'mount',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$mount{module}} = \%mount;

		my %textdump = (
				'module' => 'Amin::Command::Textdump',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'textdump',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$textdump{module}} = \%textdump;


		my %ls = (
				'module' => 'Amin::Command::Ls',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'ls',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$ls{module}} = \%ls;


		my %move = (
				'module' => 'Amin::Command::Move',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'move',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$move{module}} = \%move;



		my %amin = (
				'module' => 'Amin::Command::Amin',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'amin',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$amin{module}} = \%amin;


		my %chgrp = (
				'module' => 'Amin::Command::Chgrp',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'chgrp',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$chgrp{module}} = \%chgrp;


		my %chmod = (
				'module' => 'Amin::Command::Chmod',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'chmod',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$chmod{module}} = \%chmod;


		my %chown = (
				'module' => 'Amin::Command::Chown',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'chown',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$chown{module}} = \%chown;


		my %configure = (
				'module' => 'Amin::Command::Configure',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'configure',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$configure{module}} = \%configure;


		my %copy = (
				'module' => 'Amin::Command::Copy',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'copy',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$copy{module}} = \%copy;


		my %cp = (
				'module' => 'Amin::Command::Cp',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'cp',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$cp{module}} = \%cp;


		my %df = (
				'module' => 'Amin::Command::Df',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'df',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$df{module}} = \%df;


		my %du = (
				'module' => 'Amin::Command::Du',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'du',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$du{module}} = \%du;


		my %echo = (
				'module' => 'Amin::Command::Echo',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'echo',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$echo{module}} = \%echo;


		my %iptables = (
				'module' => 'Amin::Command::Iptables',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'iptables',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$iptables{module}} = \%iptables;

                my %ifconfig = (
                                'module' => 'Amin::Command::Ifconfig',
                                'element' => 'command',
                                'namespace' => 'amin',
                                'name' => 'ifconfig',
                                'position' => 'middle',
                                'version' => '1.0',
                );
                $parent{$ifconfig{module}} = \%ifconfig;

		my %link = (
				'module' => 'Amin::Command::Link',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'link',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$link{module}} = \%link;


		my %ln = (
				'module' => 'Amin::Command::Ln',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'ln',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$ln{module}} = \%ln;


		my %make = (
				'module' => 'Amin::Command::Make',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'make',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$make{module}} = \%make;


		my %mv = (
				'module' => 'Amin::Command::Mv',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'mv',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$mv{module}} = \%mv;
	    
	        my %pconfigure = (
		                'module' => 'Amin::Command::Pconfigure',
		                'element' => 'command',
		                'namespace' => 'amin',
		                'name' => 'pconfigure',
		                'position' => 'middle',
		                'version' => '1.0',
		);
	        $parent{$pconfigure{module}} = \%pconfigure;


		my %patch = (
				'module' => 'Amin::Command::Patch',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'patch',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$patch{module}} = \%patch;


		my %remove = (
				'module' => 'Amin::Command::Remove',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'remove',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$remove{module}} = \%remove;


		my %rm = (
				'module' => 'Amin::Command::Rm',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'rm',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$rm{module}} = \%rm;


		my %rpm = (
				'module' => 'Amin::Command::Rpm',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'rpm',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$rpm{module}} = \%rpm;


		my %rsync = (
				'module' => 'Amin::Command::Rsync',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'rsync',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$rsync{module}} = \%rsync;


		my %search_replace = (
				'module' => 'Amin::Command::Search_replace',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'search_replace',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$search_replace{module}} = \%search_replace;


		my %system_command = (
				'module' => 'Amin::Command::System_command',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'system_command',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$system_command{module}} = \%system_command;


		my %touch = (
				'module' => 'Amin::Command::Touch',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'touch',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$touch{module}} = \%touch;


		my %umount = (
				'module' => 'Amin::Command::Umount',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'umount',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$umount{module}} = \%umount;


		my %unpack = (
				'module' => 'Amin::Command::Unpack',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'unpack',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$unpack{module}} = \%unpack;


		my %unzip = (
				'module' => 'Amin::Command::Unzip',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'unzip',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$unzip{module}} = \%unzip;


		my %zip = (
				'module' => 'Amin::Command::Zip',
				'element' => 'command',
				'namespace' => 'amin',
				'name' => 'zip',
				'position' => 'middle',
				'version' => '1.0',
		);
		$parent{$zip{module}} = \%zip;


		my %chroot = (
				'module' => 'Amin::Chroot',
				'element' => 'chroot',
				'namespace' => 'amin',
				'name' => 'chroot',
				'position' => 'begin',
				'version' => '1.0',
		);
		$parent{$chroot{module}} = \%chroot;


		my %download = (
				'module' => 'Amin::Download',
				'element' => 'download',
				'namespace' => 'amin',
				'name' => 'download',
				'position' => 'begin',
				'version' => '1.0',
		);
		$parent{$download{module}} = \%download;


		my %depend = (
				'module' => 'Amin::Depend',
				'element' => 'depend',
				'namespace' => 'amin',
				'name' => 'depend',
				'position' => 'begin',
				'version' => '1.0',
		);
		$parent{$depend{module}} = \%mount;


		my %arch = (
				'module' => 'Amin::Cond::Arch',
				'element' => 'cond',
				'namespace' => 'amin',
				'name' => 'arch',
				'position' => 'begin',
				'version' => '1.0',
		);
		$parent{$arch{module}} = \%mount;


		my %archu = (
				'module' => 'Amin::Cond::Archu',
				'element' => 'cond',
				'namespace' => 'amin',
				'name' => 'archu',
				'position' => 'begin',
				'version' => '1.0',
		);
		$parent{$archu{module}} = \%archu;


		my %hostname = (
				'module' => 'Amin::Cond::Hostname',
				'element' => 'cond',
				'namespace' => 'amin',
				'name' => 'hostname',
				'position' => 'begin',
				'version' => '1.0',
		);
		$parent{$hostname{module}} = \%hostname;


		my %os = (
				'module' => 'Amin::Cond::OS',
				'element' => 'cond',
				'namespace' => 'amin',
				'name' => 'os',
				'position' => 'begin',
				'version' => '1.0',
		);
		$parent{$os{module}} = \%os;

		$spec->{Filter} = \%parent;
	}
}
}

sub start_element {
	my ($self, $element) = @_;
	my %attrs = %{$element->{Attributes}};
	#need to process this element
	my $stuff = $spec->{Filter};
	foreach (keys %$stuff) {
		#check if there is a machine_filters element 
		#corresponding with this start_element
		
		if ($_ eq "") { next; }
		if ($stuff->{$_}->{element} eq $element->{LocalName}) {
		if (($stuff->{$_}->{name} eq $attrs{'{}name'}->{Value}) || ($element->{LocalName} eq $stuff->{$_}->{name})) {
		#logic to add new element to @machine_filters or not
		my $x = 0;
		if (@machine_filters) {
			#we already have some machine_filters
			foreach my $filter (@machine_filters) {
				if ($stuff->{$_}->{module} eq $filter->{module}) {
					#found a match
					$x = 1;
					next;
				}
			}
			if ($x != 1) {
				#no match so far
				#so add it to the @machine_filters list
				push @machine_filters, $stuff->{$_};
			}
		} else {
			#first filter
			if ($stuff->{$_} eq "") { next; }
			push @machine_filters, $stuff->{$_};
		}
		}
		}

	}
	#now do the bundles
	my $bstuff = $spec->{Bundle};
	foreach (keys %$bstuff) {
		#check if there is a machine_bundle element 
		#corresponding with this start_element
		if ($bstuff->{$_}->{element} eq $element->{LocalName}) {
		#logic to add new element to @machine_bundle or not
		my $x;
		if (@machine_bundle) {
			#we already have some machine_bundle(s)
			foreach (@machine_bundle) {
				if ($bstuff->{$_}->{element} eq $element->{Name}) {
					#found a match
					$x = 1;
					next;
				}
			}
			if ($x != 1) {
				#no match so far
				#so add it to the @machine_bundle list
				push @machine_bundle, $bstuff->{$_};
			}
		} else {
			#first bundle
			push @machine_bundle, $bstuff->{$_};
		}
		}

	}
}



sub end_document {
	my $self = shift;
	my (@beg, @mid, @end);
	my $log = $self->{Spec}->{Log};
	#sort the filters into their pipeline positions
	foreach (@machine_filters) {
		#autoload modules
		if ($_ eq "")  {
			next;
		}
		no strict 'refs';
		

		eval "require $_->{module}";
		if ($@) {
			if ($_->{'download'}) {
				my @cmd = ($0, '-u', $_->{'download'});
				run \@cmd;
				eval "require $_->{module}";
				if ($@) {
					$self->{Spec}->{amin_error} = "red";
					my $text = "Machine_Spec failed could not load $_->{module}. Reason $@";
					$log->error_message($text);
				}
			} else {
				#so amin isn't installed at all
				eval "require PAR";
				if ($@) {
					$self->{Spec}->{amin_error} = "red";
					my $text = "If PAR was installed, we might be able to fix the problem. can not load the PAR module";
					$log->error_message($text);
				} else {
					use lib 'http://projectamin.org/amin-latest.par';
					use lib 'http://projectamin.org/lwp.par';
			
					eval "require $_->{module}";
					if ($@) {
						$self->{Spec}->{amin_error} = "red";
						my $text = "Machine_Spec failed could not load $_->{module}. Reason $@";
						$log->error_message($text);
					}
				}
			}
		} else {
		
			if ($_->{position} eq "begin") {
				push @beg, $_;
			} elsif ($_->{position} eq "middle") {
				push @mid, $_;
			} elsif ($_->{position} eq "end") {
				push @end, $_;
			}
		}
	}
	
	foreach (@machine_bundle) {
		#machine bundle processing
		
	}
	
	#push our filters onto the new stack
	my @newfilters;
	push (@newfilters, @beg);
	push (@newfilters, @mid);
	push (@newfilters, @end);
	
	
	@machine_filters = ();
	@machine_bundle = ();
	
	my %spec;
	$spec{Filter_List} = \@newfilters;
	#if these are defined from the machine spec then set them up
	#Handler has to be special to ignore X:S:B 
	if ($self->{FHandler}) { $spec{Handler} = $self->{FHandler}; }
	if ($self->{Log}) { $spec{Log} = $self->{Log}; }
	if ($self->{Filter_Param}) { $spec{Filter_Param} = $self->{Filter_Param}; }
	
	if ($self->{Generator}) { $spec{Generator} = $self->{Generator}; }
	
	return \%spec;
}



=head1 NAME

Machine_Spec - The machine spec reader, default setup class.


=head1 Example

  use Amin::Machine::Machine_Spec;	
  use XML::Filter::XInclude;	
  use XML::SAX::PurePerl;
	
  my $h;
  if (defined $uri) {	
    $h = Amin::Machine::Machine_Spec->new('URI' => $uri);
  } else {
    $h = Amin::Machine::Machine_Spec->new();
  }
  #don't forget to include other specs this spec may include....
  my $ix = XML::Filter::XInclude->new(Handler => $h);
  my $p = XML::SAX::PurePerl->new(Handler => $ix);
  
  my $spec;
  
  if ($type eq "uri") {
    $spec = $p->parse_uri($profile);
  } else {
    $spec = $p->parse_string($profile);
  }
  return $spec;

  
=head1 DESCRIPTION

Machine_Spec - This module controls the machine spec document
reader. It also manipulates that output into the default machine
spec setup. A machine spec is central to any amin machine process.
All admin filters, machine handler, generators, filters and so 
on will check the machine spec to perform their operations.

The spec is defined in one of four ways

 1. by uri - http://example.com/machine_spec.xml

 2. the amin etc dir - /etc/amin/machine_spec.xml

 3. user's home amin dir - ~/.amin/machine_spec.xml

 4. internal amin %filters dataset and other various
   machine defaults noted in other module documents.
   
Example machine_spec.xml is shown in the XML section.

After the $spec is defined, several things are done 
with the resulting $spec. The machine_spec.xml may 
have more or less filters available than what the 
current profile.xml has inside. So we prune excess
machine_spec filters and happily ignore profile filter
requests this machine knows nothing about. This has
the pleasant side effect, that you can control filter
usage per Amin machine, by a xml file called machine_spec.xml
at this uri over here. Think about it for a bit. 

Don't want anyone to use 

 <amin:command name="mkdir"> 

commands?

remove

	<filter name="Amin::Command::Mkdir">
		<namespace>amin</namespace>
		<element>command</element>
		<name>mkdir</name>
		<position>middle</position>
		<download>http://projectamin.org/machines/command/mkdir.xml</download>
		<version>1.2</version>
		<option>Kewl Stuff</option>
	</filter>
   
or don't include 

	<bundle name="Amin::Command">
		<element>command</element>
		<namespace>amin</namespace>
		<name>command</name>
		<position>middle</position>
		<download>http://projectamin.org/machines/command.xml</download>
		<version>1.0</version>
	</bundle>

in your machine_spec.xml and your Amin machine(s)
will ignore all 

 <amin:command name="mkdir"> 

filter requests. Even if the Mkdir.pm filter is 
installed on said system....

After first round of $spec manipulation, we move 
onto phase two. Phase two involves loading each 
individual filter listed in the $spec. If the filter
is not available, this module looks at the filter's
"download" setting and runs this a new amin machine
that tries to process the filter's download profile.

A download profile is just a simple profile on how 
to download, and install this filter. It also cleans
up after itself. 

A bundle on the other hand is just a fancy package for
a complete set of filters. Ex. Amin Command filters
This allows you to have installation, and control on 
two levels. One more generic(<bundle>) and one more 
fine grained(<filter>).

If for some reason <download> is not available in 
the machine_spec, we use some PAR tricks and see if
Amin filter sets will provide the needed filter. 

If all this fails and the filter, can not be loaded
then this machine process can not complete and the
entire machine process fails, with appropriate 
outputs. 

As each filter passes this load test, the filter's 
position is looked at and the filter is added to 
the approriate position array. 

A position for a filter is just it's location in a
sax stream process. Typically most filters have a 
position of "middle". They really don't care what
comes before or after them. Nor do they care about
filters and if they ran successfully or not.

Complex commands like chroot or <amin:cond> do care
about what position they are in relation to the filters
that are their children. ex.

 <amin:chroot>
	<amin:command name="mkdir" />
 </amin:chroot>

So the chroot filter needs to be first in the sax chain
and the mkdir filter would come after in the chain. 

A filter may want to collect events from many filters
before it. It may want to do something with all events
from all the filters before handing it off to the default
machine handler. Say it deleted certain messages any filter
may have produced before final output. So you would want
this filter at the end of the sax processing chain.

Maybe you have a combo filter set. A profile splitter and
a profile merger. The profile splitter was first in the  
sax chain, all the profile's filters would be in the middle,
and then profile merger would be at the end. 

The positions recognized are 

 begin
 middle
 end

After all this filter manipulation is over, the final
thing we do, is add the other $spec defaults, and then 
return the new $spec. 

The other defaults are 

 $spec{Handler}
 $spec{Log}
 $spec{Generator}
 $spec{Filter_Param}

The defaults specified are defined in other modules. 
Filter_Param may be undefined. 


=head1 XML

=over 4

=item Full example

  <machine xmlns:amin="http://projectamin.org/ns/">
	<generator name="XML::SAX::PurePerl"/>
	<handler name="XML::SAX::Writer" output="yes" />
	<name>Amin::Machine::Dispatcher</name>
	<filter name="Amin::Command::Mkdir">
		<namespace>amin</namespace>
		<element>command</element>
		<name>mkdir</name>
		<position>middle</position>
		<download>http://projectamin.org/machines/command/mkdir.xml</download>
		<version>1.2</version>
		<option>Kewl Stuff</option>
	</filter>
	<filter name="Amin::Command::Mount">
		<element>command</element>
		<namespace>amin</namespace>
		<name>mount</name>
		<position>middle</position>
		<download>http://projectamin.org/machines/command/mount.xml</download>
		<version>1.0</version>
	</filter>
	<filter name="Amin::Command::Ls">
		<element>command</element>
		<namespace>amin</namespace>
		<name>ls</name>
		<position>middle</position>
		<download>http://projectamin.org/machines/command/ls.xml</download>
		<version>1.0</version>
	</filter>
	<filter name="Amin::Command::Move">
		<element>command</element>
		<namespace>amin</namespace>
		<name>move</name>
		<position>middle</position>
		<download>http://projectamin.org/machines/command/move.xml</download>
		<version>1.0</version>
	</filter>
	<bundle name="Amin::Command">
		<element>command</element>
		<namespace>amin</namespace>
		<name>command</name>
		<position>middle</position>
		<download>http://projectamin.org/machines/command.xml</download>
		<version>1.0</version>
	</bundle>
  </machine>	
	
=back  

=cut

1;
