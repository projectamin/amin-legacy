# ExtUtils::AutoInstall Bootstrap Code, version 7.
BEGIN{
	my $p='ExtUtils::AutoInstall';
	my $v=0.52;
	$p->VERSION||0>=$v or + eval "use $p $v; 1" or +
	do{
		my$e=$ENV{PERL_EXTUTILS_AUTOINSTALL};
		(!defined($e)||$e!~m/--(?:default|skip|testonly)/
		and-t STDIN or
		eval"use ExtUtils::MakeMaker;
		WriteMakefile(PREREQ_PM=>{'$p',$v});1"
		and exit
		)
		
		and 
		print"==> $p $v required. Install it from CPAN? [Y/n] "
		and
		<STDIN>!~/^n/i 
		and 
		print"*** Installing $p\n"
		and
		do{
			if (eval '$>' and lc(`sudo -V`) =~ /version/) {
				system('sudo', $^X, "-MCPAN", "-e", "CPAN::install $p")
			}
			eval{ require CPAN; CPAN::install$p };
			eval "use $p $v;1" ||die "*** Please manually install $p $v from cpan.org first...\n"
		}	
	}
}

use ExtUtils::AutoInstall (
               -version        => '0.52',      
               -config         => {
                   force       => 1,           
               },
	       -core           => [
				'Cwd' => '2.04',
				'IPC::Run' => '0.74',
				'URI' => '1.22',
				'XML::SAX::Base' => '1.02',
				'XML::NamespaceSupport' => '0.03',
				'XML::SAX' => '0.12',
				'Text::Iconv' => '1.2',
				'XML::Filter::BufferText' => '0.01',
				'XML::Generator::PerlData' => '0.87',
				'XML::SAX::ParserFactory' => '1.01',
				'XML::SAX::Writer' => '0.39',
				'XML::Filter::XInclude' => '1.0',
				'XML::SAX::Machines' => '0.34',
				'HTML::Tagset' => '3.03',
				'HTML::HeadParser' => '2.17',
				-skiptests  => [ <t/robot/ua*.t>,
						 <t/local/http*.t>
			
				],
				'LWP'	=> '5.65',
				'Sort::Naturally' => '1.01',
				'XML::Mini::Document' => '1.28',
				-skiptests  => [ <t/fork*.t>,
					<t/config.t>,
					<t/loop*.t>,
					<t/single.t>,
					<t/unix.t>
				],
				'Net::Daemon'    => '0.37',
				'Crypt::Blowfish_PP' => '1.12'
		],
	
	
	
	
	);
WriteMakefile(
	NAME            => 'Amin',
	VERSION_FROM    => 'lib/Amin.pm',
	AUTHOR          => 'Project Amin http://projectamin.org',
	ABSTRACT        => 'XML Administration',
	DISTNAME        => 'Amin',
);


print "\nCopying controllers/amin to /usr/bin\n";
system("cp controllers/amin /usr/bin/");
#print "\nCopying frontends/amincli to /usr/bin\n";
#system("cp frontends/amincli /usr/bin");
