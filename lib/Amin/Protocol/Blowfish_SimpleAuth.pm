package Amin::Protocol::Blowfish_SimpleAuth;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use POSIX;
use IPC::Run qw( run );
use XML::SAX::ParserFactory;
use Amin::Protocol::Login;
use XML::SAX::Writer;
use Crypt::Blowfish_PP;
#use IPC::Shareable (':lock');
#use Net::SMTP;
use IO::Socket;
use IO::Select;

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
	my $m = shift;
	my $socket = IO::Socket::INET->new(PeerAddr => $networkmap->{'ip'},
				PeerPort => $networkmap->{'port'},
				Proto    => "tcp",
				Type     => SOCK_STREAM)
	or die "Couldn't connect to $networkmap->{'ip'}:$networkmap->{'port'} : $@\n";
	if ($m->{Filter_Param}) {
		#decrypt
		my $npassword = pack("H16", $networkmap->{'password'});
		my $nkey = pack("H16", $networkmap->{'key'});
		my $blowfish = Crypt::Blowfish_PP->new($m->{Filter_Param});
		my $plainpass = $blowfish->decrypt($npassword);
		my $plainkey = $blowfish->decrypt($nkey);
		my $encryptor = Crypt::Blowfish_PP->new($plainkey);
		my $chipertext = $encryptor->encrypt($plainpass);
		$networkmap->{'password'} = unpack("H16", $chipertext);
	} else {
		die "need the blowfish master key for your networkmap.";
	}
	my $text = "<amin:login xmlns:amin=\"http://projectamin.org/ns/\"><amin:uri>$uri</amin:uri><amin:username>$networkmap->{'username'}</amin:username><amin:password>$networkmap->{'password'}</amin:password></amin:login>\n";
	$socket->print($text);
	my $output = <$socket>;
	$socket->close;
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
	                        my $line = <$rh>;
				if ($line) {
					my $handler = Amin::Protocol::Login->new();
					my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
					my $login = $p->parse_string($line);
					#decrypt password
					my $key = $self->{'Key'};
					my $blowfish = Crypt::Blowfish_PP->new($key);
					my $crypttext =  pack("H16", $login->{'passwd'});
					my $passwd = $blowfish->decrypt($crypttext);
					$login->{'passwd'} = $passwd;
					my ($sys_name, $sys_passwd, $sys_uid) = getpwnam($login->{'username'});
					#authentication of the username and password
					my $auth = "no";
					my $auth_type = $self->{'auth_type'};
					if ($auth_type eq "PAM") {
						#require Authen::SimplePam;
						#$auth = new Authen::PAM;
						#service is like $auth_type
						#my $code = $auth->auth_user( $login->{'username'}, $login{'password'}, $self->{'service'});
						#if ($code != 1) {
						#	$auth = "no";
						#}
					} elsif ($auth_type eq "other") {
						#other schemes here
					} else {
						my $result = crypt($passwd, $sys_passwd);
						if ($sys_passwd) {
							if ($result eq $sys_passwd) {
								$auth = "yes";
							}
						}
					}
	
					if ($auth eq "yes") {
						#set the child's uid to the authenticated uid
						setuid($sys_uid);
		        			$> = $<;
	
						my ($in, $out, $err);
						if ($login->{'uri'}) {
							my @cmd = ('amin', '-u', $login->{'uri'});
							run \@cmd, \( $in, $out, $err );
						} else {
							my @cmd = ('amin', '-p', $login->{'profile'});
							run \@cmd, \( $in, $out, $err );
						}
						
						#server out
						my @things = split(/\n/,$out);
						my $sout;
						foreach (@things) {
							$sout = $sout . "$_";
						}
						$rh->send($sout);
					} else {
						#my %bad;
						#tie %bad, 'IPC::Shareable', 'bad';

						#this needs to have some sort of checker for people
						#who try to guess a password toooo many times and
						#my $errmsg = "The attempt for $login->{'username'} failed";
						#$self->Log('err', $errmsg);
						#$self->Error("The attempt for $login->{'username'} failed");

						#$bad->shlock;
						#if ($bad{$ip}) {
						#	$number = $bad{$ip};
						#	$number++;
						#	$bad{$ip} = $number;
						#} else {
						#	$bad{$ip} = "1";
						#}
						#$bad->shunlock;
						#if ($bad{$ip} eq "3") {
						 #email to admin
						#	$bad{$ip} = "0";
						#	$email = $self->{'admin_email'};
						#	$host = $self->{'email_host'};
						#	$smtp = Net::SMTP->new($host);
						#	$smtp->mail($email);
						#	$smtp->to($email);
	
						#	$smtp->data();
						#	$smtp->datasend("To: $email\n");

						#	$smtp->datasend("\n");
						#	$smtp->datasend("$login->{'username'} has failed three times trying to login\n");
						#	$smtp->dataend();
		
						#	$smtp->quit;
						#}
						my $text = "Sorry you are not authorized! \n";
						$rh->send($text);
					}
					# remove the socket from the $read_set and close it
					$read_set->remove($rh);
					close($rh);
				}
			}
		}
	}
}

1;
