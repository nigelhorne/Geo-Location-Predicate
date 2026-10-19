## Name

Geo::Location::Predicate - The rule that decides whether a string could be a location

## Version

Version 0.02

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
plus `undef`, the empty string and a reference.  Anything with at least one
non-digit character in it counts, `'3.14'`, `'-'` and `' '` included: the
rule refuses only what is certainly a number, so a rejected `'0044'` is a
column mistake rather than a place nobody has heard of.

"Digit" means a Unicode decimal digit (`\p{Nd}`), not only `0` to `9`, so
`"\x{0661}\x{0662}"` (Arabic-Indic one-two) is refused as `'12'` is.  The
answer does not depend on the locale, on whether the string carries the UTF-8
flag, or on a `use locale` in the caller's scope.

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

Purpose: say whether a value could be a location, so that a caller can skip a
lookup that cannot succeed.

Args: one value, of any kind.  Anything after the first argument is ignored.

Returns: `1` if the value is a non-reference scalar holding at least one
non-digit character; `0` otherwise - for `undef`, `''`, a reference
(blessed or not, overloaded or not) and a string of digits only.  Always
exactly one value, so it is safe in list context.

Side effects: none.  It does not croak, warn, change its argument, `$_`,
`$!`, `$@` or the caller's `$1`.

Usage: call it as a function, not a method; there is no object.

#### Example

```perl
use Geo::Location::Predicate qw(_valid_location);

# Skip rows whose 'place' column holds a postcode-less number by mistake
my @worth_looking_up = grep { _valid_location($_->{'place'}) } @rows;

_valid_location('Ramsgate, Kent');  # 1
_valid_location('3.14');            # 1 - has a '.'
_valid_location('0044');            # 0 - digits only
_valid_location('');                # 0
_valid_location(undef);             # 0
_valid_location(['London']);        # 0 - a reference, never dereferenced
```

#### Api Specification

##### Input

Positional, in [Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict) notation.  Any value is accepted:
the predicate's job is to answer for a bad value, not to reject it, so nothing
here can fail validation.

```perl
[
    {
        name     => 'location',
        type     => 'any',      # scalar, undef or reference
        optional => 1,          # no argument is the same as undef
    },
]
```

##### Output

In [Return::Set](https://metacpan.org/pod/Return%3A%3ASet) notation:

```perl
{
    type => 'integer',
    min  => 0,
    max  => 1,
}
```

#### Messages

None.  The routine never croaks, carps, dies or warns, whatever it is given;
a refusal is the return value `0`.

#### Formal Specification

```
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
```

The empty string needs no clause of its own: `dom <> = ∅`, so the
existential is false and `result! = 0`.

## Limitations

These are deliberate, but each one is a place where the rule can be argued
with.  Changing any of them changes the answer for all eight callers at once,
so they are listed rather than silently fixed.

- Whitespace is a non-digit

    `' '`, `"0044\n"` and `' 0044 '` are all accepted.  The last two are exactly
    the column mistake the rule exists to catch, when a line is not `chomp`ed or
    a fixed-width field is padded.  A caller reading such data should trim it
    first.  A stricter rule would be `/[^\d\s]/`.

- The rule sees the stringification, not the number

    `-44` (a number) is accepted because it stringifies as `'-44'`, while `44`
    is refused; the literal `1e3` stringifies as `'1000'` and is refused, while
    the string `'1e3'` is accepted.  The rule refuses "digits only", not
    "numeric".

- Objects are refused even when they stringify to a place

    An object with a `""` overload (a URI, an address object) is refused as any
    other reference is.  Stringifying it is the caller's job, and it is not done
    here so that an overload cannot die inside the predicate.

- The name is private

    The sub is a public, exported interface with a private-looking name.
    [Pod::Coverage](https://metacpan.org/pod/Pod%3A%3ACoverage) and [Test::Pod::Coverage](https://metacpan.org/pod/Test%3A%3APod%3A%3ACoverage) will skip it, and a reader may
    assume it can change.  It cannot: eight distributions call it by that name.

- Extra arguments are ignored

    `_valid_location(%row)` asks about the first key of the hash, in an
    unpredictable order, and says nothing about the mistake.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## License and Copyright

Copyright 2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License, version 2.
