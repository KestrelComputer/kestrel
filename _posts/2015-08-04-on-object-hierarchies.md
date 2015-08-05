---
layout: post
title:  "On Object Hierarchies"
date:   2015-08-04 20:41:00
---
In my [previous blog article]({{site.baseurl}}/2015/08/04/bringing-back-gcom/),
I observed the need for
modularity with reduced or no coupling
when implementing the Kestrel's user interface software.
I used the example of
selecting a theme
to illustrate how tight coupling between
the UI core and the theme logic
would require the user to 
recompile the UI library at best,
or replace the OS ROM at worst.
In this article,
I talk about another lesson I learned
while writing the [GUI spike](https://github.com/sam-falvo/toybox).

## GEM's influence

I really like
how GEM uses an object tree
to express how a user interface is structured.
I tried using this model
when writing the GUI spike.
In summary,
I have an array of `Object` structures.
GEM implements a tree by including array indices for the successor,
as well as for the children.
(See figure below.)

    +-------+    +-------+           +-------+    +-------+     +-------+
    |  next |--->|  next |--...  +-->|  next |--->|  next |--*->|  next |
    +-------+    +-------+       |   +-------+    +-------+  |  +-------+
    | first |--- | first | ------+   | first |    | first |  |  | first |
    +-------+    +-------+           +-------+    +-------+  |  +-------+
    |  last |--- |  last | --------- |  last | -- |  last | -+  |  last |
    +-------+    +-------+           +-------+    +-------+     +-------+
    |  ...  |    |  ...  |           |  ...  |    |  ...  |     |  ...  |


I don't have an immediate need for tree-like breakdown,
so I just implemented a singly-linked list of elements.
As with GEM, I used an array index to refer to other elements.
You can see the result in `calc.c` and in `objects.c`.
There's little question that it saves a fair amount of code
compared to contemporary GUIs.

I ran into some problems with the technique, however.

## Problems

It's nearly impossible to write any sort of automatic layout function over an object list like this.
I suddenly had the need to implement the full tree-like semantics that GEM objects provided.
Otherwise, I couldn't arrange "vboxes" and "hboxes"
(vertical and horizontal layout containers, inside of which you place other controls to be placed).
Easy enough when you have the full source code
and it takes milliseconds to recompile the GUI code.
However,
this made me realize, once this kind of code appears in ROM,
you cannot add new fields to a data structure willy-nilly anymore.
Not, that is, without recompiling the RAM-resident applications using the GUI API.
In other words, even though `objects.c` code is fully isolated from any other module,
it actually remains *tightly coupled* with its clients.
That's because it *shares state*.
This state has become as much a part
of the signature of the Objects module's API as the actual function calls it exposes.

Thankfully, several ways exist to deal with this problem.
Which one is best
remains a topic for future consideration.

## Solution 1: Use templates

AmigaOS successfully uses this technique,
where an application uses so-called "New" structures to
instantiate more complex, more stateful structures.
For example, you pass a `NewWindow` structure to the `intuition.library/OpenWindow` function,
which returns (if successful) a `Window` structure.
Most of the fields are simply copied over,
but the `Window` structure contains more state.
In later generations of AmigaOS,
even on-screen controls were somewhat isolated from the programmer through the `NewGadget` structure.
Today, even that has fallen into disuse,
as programmers opt instead to use
BOOPSI objects.
In each case, backward compatibility remains intact,
since old APIs preserve their old semantics.

The take away here is
if we must use an externalized data structure,
we "deserialize" it behind a layer of abstraction.
This allows the back-end representation to change
with each revision of the operating system,
without affecting client software.
Clients unaware of new functionality will use older APIs,
which will now be written to fill default values into new private fields.
Clients aware of new functionality will use the newer APIs,
which may grant the client access to enhanced functionality.
Such as, for instance, automatic layout facilities.

## Solution 2: Separate your control from your view

What am I *really* using these `Object` structures for?
I have two top-level `object.c` API entry points:
`obj_draw` will render a set of objects to the screen, while
`obj_find` will locate an object corresponding to a mouse pointer's position on the screen.
In other words,
the object hierarchy
supports both visualization and control.

If we split these functions apart,
we find that most of the need for an object hierarchy disappears all-together.
For visualization,
we can achieve comparable
LOC economy by replacing each object instance declaration
with a simple call into the `objects.c` library.

Since new visualization functions can be added at any time,
extending the API to support
new kinds of controls
or new themes
is pretty easy.
However, despite all the visual changes that might occur,
the needs for control changes only little.
You still have a rectangular spot on the screen which remains sensitive to mouse input.
The dimensions may change over time, but the presence of said "hot spot" remains.
This is a clue:
maybe, we should rededicate the object list purely
to the task of associating input events with specific on-screen controls.
This is the approach that the
[Commodore 64 operating system GEOS](http://lyonlabs.org/commodore/onrequest/geos.html#tools)
takes (vis. `DoIcons` function).

## Lesson

I'll need to spend more time researching this topic further,
because
each method has its pros and cons.
If I go with the object tree approach,
I can implement layout engines that work over the otherwise statically declared structures,
while still supporting new features "behind the scenes."
The cost will be some additional boilerplate
if the application wants to alter any properties of any given object,
since now the back-end data structure and the client's version have to be synchronized.
However, if I adopt GEOS' method of dedicating object lists for input mapping purposes,
then widget toolkits will need to either include their own layout engines, or
they'll need to make arrangements
with third-party layout engines
to agree on a common data representation.
(At which point, you might as well have an object heirarchy anyway!)

One take-away from this exercise that I must point out though,
do not maintain linked lists using array indices.
As soon as you alter the object graph,
and *you will*,
you'll have to hand-edit *all* of the links yourself.
AmigaOS definitely got this right:
just have objects point directly to other objects.
That way, if you happen to need to insert a new object between existing objects,
you only need to alter two, three at most, object declarations.
If the motivation for using array indices
involves maintaining a consistent format
between what the GUI requires 
and what a resource editor tool requires,
then you should rely on something called [pointer swizzling.](https://en.wikipedia.org/wiki/Pointer_swizzling)

Currently,
I'm leaning towards the combination of GEM and AmigaOS techniques to get the benefit of having both.
I'd like to keep the dedicated object graph.
However, I'm going to evolve the design so that pointers are used instead of indices,
and so that the GUI spike maintains its own copy of the object graph.
This will require a slightly more complex API for the client,
but I think the pay-off will come when third-party expansions arrive for the API.
In particular, new kinds of layout engines can be added independently of
explicit GUI support.
The only thing it doesn't overtly support is new kinds of widgets;
however, this can be solved
by using callbacks and a
dedicated "custom" object type.
At least, I think.

I'll need to experiment some more on this to learn what's really involved with each, though.
