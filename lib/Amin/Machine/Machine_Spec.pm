package Amin::Machine::Machine_Spec;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use vars qw(@ISA);
use Amin::Machine::Machine_Spec::Document;
use XML::Filter::XInclude;
use XML::SAX::PurePerl;
use IPC::Run qw( run );
use File::Basename qw(dirname);
use Amin::Elt;

@ISA = qw(Amin::Elt);


my $spec;
#the spec is defined in one of four ways
#1. any uri
#2. /etc/amin/machine_spec.xml
#3. ~/.amin/machine_spec.xml
#4. the default machine spec found inside
#   ~perl/site_perl/Amin/Machine/Machine_Spec/machine_spec.xml

my $home = $ENV{'HOME'};
my $configfile = "$home/.amin/machine_spec.xml";
my %machine_filters;
my %control;
my $begin = 0;
my $stage = 0;
my @parent;
my %attrs;

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
			#mess with stuff
			my $dir = $INC{'Amin.pm'};
		        $dir = dirname($dir);
			my $uri = "file:/" . $dir . "/Amin/Machine/Machine_Spec/machine_spec.xml";
			
			#define the spec
			#process ~perl/site_perl/Amin/Machine/Machine_Spec/machine_spec.xml
			my $h = Amin::Machine::Machine_Spec::Document->new();
			my $x = XML::Filter::XInclude->new(Handler => $h);
			my $p = XML::SAX::PurePerl->new(Handler => $x);
			$spec = $p->parse_uri($uri);	
			$control{ICONTROL} = "yes";
		}
	}
}

sub start_element {
	my ($self, $element) = @_;
	%attrs = %{$element->{Attributes}};
	$self->attrs(%attrs);
	
	#need to process this element
	my $stuff = $spec->{Filter};
	foreach (keys %$stuff) {
		if ($_ eq "") { next; }
		#check if there is a machine_filters element 
		#corresponding with this start_element
		if ($stuff->{$_}->{'element'} eq $element->{'LocalName'}) {
		if (($stuff->{$_}->{'name'} eq $attrs{'{}name'}->{'Value'}) 
		|| ($stuff->{$_}->{'name'} eq $element->{'LocalName'} )) {
		if ($stuff->{$_}->{namespace} eq $element->{Prefix}) {
			if ($stuff->{$_}->{position} eq "begin") {
				#begin and reset the parent
				$begin = 1;
				@parent = ();
				$stuff->{$_}->{parent_name} = $stuff->{$_}->{element};
			}
			if ($begin == 1) {
				my $same = 0;
				foreach my $lkids(@parent) {
					#do a same filter check
					if (($lkids eq $element->{'LocalName'}) || 
					   ($lkids eq $attrs{'{}name'}->{'Value'})) {
						$same = 1;
					}
				}
				if ($same != 1) {
					if ($stuff->{$_}->{'element'} ne $stuff->{$_}->{'parent_name'}) {
						push @parent, $stuff->{$_}->{'name'};
					}
				}
			}
			#logic to add new element to %machine_filters or not
			my $x = 0;
			if (%machine_filters) {
				#we already have some machine_filters
				foreach my $filter (keys %machine_filters) {
					if ($stuff->{$_}->{module} eq $machine_filters{$filter}->{module}) {
						#found a match
						$x = 1;
						next;
					}
				}
				if ($x != 1) {
					#no match so far
					#so add it to the %machine_filters list
					#add in the stage
					if ($begin != 1) {
						$stage++;
					} else {
						$stage = $stage . "-" . $stuff->{$_}->{name};
					}
					$stuff->{$_}->{stage} = $stage;
					$machine_filters{$stage} = $stuff->{$_};
				}
			} else {
				#first filter
				#add in the stage
				$stage++;
				$stuff->{$_}->{stage} = $stage;
				$machine_filters{$stage} = $stuff->{$_};
			}
		}
		}
		}
	}
}

sub end_element {
	my ($self, $element) = @_;
	my $attrs = $self->{"ATTRS"};
	my $stuff = $spec->{Filter};
	foreach (keys %$stuff) {
		if ($_ eq "") { next; }
		if ($stuff->{$_}->{namespace} eq $element->{Prefix}) {
		if ($stuff->{$_}->{parent_name} eq $element->{LocalName}) {
			if ($stuff->{$_}->{'name'} eq $attrs{'{}name'}->{'Value'}) {
				#reset parent name to be name="" not element
				$stuff->{$_}->{parent_name} = $attrs{'{}name'}->{'Value'}; 
			}
			$begin = 0;
			#this is right filter to add 
			#the @parent to
			$stuff->{$_}->{parent} = \@parent;
		}
		}
	}
}

sub end_document {
	my $self = shift;
	foreach (keys %machine_filters) {
		#autoload module check
		no strict 'refs';
		eval "require $machine_filters{$_}->{module}";
		#version check
		my $lv;
		my $lh = $machine_filters{$_}->{module};
		unless ($@) {
			if ($lh->can("version")) {
				$lv = $lh->version;
			} else {
				#tsk tsk no version sub
				$lv = "noneamin";
			}
		}	
		my $version;
		if (!$lv) {
		if ($lv ne $machine_filters{$_}->{version}) {
			$version = "bad";
		}
		}
		if ($lv eq "noneamin") {
			die "Your filter $machine_filters{$_}->{module} does not have a version subroutine. Please add one...";
		}
		if (($@) || ($version eq "bad")) {
			if ($machine_filters{$_}->{'download'}) {
				my @cmd = ($0, '-u', $machine_filters{$_}->{'download'});
				run \@cmd;
				eval "require $machine_filters{$_}->{module}";
				if ($@) {
					#$self->{Spec}->{amin_error} = "red";
					die "Machine_Spec failed could not load $_->{module}. Reason $@";
				}
			} #else {
			#	#so amin isn't installed at all
			#	eval "require PAR";
			#	if ($@) {
			#		die "If PAR was installed, we might be able to fix the problem. can not load the PAR module";
			#	} else {
			#		use lib 'http://projectamin.org/amin-latest.par';
			#		use lib 'http://projectamin.org/lwp.par';
			#
			#		eval "require $machine_filters{$_}->{module}";
			#		if ($@) {
			#			#$self->{Spec}->{amin_error} = "red";
			#			die "Machine_Spec failed could not load $_->{module}. Reason $@";
			#		}
			#	}
			#}
		}
		
	}
	
	
	$spec->{Filter_List} = \%machine_filters;
	return $spec;
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

 4. the default machine spec found inside
    ~perl/site_perl/Amin/Machine/Machine_Spec/machine_spec.xml
   
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
"download" setting and runs this as a new amin machine
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