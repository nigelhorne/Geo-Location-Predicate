package Geo::Coder::Free::Validate;

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
# The name is unchanged on purpose.  Every caller says
# Geo::Coder::Free::Validate::_valid_location(), including the facade and both of
# its backends, and a release that renamed it would break each of them for no
# gain; what moved is which distribution ships the file.
#
# The class - not the file - is the unit: L<Geo::Coder::Free> calls this rule and
# depends on this distribution, and the six call it when it is installed and fall
# back to refusing a reference when it is not.

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(_valid_location);

=encoding utf-8

=head1 NAME

Geo::Coder::Free::Validate - The rule that decides whether a string could be a location

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Geo::Coder::Free::Validate qw(_valid_location);

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
plus C<undef>, the empty string and a reference.  Anything with a non-digit
character in it counts, C<'3.14'> and C<'-'> included - including a comma, which
is why a rejected C<'0044'> is a column mistake rather than a missing place.

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

Whether the string handed to it could be a location.  False for C<undef>, for
C<''>, for a reference and for a string of digits only; true for anything else,
including a single punctuation character.

    use Geo::Coder::Free::Validate qw(_valid_location);

    if(_valid_location($row->{'place'})) {
        # worth a lookup
    }

=cut

sub _valid_location {
	my $location = shift;

	return 0 unless defined($location) && !ref($location) && length($location);
	return $location =~ /\D/ ? 1 : 0;
}

1;

__END__

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2.
