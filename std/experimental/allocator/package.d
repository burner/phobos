// Written in the D programming language.
/**

High-level interface for allocators. Implements bundled allocation/creation
and destruction/deallocation of data including `struct`s and `class`es,
and also array primitives related to allocation. This module is the entry point
for both making use of allocators and for their documentation.

$(SCRIPT inhibitQuickIndex = 1;)
$(BOOKTABLE,
$(TR $(TH Category) $(TH Functions))
$(TR $(TD Make) $(TD
    $(LREF make)
    $(LREF makeArray)
    $(LREF makeMultidimensionalArray)
))
$(TR $(TD Dispose) $(TD
    $(LREF dispose)
    $(LREF disposeMultidimensionalArray)
))
$(TR $(TD Modify) $(TD
    $(LREF expandArray)
    $(LREF shrinkArray)
))
$(TR $(TD Global) $(TD
    $(LREF processAllocator)
    $(LREF theAllocator)
))
$(TR $(TD Class interface) $(TD
    $(LREF CAllocatorImpl)
    $(LREF CSharedAllocatorImpl)
    $(LREF IAllocator)
    $(LREF ISharedAllocator)
))
$(TR $(TD Structs) $(TD
    $(LREF allocatorObject)
    $(LREF RCIAllocator)
    $(LREF RCISharedAllocator)
    $(LREF sharedAllocatorObject)
    $(LREF ThreadLocal)
))
)

Synopsis:
$(RUNNABLE_EXAMPLE
---
// Allocate an int, initialize it with 42
int* p = theAllocator.make!int(42);
assert(*p == 42);
// Destroy and deallocate it
theAllocator.dispose(p);

// Allocate using the global process allocator
p = processAllocator.make!int(100);
assert(*p == 100);
// Destroy and deallocate
processAllocator.dispose(p);
---
)
$(RUNNABLE_EXAMPLE
---
// Create an array of 50 doubles initialized to -1.0
double[] arr = theAllocator.makeArray!double(50, -1.0);
// Append two zeros to it
theAllocator.expandArray(arr, 2, 0.0);
// On second thought, take that back
theAllocator.shrinkArray(arr, 2);
// Destroy and deallocate
theAllocator.dispose(arr);
---
)

$(H2 Layered Structure)

D's allocators have a layered structure in both implementation and documentation:

$(OL
$(LI A high-level, dynamically-typed layer (described further down in this
module). It consists of an interface called $(LREF IAllocator), which concrete
allocators need to implement. The interface primitives themselves are oblivious
to the type of the objects being allocated; they only deal in `void[]`, by
necessity of the interface being dynamic (as opposed to type-parameterized).
Each thread has a current allocator it uses by default, which is a thread-local
variable $(LREF theAllocator) of type $(LREF IAllocator). The process has a
global allocator called $(LREF processAllocator), also of type $(LREF
IAllocator). When a new thread is created, $(LREF processAllocator) is copied
into $(LREF theAllocator). An application can change the objects to which these
references point. By default, at application startup, $(LREF processAllocator)
refers to an object that uses D's garbage collected heap. This layer also
include high-level functions such as $(LREF make) and $(LREF dispose) that
comfortably allocate/create and respectively destroy/deallocate objects. This
layer is all needed for most casual uses of allocation primitives.)

$(LI A mid-level, statically-typed layer for assembling several allocators into
one. It uses properties of the type of the objects being created to route
allocation requests to possibly specialized allocators. This layer is relatively
thin and implemented and documented in the $(MREF
std,experimental,allocator,typed) module. It allows an interested user to e.g.
use different allocators for arrays versus fixed-sized objects, to the end of
better overall performance.)

$(LI A low-level collection of highly generic $(I heap building blocks)$(MDASH)
Lego-like pieces that can be used to assemble application-specific allocators.
The real allocation smarts are occurring at this level. This layer is of
interest to advanced applications that want to configure their own allocators.
A good illustration of typical uses of these building blocks is module $(MREF
std,experimental,allocator,showcase) which defines a collection of frequently-
used preassembled allocator objects. The implementation and documentation entry
point is $(MREF std,experimental,allocator,building_blocks). By design, the
primitives of the static interface have the same signatures as the $(LREF
IAllocator) primitives but are for the most part optional and driven by static
introspection. The parameterized class $(LREF CAllocatorImpl) offers an
immediate and useful means to package a static low-level allocator into an
implementation of $(LREF IAllocator).)

$(LI Core allocator objects that interface with D's garbage collected heap
($(MREF std,experimental,allocator,gc_allocator)), the C `malloc` family
($(MREF std,experimental,allocator,mallocator)), and the OS ($(MREF
std,experimental,allocator,mmap_allocator)). Most custom allocators would
ultimately obtain memory from one of these core allocators.)
)

$(H2 Idiomatic Use of `std.experimental.allocator`)

As of this time, `std.experimental.allocator` is not integrated with D's
built-in operators that allocate memory, such as `new`, array literals, or
array concatenation operators. That means `std.experimental.allocator` is
opt-in$(MDASH)applications need to make explicit use of it.

For casual creation and disposal of dynamically-allocated objects, use $(LREF
make), $(LREF dispose), and the array-specific functions $(LREF makeArray),
$(LREF expandArray), and $(LREF shrinkArray). These use by default D's garbage
collected heap, but open the application to better configuration options. These
primitives work either with `theAllocator` but also with any allocator obtained
by combining heap building blocks. For example:

----
void fun(size_t n)
{
    // Use the current allocator
    int[] a1 = theAllocator.makeArray!int(n);
    scope(exit) theAllocator.dispose(a1);
    ...
}
----

To experiment with alternative allocators, set $(LREF theAllocator) for the
current thread. For example, consider an application that allocates many 8-byte
objects. These are not well supported by the default allocator, so a
$(MREF_ALTTEXT free list allocator,
std,experimental,allocator,building_blocks,free_list) would be recommended.
To install one in `main`, the application would use:

----
void main()
{
    import std.experimental.allocator.building_blocks.free_list
        : FreeList;
    theAllocator = allocatorObject(FreeList!8());
    ...
}
----

$(H3 Saving the `IAllocator` Reference For Later Use)

As with any global resource, setting `theAllocator` and `processAllocator`
should not be done often and casually. In particular, allocating memory with
one allocator and deallocating with another causes undefined behavior.
Typically, these variables are set during application initialization phase and
last through the application.

To avoid this, long-lived objects that need to perform allocations,
reallocations, and deallocations relatively often may want to store a reference
to the allocator object they use throughout their lifetime. Then, instead of
using `theAllocator` for internal allocation-related tasks, they'd use the
internally held reference. For example, consider a user-defined hash table:

----
struct HashTable
{
    private IAllocator allocator;
    this(size_t buckets, IAllocator allocator = theAllocator) {
        this.allocator = allocator;
        ...
    }
    // Getter and setter
    IAllocator allocator() { return allocator; }
    void allocator(IAllocator a) { assert(empty); allocator = a; }
}
----

Following initialization, the `HashTable` object would consistently use its
`allocator` object for acquiring memory. Furthermore, setting
`HashTable.allocator` to point to a different allocator should be legal but
only if the object is empty; otherwise, the object wouldn't be able to
deallocate its existing state.

$(H3 Using Allocators without `IAllocator`)

Allocators assembled from the heap building blocks don't need to go through
`IAllocator` to be usable. They have the same primitives as `IAllocator` and
they work with $(LREF make), $(LREF makeArray), $(LREF dispose) etc. So it
suffice to create allocator objects wherever fit and use them appropriately:

----
void fun(size_t n)
{
    // Use a stack-installed allocator for up to 64KB
    StackFront!65536 myAllocator;
    int[] a2 = myAllocator.makeArray!int(n);
    scope(exit) myAllocator.dispose(a2);
    ...
}
----

In this case, `myAllocator` does not obey the `IAllocator` interface, but
implements its primitives so it can work with `makeArray` by means of duck
typing.

One important thing to note about this setup is that statically-typed assembled
allocators are almost always faster than allocators that go through
`IAllocator`. An important rule of thumb is: "assemble allocator first, adapt
to `IAllocator` after". A good allocator implements intricate logic by means of
template assembly, and gets wrapped with `IAllocator` (usually by means of
$(LREF allocatorObject)) only once, at client level.

Copyright: Andrei Alexandrescu 2013-.

License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).

Authors: $(HTTP erdani.com, Andrei Alexandrescu)

Source: $(PHOBOSSRC std/experimental/allocator)

*/

module std.experimental.allocator;
public import std.experimental.allocator.allocator;
