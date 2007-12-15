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
use IO::Select;
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
	$socket->print("$uri\n");
	my $output = <$socket>;
	$socket->close();
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

	my $read_set = IO::Select->new(); # create handle set for reading
	$read_set->add($server);           # add the main socket to the set

	while (1) { # forever

	        # get a set of readable handles (blocks until at least one handle is ready)
	        my ($rh_set) = IO::Select->select($read_set, undef, undef, 0);
	        # take all readable handles in turn
	        foreach my $rh (@$rh_set) {
	                # if it is the main socket then we have an incoming connection and
	                # we should accept() it and then add the new socket to the $read_set
	                if ($rh == $server) {
	                        my $ns = $rh->accept();
	                        $read_set->add($ns);
	                } else {
	                        # otherwise it is an ordinary socket and we should read and process the request
	                        my $buf = <$rh>;
	                        if($buf) { # we get normal input
					my $uri = $buf;
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
								#$aout = $m->parse_string($aout);
								$aout = $m->parse_uri($uri);
							} else {
								$aout = "sorry this profile is not allowed";
							}
						}
					}
					#server out
					my $sout;
					foreach (@$aout) {
						$sout = $sout . "$_";
					}
					$rh->send($sout);
				} 
				# remove the socket from the $read_set and close it
				$read_set->remove($rh);
				close($rh);
			}
		}
	}
}

1;





