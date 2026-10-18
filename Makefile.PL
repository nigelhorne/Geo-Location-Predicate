use strict;
use warnings;

use ExtUtils::MakeMaker;

my $dist = {
	COMPRESS => 'gzip -9f',	# Compress tarball using gzip
	SUFFIX => 'gz',	# File suffix for tarball
};

if($^O eq 'darwin') {
	$dist->{'TAR'} = 'gtar';
}

WriteMakefile(
	NAME => 'Geo::Coder::Free::Validate',
	VERSION_FROM => 'lib/Geo/Coder/Free/Validate.pm',
	ABSTRACT_FROM => 'lib/Geo/Coder/Free/Validate.pm',
	AUTHOR => 'Nigel Horne <njh@nigelhorne.com>',
	LICENSE => 'GPL',
	MIN_PERL_VERSION => '5.008',
	# The rule needs nothing but perl: it is one sub with one pattern, which is
	# why it is a distribution of its own rather than a reason to install the
	# facade and its databases.
	PREREQ_PM => {},
	TEST_REQUIRES => {
		'Test::DescribeMe' => 0,
		'Test::Most' => 0,
		'Test::Needs' => 0,
	},
	dist => $dist,
	clean => { FILES => 'Geo-Coder-Free-Validate-*' },
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			homepage => 'https://metacpan.org/pod/Geo::Coder::Free::Validate',
			repository => {
				repository => 'https://github.com/nigelhorne/Geo-Coder-Free-Validate',
				type => 'git',
				url => 'git://github.com/nigelhorne/Geo-Coder-Free-Validate.git',
				web => 'https://github.com/nigelhorne/Geo-Coder-Free-Validate',
			}, bugtracker => {
				mailto => 'bug-Geo-Coder-Free-Validate@rt.cpan.org',
				web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Free-Validate',
				url => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Free-Validate',
			}
		},
	},
);
