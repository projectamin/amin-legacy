package Amin::Protocol::Blowfish_SimpleAuth;

#LICENSE:

#Please see the LICENSE file included with this distribution 
#or see the following website http://projectamin.org.

use strict;
use Net::Daemon;
use POSIX;
use IPC::Run qw( run );
use XML::SAX::ParserFactory;
#use Amin::CLI::Login;
use XML::SAX::Writer;
use Crypt::Blowfish_PP;
use IPC::Shareable (':lock');
use Net::SMTP;
use IO::Socket;

use vars qw(@ISA);
@ISA = qw(Net::Daemon);


#sub new {
#	my $class = shift;
#	my $self = {};
#	bless($self, $class);	
#	return $self;
#}

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
	
	if ($self->{Spec}->{Param}) {
		#decrypt
		my $decrypter = Crypt::Blowfish_PP->new($self->{Spec}->{Param});
		my $plainpass = $blowfish->decrypt($networkmap->{'password'});
		my $plainkey = $blowfish->decrypt($networkmap->{'key'});
		my $encryptor = Crypt::Blowfish_PP->new($plainkey);
		$networkmap->{'password'} = $encryptor->encrypt($plainpass);
		
	} else {
		die "need the blowfish master key for your networkmap.";
	}		
my $text = (<<END);

<amin:login xmlns:amin="http://projectamin.org/ns/">
	<amin:uri>$uri</amin:uri>
        <amin:username>$networkmap->{'user'}</amin:username>
        <amin:password>$networkmap->{'password'}</amin:password>
</amin:login>
eof

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

		my (@line, $line);

		#my $newline;
		#while (1) {
		#	if (!defined($line = $sock->getline())) {
		#		last;
		#	}
		#	$_ =~ s/(^\s+|\s+$)//gm;
		#	$line = $line . $_;
			#$newline = $newline . $line; 
		#}

		while (<$sock>) {
			if (/eof/) {
			#if ($sock->eof) {
				last;
			}
			$_ =~ s/(^\s+|\s+$)//gm;
			$line = $line . $_;
		}


		#password is not loaded in Login.pm There are certain
		#characters used in BlowFish encryption that bork out
		#XML parsers. So we grab the Blowfish password manually
		#and load it in $login
		my ($beg, $rest) = split (/<amin:password>/, $line);
		my ($passwd, $end) = split (/<\/amin:password>/, $rest);

		#now let's delete password out of $line so the SAX parsers
		#don't bork out....

		$line = $beg . $end;

		my $newprofile;
		my $writer = XML::SAX::Writer->new(Output => \$newprofile);
		my $handler = Amin::CLI::Login->new(Handler => $writer);
		my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
		my $login = $p->parse_string($line);

		#finally add passwd to %login
		$login->{'passwd'} = $passwd;

		if ($newprofile) {
			$login->{'profile'} = $newprofile;
		}

		my ($sys_name, $sys_passwd, $sys_uid) = getpwnam($login->{'username'});

		#authentication of the username and password
		my $key = $self->{'key'};
		my $blowfish = Crypt::Blowfish_PP->new($key);
		my $passwd = $blowfish->decrypt($login->{'passwd'});

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
				return;
			}
		}
	}
}

1;
