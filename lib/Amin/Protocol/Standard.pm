package Amin::Protocol::Standard;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use Net::Daemon;
use Amin;
use LWP::UserAgent;
#use Amin::Machine::Protocol::Datastore;
use XML::Filter::XInclude;
use XML::SAX::PurePerl;
use Digest::MD5;
use IO::Socket;

use vars qw(@ISA);
@ISA = qw(Net::Daemon);


sub parse_uri {
	my $self = shift;
	my $networkmap = shift;
	my $uri = shift;
	my $line;
	#setup the socket infos
	my $ip = $networkmap->{'ip'};
	my $port = $networkmap->{'port'};
	my $socket = IO::Socket::INET->new(PeerAddr => $ip,
		PeerPort => $port,
		Proto    => "tcp",
		Type     => SOCK_STREAM)
		or die "Couldn't connect to 
		$networkmap->{'ip'}:$networkmap->{'port'} : $@\n";
	#send the uri to the other side
	$socket->send($uri);
	#get back the response and return it
	my $newline;
	while (1) {
		if (!defined($line = $socket->getline())) {
			last;
		}
		$newline = $newline . $line;
	}
	close($socket);
	return $newline;
}

sub Run ($) {
	my($self) = @_;
	my($line, $sock);
	$sock = $self->{'socket'};
	while (1) {
		#grab the $line from the $socket
		if (!defined($line = $sock->getline())) {
			if ($sock->error()) {
				$self->Error("Client connection error %s", $sock->error());
			}
			$sock->close();
			return;
		}
		#fork a child
		my $pid = fork;
		if ($pid eq 0) {
			wait;
			#should this be return; instead?
			#is this the defunct process problem?
			#
			exit;
			return;
		} else {
			#this is a simple amin controller.
			#it takes the $uri supplied, grabs the
			#resulting profile, checksums the uri/profile
			#compares that checksum to it's internal datastore
			#of checksums, and if matches parses as whatever
			#user this daemon runs as.
			my $m = Amin->new ();
			my $lout;
			#grab profile
			my $ua = LWP::UserAgent->new;
			my $aout;
			#change?
			my $uri = $line;
			my $req = HTTP::Request->new(GET => $uri);
			my $res = $ua->request($req);
			if ($res->is_success) {
			
			} else {
				$aout .= " Unable to download $uri.";
			
			}
			#checksum the profile
			my $md5 = Digest::MD5->new;
			$md5->add($aout);
			my $digest = $md5->hexdigest;
			#compare to datastore of checksums
			my $ds = $self->{Data_Store};
			my $h = Amin::Machine::Protocol::Datastore->new();
			my $x = XML::Filter::XInclude->new(Handler => $h);
			my $p = XML::SAX::PurePerl->new(Handler => $x);
			$ds = $p->parse_uri($ds);	
			#if checksum matches or not.
			foreach (keys %$ds) {
				if ($digest eq $ds->{$_}->{digest}) {
					$aout = $m->parse_uri($uri);
				} else {
					$aout = "sorry this profile is not allowed";
				}
			}
			$sock->send($aout);
			$sock->close();
			return;
		}
	}
}

1;