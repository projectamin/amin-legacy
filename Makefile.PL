use inc::Module::Install;
name		('Amin');
abstract	('Amin XML Administration');
author		('Project Amin http://projectamin.org');
include		('ExtUtils::AutoInstall');
license		('perl');
version_from	('lib/Amin.pm');

requires        ('Cwd');
requires        ('IPC::Run');
requires        ('URI');
requires        ('XML::SAX::Base');
requires        ('XML::NamespaceSupport');
requires        ('XML::SAX');
requires        ('XML::Generator::PerlData');
requires        ('XML::SAX::ParserFactory');
requires        ('XML::Filter::XInclude');
requires        ('HTML::Tagset');
requires        ('HTML::HeadParser');
requires        ('LWP');
requires        ('Sort::Naturally');
requires        ('XML::SAX::PurePerl');
recommends	('Sys::Hostname');
recommends	('Net::Daemon');
recommends	('Crypt::Blowfish_PP');
recommends	('IPC::Shareable');
recommends	('Net::SMTP');
recommends	('IO::Socket');

no_index        (directory => 'xml_files');
auto_install	();
&WriteAll;

print "\nCopying controllers/amin to /usr/bin\n";
system("cp controllers/amin /usr/bin/");
