#!perl -w

# The rule, by equivalence class.
#
# Geo::Location::Predicate answers one question - could this string be a
# location at all? - and its answer is a cheap syntactic test: true for anything
# with a non-digit character in it, false for undef, the empty string, a
# reference and a string of digits only.  What it is for is the string a numeric
# column holds when the wrong column has been read, which must not be looked up
# as a place; that is why the classes below are the ones that matter.
#
# Two of them are easy to get wrong and are here for it.  A string of Unicode
# digits is refused as well as an ASCII one, because the pattern is a negated
# digit class and Perl answers it with Unicode rules for a string that carries
# the UTF-8 flag - and a caller reading a column of such digits is in the same
# position as one reading '0044'.  A scalar reference is refused: passing the
# string it points at is a caller's job (Params::Get does it for the six), and
# the rule is not what does it.

use strict;
use warnings;

use Scalar::Util qw(refaddr);
use Test::Most;

use Geo::Location::Predicate qw(_valid_location);

# Values that are not a location.  Held as pairs so a case cannot be confused
# with the assertion it feeds: '0' and 0 are different questions.
my @NOT_A_LOCATION = (
	['undef',                            undef],
	['the empty string',                 ''],
	['zero as a string',                 '0'],
	['zero as a number',                 0],
	['zero as a float',                  0.0],
	['a string of digits',               '0044'],
	['a long string of digits',          '1' x 200],
	['digits from another script',       "\x{0661}\x{0662}"],
	['fullwidth digits',                 "\x{FF11}\x{FF12}"],
	['a reference to an array',          [1, 2, 3]],
	['a reference to a hash',            { location => 'London' }],
	['a reference to a scalar',          \'London'],
	['a blessed reference',              bless({}, 'Geo::Location::Predicate::Test::Thing')],
);

# Values that could be.  A true answer means the string is not disqualified, not
# that anybody knows it: 'Ramsgate, Kent' is a location whether or not a backend
# has heard of it.
my @A_LOCATION = (
	['a city',                           'London'],
	['an address',                       'Ramsgate, Kent'],
	['a decimal',                        '3.14'],
	['a minus sign on its own',          '-'],
	['a space',                          ' '],
	['a negative number in a string',    '-0044'],
	['digits with a non-digit among them', '0 but true'],
	['a number in exponent form',        '1e3'],
	['a single letter',                  'a'],
);

for my $case (@NOT_A_LOCATION) {
	ok(!_valid_location($case->[1]), "$case->[0] is refused");
}

for my $case (@A_LOCATION) {
	ok(_valid_location($case->[1]), "$case->[0] can be looked up");
}

# The private name is the only one, and asking for it is how a caller gets it:
# a module that exported the rule by default would put it into a caller's
# namespace unasked.
is_deeply(\@Geo::Location::Predicate::EXPORT, [], 'the rule is not exported by default');
is_deeply(\@Geo::Location::Predicate::EXPORT_OK, ['_valid_location'],
	'it is available on request, under the name the callers use');

# The import is that sub, not a copy of it: a module that pasted the rule into
# its caller would answer the same and could still drift from this one.
is(refaddr(\&main::_valid_location), refaddr(\&Geo::Location::Predicate::_valid_location),
	'the imported name and the module\'s sub are the same code reference');

done_testing();
