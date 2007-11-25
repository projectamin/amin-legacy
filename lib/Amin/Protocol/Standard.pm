package Amin::Protocol::Standard;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use Amin;
use LWP::UserAgent;
use Amin::Protocol::Datastore;
use Amin::Machine::Filter::XInclude;
use XML::SAX::PurePerl;
use Digest::MD5;
use Amin::Uri;
use IO::Socket;
use POSIX qw(:sys_wait_h);

sub new {
	my $class = shift;
	my %args = @_;
	my $self;
	$self = bless \%args, $class;
	return $self;
}

sub parse_uri {
	my $self = shift;
	my $networkmap = shift;
	my $uri = shift;
	my $socket = IO::Socket::INET->new(PeerAddr => $networkmap->{'ip'},
                                PeerPort => $networkmap->{'port'},
                                Proto    => "tcp",
                                Type     => SOCK_STREAM)
	or die "Couldn't connect to $networkmap->{'ip'}:$networkmap->{'port'} : $@\n";
	print $socket "$uri\n";
	my $output = <$socket>;
	close($socket);	
	return $output;
}

sub Run {
	my $self = shift;
	my $info = "$self->{Ip}:$self->{Port}";
	my $server = IO::Socket::INET->new(
					LocalAddr => $info,
					Type => SOCK_STREAM,
					Reuse => 1,
					Listen => 10,
					 )
	or die "Could not bind as a server on ip $self->{Ip} port $self->{Port} : $@\n";
	print "Server $self->{Ip} on port $self->{Port} has started\n";

	while (my $client = $server->accept()) {
		my $uri = $client->getline();
		chomp ($uri);
		#this is a simple amin controller.
		#it takes the $uri supplied, grabs the
		#resulting profile, checksums the uri/profile
		#compares that checksum to it's internal datastore
		#of checksums, and if the checksums match then the
		#daemon runs the profile/adminlist as whatever
		#user this daemon runs as.
		my $aout;
		my $m = Amin->new ();
		#grab profile
		my $ua = LWP::UserAgent->new;
		my $req = HTTP::Request->new(GET => $uri);
		my $res = $ua->request($req);
		if ($res->is_success) {
			$aout = $res->content;
		} else {
			$aout .= " Unable to download $uri.";
		}
		my $uric = Amin::Uri->new();
		if ($uric->is_uri($uri)) {
			#checksum the profile
			my $md5 = Digest::MD5->new;
			$md5->add($aout);
			my $digest = $md5->hexdigest;
			#compare to datastore of checksums
			my $ds = $self->{Data_Store};
			my $h = Amin::Protocol::Datastore->new();
			my $x = Amin::Machine::Filter::XInclude->new(Handler => $h);
			my $p = XML::SAX::PurePerl->new(Handler => $x);
			$ds = $p->parse_uri($ds);	
			#if checksum matches or not.
			foreach (keys %$ds) {
				if ($digest eq $ds->{$_}->{checksum}) {
					$aout = $m->parse_uri($uri);
				} else {
					$aout = "sorry this profile is not allowed";
				}
			}
		}
		$client->print(@$aout);
	}
	$SIG{CHLD} = \&REAPER;
	$server->shutdown(2);
}

# set up the socket SERVER, bind and listen ...

sub REAPER {
    1 until (-1 == waitpid(-1, WNOHANG));
    $SIG{CHLD} = \&REAPER;
}

1;