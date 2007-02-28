use strict;
use Test::More tests =>1;

use Amin;
diag ("# I'm testing Amin version $Amin::VERSION\n");
use Amin::Machine::AdminList;
use Amin::Controller::CLIOutput;
use XML::SAX::PurePerl;
use Amin::Machine::Profile::Checker;
use Sort::Naturally;

system ("chmod 755 ./xml_files/convertor");
my $uri = `./xml_files/convertor`;
chomp($uri);
my $adminlist = $uri . "/command/adminlist-main.xml";
my @adminlists;
my @profiles;
my $h = Amin::Machine::AdminList->new();
my $p = XML::SAX::PurePerl->new(Handler => $h);
$adminlist = $p->parse_uri($adminlist);

foreach my $key (nsort keys %$adminlist) {
	if ($adminlist->{$key}->{type} eq "profile") {
		push @profiles, $adminlist->{$key}->{uri};
	}
	if ($adminlist->{$key}->{type} eq "adminlist") {
		push @adminlists, $adminlist->{$key}->{uri};
	}
}
#deal with adminlists within adminlists
#we have to repeat ourselves for a while....
foreach (@adminlists) {
	my $ih = Amin::Machine::AdminList->new();
	my $ip = XML::SAX::PurePerl->new(Handler => $ih);
	my $iadminlist = $ip->parse_uri($_);
		
	foreach my $key (nsort keys %$iadminlist) {
		if ($iadminlist->{$key}->{type} eq "profile") {
			push @profiles, $iadminlist->{$key}->{uri};
		}
		if ($iadminlist->{$key}->{type} eq "profile") {
			push @adminlists, $iadminlist->{$key}->{uri};
		}
	}
}
my $m = Amin->new ();
ok($m, 'loaded Amin\n');
diag("going to run $uri\n");
foreach my $profile (@profiles) {
	my $aout;
	my $lout;
	$lout = $m->parse_uri($profile);
	foreach (@$lout) {
		$aout = $aout . "$_";
	}
	my $h = Amin::Controller::CLIOutput->new();
	my $p = XML::SAX::PurePerl->new(Handler => $h);
	my $text = $p->parse_string($aout);
	diag ("$text\n");
	
	my $th = Amin::Machine::Profile::Checker->new();
	my $tp = XML::SAX::PurePerl->new(Handler => $th);
	my $cres = $tp->parse_string($aout);
	if ($cres == 1) {
		diag ("There was a failure");
		die;
	}
}
diag ("All is Good, have fun!!!!");