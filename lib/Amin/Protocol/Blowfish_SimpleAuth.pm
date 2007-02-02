package Amin::Protocol::Blowfish_SimpleAuth;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use Net::Daemon;
use POSIX;
use IPC::Run qw( run );
use XML::SAX::ParserFactory;
use Amin::CLI::Login;
use XML::SAX::Writer;
use Crypt::Blowfish_PP;
#use IPC::Shareable (':lock');
#use Net::SMTP;
use IO::Socket;

use vars qw(@ISA);
@ISA = qw(Net::Daemon);

sub parse_uri {
	my $self = shift;
	my $networkmap = shift;
	my $uri = shift;
	my $line;
	my $ip = $networkmap->{'ip'};
	my $port = $networkmap->{'port'};
	my $socket = IO::Socket::INET->new(PeerAddr => $ip,
		PeerPort => $port,
		Proto    => "tcp",
		Type     => SOCK_STREAM)
		or die "Couldn't connect to 
		$networkmap->{'ip'}:$networkmap->{'port'} : $@\n";
	if ($self->{Spec}->{Filter_Param}) {
		#decrypt
		my $decrypter = Crypt::Blowfish_PP->new($self->{Spec}->{Filter_Param});
		my $plainpass = $blowfish->decrypt($networkmap->{'password'});
		my $plainkey = $blowfish->decrypt($networkmap->{'key'});
		my $encryptor = Crypt::Blowfish_PP->new($plainkey);
		my $chipertext = $encryptor->encrypt($plainpass);
		$networkmap->{'password'} = pack("H*", $chipertext);
	} else {
		die "need the blowfish master key for your networkmap.";
	}
	my $text = (<<END);
<amin:login xmlns:amin="http://projectamin.org/ns/">
	<amin:uri>$uri</amin:uri>
        <amin:username>$networkmap->{'user'}</amin:username>
        <amin:password>$networkmap->{'password'}</amin:password>
</amin:login>

END
	$socket->send($text);
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
	
	
		my $handler = Amin::CLI::Login->new(Handler => $writer);
		my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
		my $login = $p->parse_string($line);

		#decrypt password
		
		my $key = $self->{'key'};
		my $blowfish = Crypt::Blowfish_PP->new($key);
		my $crypttext =  unpack("H*", $login->{'passwd'});
		my $passwd = $blowfish->decrypt($crypttext);
		$login->{'passwd'} = $passwd;


		my ($sys_name, $sys_passwd, $sys_uid) = getpwnam($login->{'username'});

		#authentication of the username and password

		my $auth;
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
			if (crypt($passwd, $sys_passwd) ne $sys_passwd) {
				$auth = "no";
			}
		}

		if ($auth eq "no") {
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
			$sock->send($text);
			$sock->close();
			return;
		} else {
			my $pid = fork;
			if ($pid eq 0) {
				wait;
				#should this be return; instead?
				#is this the defunct process problem?
				#exit;
				return;
			} else {
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
				$sock->send($out);
				$sock->close();
				return;
			}
		}
	}
}

1;
