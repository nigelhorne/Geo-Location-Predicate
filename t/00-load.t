#!perl -T

use strict;
use warnings;

use Test::Most tests => 2;

BEGIN {
	use_ok('Geo::Coder::Free::Validate') or BAIL_OUT('Geo::Coder::Free::Validate failed to load');
}

require_ok('Geo::Coder::Free::Validate');

diag("Testing Geo::Coder::Free::Validate $Geo::Coder::Free::Validate::VERSION, Perl $], $^X");
