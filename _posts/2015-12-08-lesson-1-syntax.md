---
layout: post
title:  "Lessons Learned #1: Syntax Matters"
date:   2015-12-08 16:07:00
---

Now that I've completed substantial amounts of work on the STS V1.5 operating system for the Kestrel-3,
I feel emboldened, perhaps foolishly, to document the lessons I've learned from the project.
From today until Christmas, I'll be posting at least one lesson learned from working on STS.

As you might already know,
I've created a simple programming language
built around Forth-like semantics
called [BSPL](http://kestrelcomputer.github.io/kestrel/2015/09/15/bspl-compiler/).
I'm using BSPL to implement a port of the Kestrel-2 operating system, STS, to the Kestrel-3.
So far, the work is a resounding success.
However, while happy with my progress and relative project velocity,
I can't help but feel that BSPL's RPN syntax has imposed a ceiling on my velocity.

## Repetitive Code

RPN notation is convenient and compact,
but is more difficult than I'd like
to add higher-level features to the language.
Unlike a proper Forth environment,
I cannot use BSPL to extend itself.
The language described by BSPL is as static in scope and capability as C is.
Even changing the [source code to the compiler itself](https://github.com/KestrelComputer/kestrel/tree/master/3/src/bspl)
proves not to be very easy,
as every syntax change runs the risk of breaking compatibility with my existing code-base,
or worse,
accidentally shadowing GForth features behind words intended for BSPL source listings.
Both has happened to me, and
the latter introduces particularly nasty bugs to track down.

There exists several places in STS
which have repetitive sequences of code.
For example, the following listing
configures the initial ROM-resident filesystem:

    : fs0
        objDirNew d> 0=if S" dir / failed" >d >d panic then
        d> rootnode !

        objDirNew d> 0=if S" dir /rom failed" >d >d panic then
        objEntNew d> 0=if S" ent /rom failed" >d >d panic then
        S" rom" >d >d 2 d@ >d objEntSetName d> 0=if S" nam /rom failed" >d >d panic then
        1 d@ >d 1 d@ >d objEntSetObject
        0 d@ >d rootnode @ >d objDirAddHead

        ( root[dir ent] )

        romFileNew d> 0=if S" fil /rom/foo failed" >d >d panic then
        S" Hello" >d >d 2 d@ >d romFileSetContents
        objEntNew d> 0=if S" ent /rom/foo failed" >d >d panic then
        S" foo" >d >d 2 d@ >d objEntSetName d> 0=if S" nam /rom/foo failed" >d >d panic then
        1 d@ >d 1 d@ >d objEntSetObject
        0 d@ >d 4 d@ >d objDirAddHead
        d> d>

        romFileNew d> 0=if S" fil /rom/hello failed" >d >d panic then
        prg_hello_start prg_hello_len 2 d@ >d romFileSetContents
        objEntNew d> 0=if S" ent /rom/hello failed" >d >d panic then
        S" hello" >d >d 2 d@ >d objEntSetName d> 0=if S" nam /rom/hello failed" >d >d panic then
        1 d@ >d 1 d@ >d objEntSetObject
        0 d@ >d 4 d@ >d objDirAddHead
        d> d>

        romFileNew d> 0=if S" fil /rom/fbtest failed" >d >d panic then
        prg_fbtest_start prg_fbtest_len 2 d@ >d romFileSetContents
        objEntNew d> 0=if S" ent /rom/fbtest failed" >d >d panic then
        S" fbtest" >d >d 2 d@ >d objEntSetName d> 0=if S" nam /rom/fbtest failed" >d >d panic then
        1 d@ >d 1 d@ >d objEntSetObject
        0 d@ >d 4 d@ >d objDirAddHead
        d> d>

        romFileNew d> 0=if S" fil /rom/m2 failed" >d >d panic then
        prg_m2_start prg_m2_len 2 d@ >d romFileSetContents
        objEntNew d> 0=if S" ent /rom/m2 failed" >d >d panic then
        S" m2" >d >d 2 d@ >d objEntSetName d> 0=if S" nam /rom/m2 failed" >d >d panic then
        1 d@ >d 1 d@ >d objEntSetObject
        0 d@ >d 4 d@ >d objDirAddHead
        d> d>

        romFileNew d> 0=if S" fil /rom/m2.slides failed" >d >d panic then
        prg_m2slides_start prg_m2slides_len 2 d@ >d romFileSetContents
        objEntNew d> 0=if S" ent /rom/m2.slides failed" >d >d panic then
        S" m2.slides" >d >d 2 d@ >d objEntSetName d> 0=if S" nam /rom/m2.slides failed" >d >d panic then
        1 d@ >d 1 d@ >d objEntSetObject
        0 d@ >d 4 d@ >d objDirAddHead
        d> d>

        ( root[dir ent] )

        d> d> ;

Notice the stuttering in the code.
I can rely on a macro processor like `m4`,
and I'll almost certainly go this route in a future refactoring of STS.
However, we must admit that this additional step makes building the software that much more inconvenient.
It's an additional dependency,
it adds time to the compile cycle since we need more invokations of `redo`,
and speaking of which, complects the `redo` configuration needed to properly build `stsv1.rom`.

Less importantly to me,
but definitely a red flag to language purists,
it also introduces a wildly different syntax than BSPL itself.
You might think this is a cosmetic issue, but it has merit when untangling hard to detect bugs.
The compiler will of course complain about the *post*-processed source,
not the original source.
Thus, the maintainer will need to maintain a mental model of
how the post-processed source relates to the pre-processed source.
The greater the use of macros,
*or*,
the more macros you define (even if used sparingly)
will result in greater confusion when trying to reconstruct the precondition behind a bug.

Yuck.

It'd be nice if macros were ingrained right into the language itself,
even if BSPL remained a statically-compiled language like C.
Which brings us to ...

## Ease of Writing New BSPL Features

In C, you have the expressive power to create complex data structures in-place.
This could have been used to build a directory layout for the ROM filesystem without incurring any code overhead.
For example, taking the above definition of `fs0` and turning it into a C data structure, we can write:

    /* Convenience definitions; perhaps in a header file somewhere. */

    #define struct ObjDir OBJDIR;
    #define struct ObjEnt OBJENT;
    #define struct RomFile ROMFILE;

    OBJENT _m2slides = { NULL,       &_m2,     "m2.slides", (OBJ *)&_m2slidesfile, etc };
    OBJENT _m2 =       { &_m2slides, &_fbtest, "m2",        (OBJ *)&_m2file,       etc };
    OBJENT _fbtest =   { &_m2,       &_hello,  "fbtest",    (OBJ *)&_fbtestfile,   etc };
    OBJENT _hello =    { &_fbtest,   &_foo,    "hello",     (OBJ *)&_hellofile,    etc };
    OBJENT _foo =      { &_hello,    NULL,     "foo",       (OBJ *)&_foofile,      etc };

    OBJDIR _romdir = { &romDirVTable, _foo, _m2slides };

    OBJENT _rom =      { NULL,       NULL,     "rom",       (OBJ *)&_romdir,       etc };

    OBJDIR _root =   { &romDirVTable, _rom, _rom };

OK, my doubly-linked lists no longer are circular like they are in STS today,
however, you can plainly see that static data structure declarations in C are surprisingly powerful,
and we're able to express entirely in data
what took about 50 lines of copy-pasta,
that you must arrange to run somehow,
to do in raw BSPL code.

BSPL can't even declare a single integer statically while still being able to reference it.
That is, yes, I can declare an integer statically, but I cannot later reference it.
The original intention behind this was to embed structures called "rom tags",
where they'd be discovered through a scan through memory.
However, I've since abandoned this implementation on the basis of overall complexity.
So, BSPL's static data declaration facilities remain vestigial, and almost completely useless.

However, adding the syntax to BSPL to support complex data declarations like the above is
challenging,
to say the least,
particularly since BSPL's RPN semantics depends so heavily on declare-before-use to
not only get naming right, but also space allocation.

## Why S-Expressions

The problem is that RPN,
at least as far as BSPL is concerned,
is entirely context-free.
It's great when you can get away with one-pass compilation;
as soon as you need to examine the context in which a construct appears, though,
it falls flat.
To support the distinction between macros (compile-time function calls) and run-time function calls,
you need additional context.
To support the declaration of a web of related data structures in memory,
you *definitely* need additional context.
Heck, to determine if `1 == 0` sets a flag or compiles to a `bne` instruction
requires that we examine the context in which this expression appears.

But you don't want *too much*;
you only want appropriate levels of context for an appropriate amount of time.
Often,
that time is lexically bounded.
BSPL, as it currently stands, cannot support this.

But, s-expressions *can*.

S-expressions are *almost* as simple to work with as RPN
(they are, in fact, *forward* Polish notation),
and *almost* as compact.
Perhaps most importantly, though,
they are inherently lexically structured.

Although you now need a parser in addition to a simple lexer,
the regular structure greatly simplifies the parser.

I won't get into a complete treatise about how applicable s-expressions are for my needs,
but I will illustrate both
the declaration of a complex web of structures
and the use of macros
using a single, completely hypothetical, syntax for a completely hypothetical compiler:

    (data 
      (objent _m2slides (nil _m2 "m2.slides" _m2slidesfile ...))
      (objent _m2 (_m2slides _fbtest "m2" _m2file ...))
      (objent _fbtest (_m2 _hello "fbtest" _fbtestfile ...))
      (objent _hello (_fbtest _foo "hello" _hellofile ...))
      (objent _foo (_hello nil "foo" _foofile ...))
      (objent _rom (nil nil "rom" _romdir ...))

      (objdir _romdir (_foo _m2slides ...))
      (objdir _root (_rom _rom ...)))

Some things to note here:

1. No need to explicitly associate v-tables with data structures, since we can rely on `objdir` being a macro sufficiently powerful to do this automatically for us.  This reduces errors and makes the code easier to read.
2. We can write the compiler to allow nested structure definitions, so definitions like `_m2slidesfile` can be *in-line* in the source code, even if they're not in memory.  Again, this is the power that macro/function syntax unification can provide.
3. You'll notice that we don't include any forward declarations in the opening clause to `(data)`.  Strictly speaking, it's not necessary, as all symbols in my graph are explicitly named already.  Whatever code handles `data` in the compiler can depend on this for symbol resolution.  Traditional methods of working around declare-before-use situations would involve the use of [literate programming](http://literateprogramming.com/) toolchains, which are increasingly awkward to use in today's programming environments.  With RPN, I can forward-declare names, but I cannot detect space allocation needs ahead of time (at least, not easily).  With s-expressions, I can *easily* do both.

I want to re-iterate:
the above example is hypothetical.
No such language exists with this syntax yet,
though competent Lisp programmer could whip something like this up easily enough.

## Lesson Learned

Next time I write a compiler for the Kestrel-3,
it will use s-expressions for input.
And, the neat thing is, I might not have to reinvent the wheel.
It turns out, the world is already working on such a syntax,
called [Web Assembly](https://blog.mozilla.org/luke/2015/06/17/webassembly/).
A proper subset of Web Assembly, suitable for systems level programming,
should be quite capable of supporting all of my needs.
