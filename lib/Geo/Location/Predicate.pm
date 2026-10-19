package Geo::Location::Predicate;

# The one definition of what counts as a location.
#
# It was a module of Geo::Coder::Free until 0.48, and lives in a distribution of
# its own now for two reasons.  The first is weight: the six geocoders that ask
# the rule - Geo::Coder::CA, DataScienceToolkit, GeoApify, List, Postcodes and
# XYZ - are releases of their own, and while the rule lived inside
# Geo::Coder::Free the only way for them to name it in their metadata was to
# require the facade too, with its backends, its databases and its cache; so each
# looked for the module when it loaded instead of declaring it.  The second is
# that the rule is useful on its own and does not need any of that: it is a cheap
# syntactic test with no dependencies at all, so it can be the dependency the six
# declare - a recommendation in their META, which an installer fetches by
# default.
#
# The name says the question, not the namespace it was written in.  It is a
# predicate - could this string be a location? - and not a validator, which
# would promise that the string is a correct address or a real place; the answer
# is a policy about whether a lookup is worth making, so a numeric geocoder may
# want it to say true where this says false.  Geo::Location::* is where a
# location is looked at rather than where one is looked up (that is Geo::Coder::*,
# ::CA and ::OSM being geocoders for a service each), and it sits beside
# Geo::Location::Point for a caller who already has coordinates in hand.  Every
# caller says Geo::Location::Predicate::_valid_location(), including the facade
# and both of its backends; the sub keeps its private name so that it does not
# compete with the public spelling the facade already offers.
#
# The class - not the file - is the unit: L<Geo::Coder::Free> calls this rule and
# depends on this distribution, and the six call it when it is installed and fall
# back to refusing a reference when it is not.
#
# Zero dependencies is the point of the distribution, so nothing beyond core
# perl is loaded here - not Params::Validate::Strict, not Readonly, not
# Sub::Private.  Each of those would become a prerequisite of eight
# distributions to guard one line, and Sub::Private would stop the eight
# callers from calling the rule at all.

use strict;
use warnings;

# Exporter's import() is inherited by name rather than through @ISA; that form
# needs Exporter 5.57, which is first in perl 5.8.3 (hence MIN_PERL_VERSION).
use Exporter qw(import);
our @EXPORT_OK = qw(_valid_location);

=encoding utf-8

=head1 NAME

Geo::Location::Predicate - The rule that decides whether a string could be a location

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Geo::Location::Predicate qw(_valid_location);

    if(_valid_location($row->{'place'})) {
        # worth a lookup
    }

=head1 DESCRIPTION

One question: could this string be a location at all?

It is asked in three places by L<Geo::Coder::Free> - of a C<location> and of a
C<scantext> before it queries a backend, and by
L<Geo::Coder::Free::MaxMind> and L<Geo::Coder::Free::OpenAddresses> of what a
caller hands them directly - and by the six sibling geocoders that look a place
up in their own service.  The rule lives here rather than being written out at
each of those places, so they cannot drift apart on which strings are worth
looking up: a string the facade refuses must not be accepted by a backend, and
the other way round.

It is a cheap syntactic test and nothing more.  A C<true> answer means the string
is not disqualified, B<not> that a backend knows it: C<'Ramsgate, Kent'> is a
location and may still find nothing.  What is disqualified is a string of digits
only, which is what a numeric column holds when the wrong column has been read,
plus C<undef>, the empty string and a reference.  Anything with at least one
non-digit character in it counts, C<'3.14'>, C<'-'> and C<' '> included: the
rule refuses only what is certainly a number, so a rejected C<'0044'> is a
column mistake rather than a place nobody has heard of.

"Digit" means a Unicode decimal digit (C<\p{Nd}>), not only C<0> to C<9>, so
C<"\x{0661}\x{0662}"> (Arabic-Indic one-two) is refused as C<'12'> is.  The
answer does not depend on the locale, on whether the string carries the UTF-8
flag, or on a C<use locale> in the caller's scope.

The name is a predicate, not a promise: C<true> does not mean the place exists,
and a geocoder for a service with numeric identifiers may want a different
policy, which is why this one is asked only when it is installed rather than
being a hard prerequisite of the six.

A caller should not need this module: L<Geo::Coder::Free> has the same rule in
public as C<< $geo->valid_location($row->{'place'}) >>, which is what a batch
caller should pre-filter with.  The sub is exported under its private name
because the facade, its backends and the six are the only intended callers, and
because its public spelling already exists and has a name a caller can rely on.

Installing this distribution is optional for the six siblings and required by
L<Geo::Coder::Free>.  Each sibling declares it under C<recommends> in its META
rather than as a prerequisite, and looks for it when it first needs it rather
than when it loads, so importing a sibling reads no file it may not have.  A
sibling without it still refuses a reference, which is the case none of them
could test for on its own, but it cannot answer the question about a numeric
column read by mistake - so the rule is asked when it is there, and what each
sibling does without it is documented by that sibling.

