---
layout: post
title:  "Lessons Learned #2: Records"
date:   2015-12-08 16:07:00
---

Right now, BSPL offers three methods of accessing state.
Global variables may be referenced by name; for instance, `mplsta`.
Local variables and parameters don't exist as first-class objects.
Instead, both are created or referenced using data stack accessors,
such as `>d`, `d@`, `d!`, and `d>`.
Finally,
record and array fields are typically referenced using `@` and `!`,
often preceeded with an effective address calculation.
As you might imagine,
this can make for some pretty noisy source listings,
particularly when records are involved.

And they *will* be involved.  A lot.

## Some Free-Thinking on Record Access Syntax

Access to record fields happens very frequently in STS, and
it's not hard to imagine that they'd
also be frequent in many applications as well.
Effective address calculations dominate a surprising number of lines of code.
Getting these calculations conceptually right has not proven to be a problem.
However, *practically* speaking,
they introduce opportunities for hard to find typos
that makes code crash and burn.
Finding these typos is often a time-consuming practice.
Introducing some syntax
to automate effective address calculations
is warranted.

Often, one particular entity holds special significance;
it's often convenient to think about something happening *to* this entity,
particularly if in-place updates to the entity are involved.
When working with such a significant entity,
it'd be notationally very convenient to refer to members
as conveniently as local variables, parameters, or global variables.
In this situation,
no new syntax is needed at all.

If we assume an s-expression-based systems programming language
as recommended in lesson 1,
then we can rely
on the lexical knowledge
afforded to the compiler
by the nesting nature of s-expressions
to figure out the context of a symbol.

Let's start
with a Lispy transliteration
of our current BSPL code
to initialize a memory pool.

    (vars (mplsta mplsiz))

    (: (fmtmem start size) ()
        (set (mplsta mplsiz) (start size))
        
        ; initialize memory chunk list (circular list; node points to itself).
        (! mplsta mplsta)

        ; node describes 16 bytes less than the total memory pool,
        ; since our header is 16 bytes in size.
        (! (+ 8 mplsta) (- (& -16 mplsiz) 16))
    )

Notice the effective address calculation,
`(+ 8 mplsta)`.
For code as simple as this, it's probably fine;
you can figure out from the comments what the fields are.
Ideally, though, we'd like our code to be as self-documenting as possible.
Comments should be used sparingly;
they fall out of date quickly,
and consume 5 of the 10 lines of code comprising `fmtmem` alone.

If we borrow a concept from Pascal,
we can introduce a `with`-construct to associate a type with a pointer,
and in the process establishing a lexical context where unqualified symbols
are checked against the record the base pointer refers to.

    (vars (mplsta mplsiz))

    (record MemPoolNode (next size))

    (: (fmtmem start size) ()
        (set (mplsta mplsiz) (start size))
        (with MemPoolNode mplsta
            (set next mplsta)
            (set size (- (& -16 mplsiz) 16))
        )
    )

This is an improvement;
the compiler would understand
that `next` and `size`
refer to fields of `MemPoolNode`,
and the `with` statement tells the compiler
that such a record exists at the base address pointed at in `mplsta`.

What if we need to work with several different entities of the same type?
We need a way to disambiguate one instance from another.
Typical languages use an infix operator,
`.` or `:`,
to navigation of scopes.
These operations tuck all the effective address calculation under the carpet.
But, in a Lispy language without some syntax sugar,
it's not as convenient.
We'd have to write `X.Y` as `(. X Y)`.

