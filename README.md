## Name

Geo::Location::Predicate - The rule that decides whether a string could be a location

## Version

Version 0.01

## Synopsis

```perl
use Geo::Location::Predicate qw(_valid_location);

if(_valid_location($row->{'place'})) {
    # worth a lookup
}
```

## Description

One question: could this string be a location at all?

It is asked in three places by [Geo::Coder::Free](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree) - of a `location` and of a
`scantext` before it queries a backend, and by
[Geo::Coder::Free::MaxMind](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree%3A%3AMaxMind) and [Geo::Coder::Free::OpenAddresses](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree%3A%3AOpenAddresses) of what a
caller hands them directly - and by the six sibling geocoders that look a place
up in their own service.  The rule lives here rather than being written out at
each of those places, so they cannot drift apart on which strings are worth
looking up: a string the facade refuses must not be accepted by a backend, and
the other way round.

It is a cheap syntactic test and nothing more.  A `true` answer means the string
is not disqualified, **not** that a backend knows it: `'Ramsgate, Kent'` is a
location and may still find nothing.  What is disqualified is a string of digits
only, which is what a numeric column holds when the wrong column has been read,
plus `undef`, the empty string and a reference.  Anything with a non-digit
character in it counts, `'3.14'` and `'-'` included - including a comma, which
is why a rejected `'0044'` is a column mistake rather than a missing place.

The name is a predicate, not a promise: `true` does not mean the place exists,
and a geocoder for a service with numeric identifiers may want a different
policy, which is why this one is asked only when it is installed rather than
being a hard prerequisite of the six.

A caller should not need this module: [Geo::Coder::Free](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree) has the same rule in
public as `$geo->valid_location($row->{'place'})`, which is what a batch
caller should pre-filter with.  The sub is exported under its private name
because the facade, its backends and the six are the only intended callers, and
because its public spelling already exists and has a name a caller can rely on.

Installing this distribution is optional for the six siblings and required by
[Geo::Coder::Free](https://metacpan.org/pod/Geo%3A%3ACoder%3A%3AFree).  Each sibling declares it under `recommends` in its META
rather than as a prerequisite, and looks for it when it first needs it rather
than when it loads, so importing a sibling reads no file it may not have.  A
sibling without it still refuses a reference, which is the case none of them
could test for on its own, but it cannot answer the question about a numeric
column read by mistake - so the rule is asked when it is there, and what each
sibling does without it is documented by that sibling.

## Subroutines/Methods

### \_Valid\_Location

Whether the string handed to it could be a location.  False for `undef`, for
`''`, for a reference and for a string of digits only; true for anything else,
including a single punctuation character.

```perl
use Geo::Location::Predicate qw(_valid_location);

if(_valid_location($row->{'place'})) {
    # worth a lookup
}
```

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## License and Copyright

Copyright 2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2.
