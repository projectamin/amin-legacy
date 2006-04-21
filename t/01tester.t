use strict;
use Test::More tests =>1;

use Amin;
diag ("# I'm testing Amin version $Amin::VERSION\n");
use Amin::Controller::CLIOutput;
use XML::SAX::PurePerl;

my $uri = `./xml_files/convertor`;
chomp($uri);
$uri = $uri . "/command/adminlist-main.xml";

my $amin = Amin->new();
ok($amin, 'loaded Amin\n');
diag("going to run $uri\n");

$amin->parse_adminlist($uri);
my $results = $amin->results;
foreach (@$results) {
       my $h = Amin::Controller::CLIOutput->new();
       my $p = XML::SAX::PurePerl->new(Handler => $h);
       my $text = $p->parse_string($_);
       diag ("$text\n");

	my $th = Amin::Machine::Profile::Checker->new();
	my $tp = XML::SAX::PurePerl->new(Handler => $th);
	my $cres = $tp->parse_string($_);

	if ($cres == 1) {
		diag ("There was a failure");
		die;
	}
}
diag ("All is Good, have fun!!!!");