=head1 SUBROUTINES/METHODS

=head2 _valid_location

Purpose: say whether a value could be a location, so that a caller can skip a
lookup that cannot succeed.

Args: one value, of any kind.  Anything after the first argument is ignored.

Returns: C<1> if the value is a non-reference scalar holding at least one
non-digit character; C<0> otherwise - for C<undef>, C<''>, a reference
(blessed or not, overloaded or not) and a string of digits only.  Always
exactly one value, so it is safe in list context.

Side effects: none.  It does not croak, warn, change its argument, C<$_>,
C<$!>, C<$@> or the caller's C<$1>.

Usage: call it as a function, not a method; there is no object.

=head3 EXAMPLE

    use Geo::Location::Predicate qw(_valid_location);

    # Skip rows whose 'place' column holds a postcode-less number by mistake
    my @worth_looking_up = grep { _valid_location($_->{'place'}) } @rows;

    _valid_location('Ramsgate, Kent');  # 1
    _valid_location('3.14');            # 1 - has a '.'
    _valid_location('0044');            # 0 - digits only
    _valid_location('');                # 0
    _valid_location(undef);             # 0
    _valid_location(['London']);        # 0 - a reference, never dereferenced

=head3 API SPECIFICATION

=head4 INPUT

Positional, in L<Params::Validate::Strict> notation.  Any value is accepted:
the predicate's job is to answer for a bad value, not to reject it, so nothing
here can fail validation.

    [
        {
            name     => 'location',
            type     => 'any',      # scalar, undef or reference
            optional => 1,          # no argument is the same as undef
        },
    ]

=head4 OUTPUT

In L<Return::Set> notation:

    {
        type => 'integer',
        min  => 0,
        max  => 1,
    }

=head3 MESSAGES

None.  The routine never croaks, carps, dies or warns, whatever it is given;
a refusal is the return value C<0>.

=head3 FORMAL SPECIFICATION

    [VALUE, CHAR]

    STRING  : ℙ VALUE                 -- defined non-reference scalars
    chars   : STRING → seq CHAR       -- the string as perl stringifies it
    DIGIT   : ℙ CHAR                  -- Unicode general category Nd

    ┌─ ValidLocation ─────────────────────────────────
    │ location? : VALUE
    │ result!   : {0, 1}
    ├─────────────────────────────────────────────────
    │ result! = 1 ⇔
    │     location? ∈ STRING ∧
    │     (∃ i : dom chars(location?) • chars(location?) i ∉ DIGIT)
    └─────────────────────────────────────────────────

The empty string needs no clause of its own: C<dom E<lt>E<gt> = ∅>, so the
existential is false and C<result! = 0>.

=cut

# One expression, one exit: the three disqualifications are tested in order of
# cost, and each short-circuits the next.  ref() comes before the match so that
# an object is never stringified - its "" overload is not called and cannot die
# or have side effects.  No length() test is needed: '' has no non-digit, so the
# match already refuses it.
sub _valid_location {
	my $location = shift;

	return (defined($location) && !ref($location) && $location =~ /\D/) ? 1 : 0;
}

1;

__END__

=head1 LIMITATIONS

These are deliberate, but each one is a place where the rule can be argued
with.  Changing any of them changes the answer for all eight callers at once,
so they are listed rather than silently fixed.

=over 4

=item * Whitespace is a non-digit

C<' '>, C<"0044\n"> and C<' 0044 '> are all accepted.  The last two are exactly
the column mistake the rule exists to catch, when a line is not C<chomp>ed or
a fixed-width field is padded.  A caller reading such data should trim it
first.  A stricter rule would be C</[^\d\s]/>.

=item * The rule sees the stringification, not the number

C<-44> (a number) is accepted because it stringifies as C<'-44'>, while C<44>
is refused; the literal C<1e3> stringifies as C<'1000'> and is refused, while
the string C<'1e3'> is accepted.  The rule refuses "digits only", not
"numeric".

=item * Objects are refused even when they stringify to a place

An object with a C<""> overload (a URI, an address object) is refused as any
other reference is.  Stringifying it is the caller's job, and it is not done
here so that an overload cannot die inside the predicate.

=item * The name is private

The sub is a public, exported interface with a private-looking name.
L<Pod::Coverage> and L<Test::Pod::Coverage> will skip it, and a reader may
assume it can change.  It cannot: eight distributions call it by that name.

=item * Extra arguments are ignored

C<_valid_location(%row)> asks about the first key of the hash, in an
unpredictable order, and says nothing about the mistake.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2.
