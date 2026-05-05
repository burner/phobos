// Written in the D programming language.

/**
This module defines the notion of a range. Ranges generalize the concept of
arrays, lists, or anything that involves sequential access. This abstraction
enables the same set of algorithms (see $(MREF std, algorithm)) to be used
with a vast variety of different concrete types. For example,
a linear search algorithm such as $(REF find, std, algorithm, searching)
works not just for arrays, but for linked-lists, input files,
incoming network data, etc.

Guides:

There are many articles available that can bolster understanding ranges:

$(UL
    $(LI Ali Çehreli's $(HTTP ddili.org/ders/d.en/ranges.html, tutorial on ranges)
        for the basics of working with and creating range-based code.)
    $(LI Jonathan M. Davis $(LINK2 http://dconf.org/2015/talks/davis.html, $(I Introduction to Ranges))
        talk at DConf 2015 a vivid introduction from its core constructs to practical advice.)
    $(LI The DLang Tour's $(LINK2 http://tour.dlang.org/tour/en/basics/ranges, chapter on ranges)
        for an interactive introduction.)
    $(LI H. S. Teoh's $(LINK2 http://wiki.dlang.org/Component_programming_with_ranges, tutorial on
        component programming with ranges) for a real-world showcase of the influence
        of range-based programming on complex algorithms.)
    $(LI Andrei Alexandrescu's article
        $(LINK2 http://www.informit.com/articles/printerfriendly.aspx?p=1407357$(AMP)rll=1,
        $(I On Iteration)) for conceptual aspect of ranges and the motivation
    )
)

Submodules:

This module has two submodules:

The $(MREF std, range, primitives) submodule
provides basic range functionality. It defines several templates for testing
whether a given object is a range, what kind of range it is, and provides
some common range operations.

The $(MREF std, range, interfaces) submodule
provides object-based interfaces for working with ranges via runtime
polymorphism.

The remainder of this module provides a rich set of range creation and
composition templates that let you construct new ranges out of existing ranges:


$(SCRIPT inhibitQuickIndex = 1;)
$(DIVC quickindex,
$(BOOKTABLE ,
    $(TR $(TD $(LREF chain))
        $(TD Concatenates several ranges into a single range.
    ))
    $(TR $(TD $(LREF choose))
        $(TD Chooses one of two ranges at runtime based on a boolean condition.
    ))
    $(TR $(TD $(LREF chooseAmong))
        $(TD Chooses one of several ranges at runtime based on an index.
    ))
    $(TR $(TD $(LREF chunks))
        $(TD Creates a range that returns fixed-size chunks of the original
        range.
    ))
    $(TR $(TD $(LREF cycle))
        $(TD Creates an infinite range that repeats the given forward range
        indefinitely. Good for implementing circular buffers.
    ))
    $(TR $(TD $(LREF drop))
        $(TD Creates the range that results from discarding the first $(I n)
        elements from the given range.
    ))
    $(TR $(TD $(LREF dropBack))
        $(TD Creates the range that results from discarding the last $(I n)
        elements from the given range.
    ))
    $(TR $(TD $(LREF dropExactly))
        $(TD Creates the range that results from discarding exactly $(I n)
        of the first elements from the given range.
    ))
    $(TR $(TD $(LREF dropBackExactly))
        $(TD Creates the range that results from discarding exactly $(I n)
        of the last elements from the given range.
    ))
    $(TR $(TD $(LREF dropOne))
        $(TD Creates the range that results from discarding
        the first element from the given range.
    ))
    $(TR $(TD $(LREF dropBackOne))
        $(TD Creates the range that results from discarding
        the last element from the given range.
    ))
    $(TR $(TD $(LREF enumerate))
        $(TD Iterates a range with an attached index variable.
    ))
    $(TR $(TD $(LREF evenChunks))
        $(TD Creates a range that returns a number of chunks of
        approximately equal length from the original range.
    ))
    $(TR $(TD $(LREF frontTransversal))
        $(TD Creates a range that iterates over the first elements of the
        given ranges.
    ))
    $(TR $(TD $(LREF generate))
        $(TD Creates a range by successive calls to a given function. This
        allows to create ranges as a single delegate.
    ))
    $(TR $(TD $(LREF indexed))
        $(TD Creates a range that offers a view of a given range as though
        its elements were reordered according to a given range of indices.
    ))
    $(TR $(TD $(LREF iota))
        $(TD Creates a range consisting of numbers between a starting point
        and ending point, spaced apart by a given interval.
    ))
    $(TR $(TD $(LREF lockstep))
        $(TD Iterates $(I n) ranges in lockstep, for use in a `foreach`
        loop. Similar to `zip`, except that `lockstep` is designed
        especially for `foreach` loops.
    ))
    $(TR $(TD $(LREF nullSink))
        $(TD An output range that discards the data it receives.
    ))
    $(TR $(TD $(LREF only))
        $(TD Creates a range that iterates over the given arguments.
    ))
    $(TR $(TD $(LREF padLeft))
        $(TD Pads a range to a specified length by adding a given element to
        the front of the range. Is lazy if the range has a known length.
    ))
    $(TR $(TD $(LREF padRight))
        $(TD Lazily pads a range to a specified length by adding a given element to
        the back of the range.
    ))
    $(TR $(TD $(LREF radial))
        $(TD Given a random-access range and a starting point, creates a
        range that alternately returns the next left and next right element to
        the starting point.
    ))
    $(TR $(TD $(LREF recurrence))
        $(TD Creates a forward range whose values are defined by a
        mathematical recurrence relation.
    ))
    $(TR $(TD $(LREF refRange))
        $(TD Pass a range by reference. Both the original range and the RefRange
        will always have the exact same elements.
        Any operation done on one will affect the other.
    ))
    $(TR $(TD $(LREF repeat))
        $(TD Creates a range that consists of a single element repeated $(I n)
        times, or an infinite range repeating that element indefinitely.
    ))
    $(TR $(TD $(LREF retro))
        $(TD Iterates a bidirectional range backwards.
    ))
    $(TR $(TD $(LREF roundRobin))
        $(TD Given $(I n) ranges, creates a new range that return the $(I n)
        first elements of each range, in turn, then the second element of each
        range, and so on, in a round-robin fashion.
    ))
    $(TR $(TD $(LREF sequence))
        $(TD Similar to `recurrence`, except that a random-access range is
        created.
    ))
    $(TR $(TD $(LREF slide))
        $(TD Creates a range that returns a fixed-size sliding window
        over the original range. Unlike chunks,
        it advances a configurable number of items at a time,
        not one chunk at a time.
    ))
    $(TR $(TD $(LREF stride))
        $(TD Iterates a range with stride $(I n).
    ))
    $(TR $(TD $(LREF tail))
        $(TD Return a range advanced to within `n` elements of the end of
        the given range.
    ))
    $(TR $(TD $(LREF take))
        $(TD Creates a sub-range consisting of only up to the first $(I n)
        elements of the given range.
    ))
    $(TR $(TD $(LREF takeExactly))
        $(TD Like `take`, but assumes the given range actually has $(I n)
        elements, and therefore also defines the `length` property.
    ))
    $(TR $(TD $(LREF takeNone))
        $(TD Creates a random-access range consisting of zero elements of the
        given range.
    ))
    $(TR $(TD $(LREF takeOne))
        $(TD Creates a random-access range consisting of exactly the first
        element of the given range.
    ))
    $(TR $(TD $(LREF tee))
        $(TD Creates a range that wraps a given range, forwarding along
        its elements while also calling a provided function with each element.
    ))
    $(TR $(TD $(LREF transposed))
        $(TD Transposes a range of ranges.
    ))
    $(TR $(TD $(LREF transversal))
        $(TD Creates a range that iterates over the $(I n)'th elements of the
        given random-access ranges.
    ))
    $(TR $(TD $(LREF zip))
        $(TD Given $(I n) ranges, creates a range that successively returns a
        tuple of all the first elements, a tuple of all the second elements,
        etc.
    ))
))

Sortedness:

Ranges whose elements are sorted afford better efficiency with certain
operations. For this, the $(LREF assumeSorted) function can be used to
construct a $(LREF SortedRange) from a pre-sorted range. The $(REF
sort, std, algorithm, sorting) function also conveniently
returns a $(LREF SortedRange). $(LREF SortedRange) objects provide some additional
range operations that take advantage of the fact that the range is sorted.

Source: $(PHOBOSSRC std/range/package.d)

License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors: $(HTTP erdani.com, Andrei Alexandrescu), David Simcha,
         $(HTTP jmdavisprog.com, Jonathan M Davis), and Jack Stouffer. Credit
         for some of the ideas in building this module goes to
         $(HTTP fantascienza.net/leonardo/so/, Leonardo Maffi).
 */
module std.range;
public import std.range.range;