For example,
STS needs a procedure to split a large memory chunk into two smaller chunks,
one of which is allocated, the other free.
Here's what it might look like without any convenient syntax:

    (: (gmsplit u a) (nxt)
        (if (< (+ u 32) (& -16 (@ (+ a 8)))) (
            (set nxt (+ a u 16))
            (! nxt (@ a))
            (! (+ 8 nxt) (- (- (@ (+ a 8)) u) 16))
            (! a nxt)
            (! (+ 8 a) (| 1 u))
        ) (
            (! (+ 8 a) (| 1 (@ (+ 8 a))))
        )
    )

We can wrap one instance of the MemPoolNode with a `with` statement:

    (: (gmsplit u a) (n)
        (with MemPoolNode a (
            (if (< (+ u 32) (& -16 size)) (
                (set n (+ a u 16))
                (! n next)
                (! (+ 8 n) (- (- size u) 16))
                (set next n)
                (set size (| 1 u))
            ) (
                (set size (| 1 size))
            )
        )
    )

The consequent of the `if`-statement demonstrates where `with` breaks down.
Note that we touch the fields of both nodes with about equal frequency,
but *how* we do so is different between them.
We need a different method of accessing fields.

I'm going to borrow a bit from Lisp and PL/I here,
and replace `with` with `declare`.
Unlike Lisp and PL/I, though,
my `declare` is lexically scoped, like `with`:

    (: (gmsplit u a) (n)
        (declare ((a n) (ptr MemPoolNode))
            (if (< (+ u 32) (& -16 (. a size))) (
                (set n (+ a u 16))
                (set (. n next) (. a next))
                (set (. n size) (- (- (. a size) u) 16))
                (set (. a next) n)
                (set (. a size) (| 1 u))
            ) (
                (set (. a size) (| 1 (. a size)))
            )
        )
    )

We're telling the compiler to treat `a` and `n` as pointers to a MemPoolNode.
This gives the compiler enough context so that
`.` knows how to interpret the member reference.
If we sacrifice a compiler pass to syntax desugaring,
we can improve the syntax further:

    (: (gmsplit u a) (n)
        (declare ((a n) (ptr MemPoolNode))
            (if (< (+ u 32) (& -16 a:size)) (
                (set n (+ a u 16))
                (set n:next a:next)
                (set n:size (- (- a:size u) 16))
                (set a:next n)
                (set a:size (| 1 u))
            ) (
                (set a:size (| 1 a:size))
            )
        )
    )

This is substantially more clear to the casual reader,
even accounting for the single-letter variable names.
Now that we have enough context to declutter the program listing,
it actually frees us to use more meaningful variable names.

    (: (gmsplit blklen thisNode) (newNode)
        (declare ((thisNode newNode) (ptr MemPoolNode))
            (if (< (+ blklen 32) (& -16 thisNode:size)) (
                (set newNode (+ thisNode blklen 16))
                (set newNode:next thisNode:next)
                (set newNode:size (- (- thisNode:size blklen) 16))
                (set thisNode:next newNode)
                (set thisNode:size (| 1 blklen))
            ) (
                (set thisNode:size (| 1 thisNode:size))
            )
        )
    )

You might notice a pattern, though.
Whenever we have multiple instances of an entity,
it's typically in the context of object construction or replication.
Not always, as a review of STS source listing will show.
But, enough that we might gain from a class-oriented notation.

    (class MemPoolNode
        (next size)

        (: (init n s) ()
            (set (next size) (n s)))

        (: (gmsplit blklen) (newNode)
            (declare (newNode (ptr MemPoolNode))
                (if (< (+ blklen 32) (& -16 size)) (
                    (set newNode (+ $ blklen 16))
                    (newNode:init next (- (- size blklen) 16))
                    (init newNode (| 1 blklen))
                ) (
                    (set size (| 1 size))
                )
            )
        )
    )

Some things to take note of:

1. The "self" pseudo-pointer is simply `$`.
2. Members of `$` need no particular qualification.
3. We no longer need an explicit `with` construct.
4. Methods on `$` are invoked like any other procedure.

These features allow us to revisit `fmtmem` from the very beginning:

    (vars mplsta mplsiz)

    (: (fmtmem start size) ()
        (set (mplsta mplsiz) (start size))
        (declare (start (ptr MemPoolNode))
            (start:init start (- (& -16 size) 16)))

## Lesson Learned

It's clear that whatever language replaces BSPL
in the future
must provide raw memory accessors,
such as `@` and `!` to fetch and store to arbitrary memory locations.
I think this is a given.

However,
introducing complexity in the compiler to recognize record types and their
members as first-class constructs
will yield significant rewards in both
reading comprehension of a source listing and
developer productivity.

Once again, everything you read above is just free-thinking on the subject.
I don't know what the actual syntax will look like.
If I adopt WebAssembly, that decision will have been made for me,
and I could potentially use higher-level languages still
as long as they compile to that format.

