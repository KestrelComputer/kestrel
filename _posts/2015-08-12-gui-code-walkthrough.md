---
layout: post
title:  "Some History and a GUI Code Walkthrough"
date:   2015-08-12 18:00:00
---

In the
[first article]({{site.baseurl}}/2015/08/04/bringing-back-gcom/)
on my cursory work in GUI implementation,
I talked about the need for low coupled, highly modular software architecture.
In the
[second article,]({{site.baseurl}}/2015/08/04/on-object-hierarchies/)
I talked about object tree considerations
and some of the visceral feelings concerning them.
I got some valuable feedback a Twitter follower,
asking for more context and examples.
I can see how, if one misses the link to the github repository,
you might think I'm just blabbing on about nothing.
And, even if you did catch the link,
you probably have a hard time pinning down which sections of code correspond to which epiphanies.

This article aims to remedy this problem by walking through the code I've written so far.
Don't worry; the code isn't that much:
the dummy application combined with the "video driver" totals around 18KB compiled on a 64-bit system.
However, in order to explain where my influences originate,
I must explain the concepts behind the influences themselves.
Otherwise, nothing will make any sense.
This historical context is what the bulk of this article consists of.
If you want to skip to the bottom of the article,
where I actually go through my code,
feel free to do so,
and just refer back to the previous sections as necessary.


## Concepts behind GEM

I'll start by
talking about
[the GEM Operating System.](https://en.wikipedia.org/wiki/Graphical_Environment_Manager)

GEM started life as a PC operating system,
running on top of the CP/M-86 and MS-DOS platforms.
Atari adopted it for their Atari ST and compatible families of computers.
It is now a [GPL'ed, open-source operating system.](http://www.deltasoft.com/)
If you're willing to run a DOS emulator of some kind,
you can play with GEM yourself.

### Horizontal architecture

To the greatest extent possible,
GEM makes little attempt to hide
its CP/M underpinnings.
It's designed to sit *beside*,
not *on top of*, CP/M.
Contrast this with Windows.
Even in its earliest days,
it offered replacement APIs
for file I/O, seemingly intending
to hide MS-DOS from application developers.

This applies fractally as well;
*within* GEM, individual components
remain *peers* with respect to each other.
Don't get me wrong;
layering still happens.
Indeed, it *has* to happen;
or else GEM couldn't automatically
manage the application's
menu bar, to cite just one example.

Below, I outline the relationship between
"an application"
and the rest of the GEM ecosystem.

    +-----------------------------------------------------------+
    |                         Application                       |
    +-----------------------------------------------------------+
         ^                  ^                       ^
         |                  |                       |
         V                  V                       V
    +---------+         +-------+       +-----------------------+ \
    |         |         |       |       |           .           |  |
    |         | <------>|       |<----->|         .             |  |
    | BDOS or |         |       |       |       .               |  |
    | MS-DOS  |         |  AES  |       |     .    GDOS         |  |  "VDI"
    |         |         |       |       |    .                  |  |
    |         |         |       |       |   .                   |  |
    |         |         |       |       |   .                   |  |
    +---------+         +-------+       +-----------------------+  |
         ^                                  ^               ^      |
         |                                  |               |      |
         V                                  v               v      |
    +---------+                         +-------+-------+-------+  |
    |  BIOS   |                         |  GDD  |  ...  |  GDD  |  |
    +---------+                         +-------+-------+-------+ /
         ^                                  |               |
         |                                  |               |
         V                                  V               V
    +---------+                         +-------+       +---------+
    | Floppy  |                         |  VGA  |  ...  | PRINTER |
    +---------+                         +-------+       +---------+

The neat thing about GDOS and VDI modules
is that they share the same API.
Technically, you don't need GDOS to 
have a functional GEM environment.
Atari ST's port of GEM, for example,
lacks a built-in GDOS component.
(An after-market product became available, however.)

Each component performs one task really well.
It's almost like
an independent discovery
of the Unix philosophy.

*BDOS* stands for Basic Disk Operating System.
For most PCs, MS-DOS provided this service.
AES uses DOS to load applications and manage memory,
as well as to load "resource files" (persisted object trees).

**AES** stands for Application Environment Service.
It's tasked with ensuring the user
experiences a consistent user interface.
It manages the menu bar across the top of the display,
manages things called "desk accessories",
and manages screen real-estate by supporting
up to eight
overlapping windows at once.
It relies on DOS for changing applications and
for loading object trees from resource files.
It also uses the VDI API
to actually perform on-screen drawing.

Historically,
AES has an awareness for only one application
at a time.
Thus, when you double-click on an icon on the desktop,
the DESKTOP.APP program will unload, and the
selected application will be loaded in its place.
Even though only one application is loaded at a time,
AES and desk accessories could be drawing to the screen at any time.
Thus, applications must assume *cooperative* ownership of the screen.
This becomes more important with contemporary versions of AES,
most of which support true, preemptive multitasking.

Note that AES maintains window borders, but 
will not touch the interior of a window.
It remains the application's responsibility
to update the contents of its window.
As with the AES,
the application will use VDI
to perform this task.
However, it does so with input from AES,
for only AES knows which portions of a window are visible
to the user.
It also knows the window's left and top edge coordinates.

**VDI** is the Virtual Display Interface.
It's role is to provide a consistent graphics API
for whatever graphical device it is compatible with.
Most VDI drivers, obviously, are for displays
and for printers.
Note that VDI is entirely ignorant of AES.
This is not accidental;
VDI evolved from an earlier CP/M product called GSX.

Without GDOS installed,
you can talk to one and only one VDI device.
Typically, this is the screen driver.
Therefore, when you're drawing something on the screen,
you're literally one function call removed from touching raw
video frame buffer memory.
In addition,
all coordinates are relative to the device's own raster coordinates.

What if the VDI doesn't offer the graphics operation you need?
For example, the current VDI API does not support hardware MPEG playback.
If your application has some hardware-dependent knowledge 
of the graphics output device,
or if you use an adjunct device driver architecture in parallel with the VDI,
and as long as you respect AES' knowledge of what portions of your window are visible,
it doesn't matter if you use VDI or not to effect visual output.
AES simply doesn't care.  BDOS simply doesn't care.
For that matter, VDI doesn't care either.

A VDI module could be a single monolithic binary,
such as is the case with Atari ST computers
where GEM sits in ROM,
or it could be architected into two basic halves, called
GDOS and GDD (or, in older literature, GIOS).

**GDOS** is the Graphics Device Operating System.
This module presents the VDI API to the rest of the system.
It may also implement some higher-level, 
device-independent, graphics primitives.
It differs from a monolithic VDI driver in that it's
aware of how to manage multiple fonts,
and can multiplex requests amonst different specific hardware drivers

GDOS also acts as a multiplexor amongst different GDD instances.
See the dotted line leading from the app to a GDD in the figure.
For example, through GDOS,
you can draw something to the screen
through one "workstation" instance,
and draw something else to a printer with another.
GDOS also introduces a new coordinate system,
the Normalized Device Coordinates (NDC).
This lets you map a (32767x32767) virtual display resolution onto
whatever native coordinate system the device actually supports.
In theory, this lets you produce WYSIWYG output on the screen and on paper with the same set of VDI calls.

**GDD** modules are graphics device drivers.
These are the programs that actually know hardware-level details
about your video or printer device.
They're loaded by GDOS from storage on an as-needed basis.
They actually implement an API that is VDI compatible,
which means that GDOS is more of a *filter* to any given GDD.
For instance, GDD modules *never* see normalized device coordinates.
GDOS translates coordinates back and forth without a GDD's knowledge.

Together, GDOS and all GDD components comprise "the VDI."

### Object Trees and Resources

Describing a user interface in GEM requires
the use of something called *object trees*.
An object tree consists of an array of
`OBJECT` structures,
each of which includes linkage information to
find other `OBJECT`s.
The first three words of an `OBJECT` structure
looks like this:

    #define OBJECT struct Object

    OBJECT {
        WORD    next;
        WORD    first, last;
        // ...
    }

The `next` field points to an object's sibling,
officially not overlapping in any way,
although ordered according to painter's algorithm in practice.

The `first` field points to the first *child* of the
`OBJECT`,
while the
`last` field
points to the last child in the sibling list.
`last` really is only useful for quickly appending objects
to the end of the sibling list.

So, for example, a dialog box
might be described with a top-level object that
renders a white box,
and with children covering
the content text,
an OK and CANCEL button,
and maybe a few other goodies.

Most contemporary GUIs also implement hierarchical decomposition
of user interfaces.
This should not be cutting edge technology for anyone.

A "resource file", then,
merely consists of an array of `OBJECT` structures
serialized to a file.
GEM provides functions that
lets an application materialize a complete `OBJECT` tree in memory
given just a filename.
As you might expect, making a sophisticated GEM application
requires you not only write your software in a language like C,
but you also use a resource editor to compose your user interface
and write out ".RC" files.

You don't *have* to use the resource editor.
Manually constructing object trees is doable.
(You can see this done in the source code to DESKTOP.APP.)
However, resources made casual user interface construction simpler.








## Concepts behind GEOS

I'll next talk about the Commodore 64 variant of GEOS,
for that's the version I have most experience with.
The concepts should equally apply, however,
to the Commodore 128 and Apple II variants as well.
These topics *do not* cover the PC/GEOS versions and their progeny.

### Overtly Event Driven

GEM provides a function, `event_multi`,
which applications can use to wait for one or more events.
This gives programs a nice "threaded" feel to them:
you write your program as if you were performing file-I/O,
except with event streams instead.
You have a main function, it's called, and you only return from it
when your application truly quits.

GEOS throws that away.
There simply wasn't enough memory
in the Commodore 64 for such luxury.
Instead, GEOS makes plain to the programmer
that one, and only one, event loop resides in the system.
The GEOS Kernal provides this event loop,
which means your "application" isn't just a single blob of code and data.
It's actually a *confederation* of smaller programs, all very dedicated in scope,
and all invoked through a system of *callbacks*.
Even program initialization after freshly loading its binary is handled as a callback.

To facilitate event handling,
a number of global variables used to contain subroutine addresses are manipulated
at various times by the application.
These include the following:

Vector          |Purpose
----------------|-------------------------------------------------------------------------
recoverVector   |Repaint a damaged region of the screen
otherPressVector|Handle mouse button event not otherwise handled by GEOS
mouseFaultVec   |Handle when a mouse pointer moves outside of a rectangle
keyVector       |Handle a keyboard event.
stringFaultVec  |Handle when printing a character would fall outside a bounding rectangle.

In addition to these lower-level callback vectors,
GEOS also supports many higher-level input event dispatching,
and periodic callbacks (what it calls "processes") for background processing.
For example, icons
(what we'd now call buttons or widgets)
each have their own callbacks,
as do individual menu items.
`otherPressVector` is only invoked when neither an icon nor menu corresponds to a click event.

Let's see how one would put all these things together to build, for example, a paint program.

You'd use a set of *icons*, each with their own handler callbacks,
to implement the toolbox along the edge of a screen.
When the user clicks on any toolbox item,
that icon will toggle, and your callback will be invoked.
(Your callback will be responsible for inverting the previously selected icon,
so that the user doesn't see two concurrently selected icons.)

You'd use the `otherPressVector` to detect mouse button events
over the painting surface.
While the mouse button was pressed,
the application directly polls the mouse driver coordinates,
allowing it to track the mouse while painting or selection is in progress.
Note that the Kernal's event loop doesn't run during this time.
(GEOS may provide a "mouse moved" vector, but I haven't seen it in any online docs yet.)
When you release the mouse button,
that's when control returns to the event loop.

If you had a selection on the screen, then
you'd install a "process"
scheduled to run every half-second
to update a "marching ants" effect.

You'd probably want to install a handler for `keyVector` as well,
to handle accelerators or general purpose text-entry functionality.

Finally, you'll likely have a set of menus installed,
each with their own callbacks of course,
to handle file and clipboard I/O so you can load and save your masterpiece.

So, as you can see, lots and lots of callbacks,
all working together, all orchestrated through global state.
Since the event loop logic is abstracted from the application programmer,
applications tend to be very small and surprisingly robust.
For computers with 48KB to 64KB of memory total,
small size and efficient program behavior are paramount priorities.


### Exclusive Screen Ownership

With GEM,
the AES manages menus,
and applications are encouraged to use windows to manage their workspaces.
No such guidelines exist with GEOS,
in part because of memory limitations,
and in part because of the rather low resolution displays
that Commodore and Apple computers had at the time.
GEOS applications own the screen completely.

It's true that the GEOS Kernal managed the menu bar;
however, the applications knew both the size of the menu bar,
and its complete content.
Therefore, you frequently saw applications
use the right-hand size of the screen,
normally used by a menu bar,
for such tasks as a clock, or a file name label.
The application, ultimately, is responsible for rendering the entire screen,
so this is a sensible way to use precious screen real-estate.

This means that GEOS applications are composed of a series of handler callbacks,
each implementing the same basic control flow pattern:

* Is this event intended for me?
* Deal with the event in some meaningful manner.
* Redraw appropriate portions of the screen to reflect any state changes.
* Return to main loop.

The screen is viewed as a global variable *of the application*,
not of GEOS itself.
GEOS simply provides a convenient library of functions
to help you draw a nice-looking display.
Therefore, applications often draw something to the screen and forget about it.

Something deep inside you probably feels this is familiar:
if you're a web-app developer,
you'll notice your route handlers are callbacks,
managed by your web-app framework.
You take a request, you massage some data,
construct some HTML response, and then return.
It's the *exact* same pattern.









## The Calculator

Since I wanted to evolve my own GUI,
I wanted to design it from the perspective of
what would be the simplest API for a "typical" GUI application.
The GUI application would need to present controls to the user,
and would need to (somehow) respond to them.
The display should look reasonably nice
despite not having a graphics artists' touch.

One of the simplest, yet not exactly trivial, applications
one could write for any GUI is a 4-function calculator.
So, that's what I set out to implement.
Well, at least the user interface for it.

### Rendering the calculator

As with GEOS,
the calculator application assumes
it owns the entire display.
I chose this path because it seemed simpler to get off the ground.
It also provides a faster return on investment;
because GEOS was basically a glorified video driver,
it guarantees that, when I desired windows,
I'd use a horizontal configuration of modules, as with GEM.

Unlike GEOS,
however,
I wanted to make my code as device independent as possible.
This means I could not directly expose certain attributes of the display.
It had to be abstracted.
I'm using SDL to render to the screen,
but this fact should never be made known to the calculator.

Therefore,
the first thing we do is gain access to that display:

    // calc.c
    int
    main(int argc, char *argv[]) {
        Workstation *wk;
        int erc, i;
        ...
        erc = workstation_open(&wk);
        if(erc) {
            printf("Problem during initialization: 0x%X\n", erc);
            return 1;
        }
        ...
        workstation_close(wk);
    }

Inside `workstation.c`,
the `workstation_open` routine
is responsible for
initializing the SDL library,
opening a window,
and acquiring whatever renderers are required.
This is fully abstracted from the calculator;
in theory, I should be able to retarget the workstation
to a raw framebuffer tomorrow if I wanted.
Looking in `workstation.h`, a `typedef` exists for `Workstation`,
however the corresponding structure definition does not,
so we're free to redefine what a `Workstation` actually is in memory
with impunity.

Once we have the workstation reference,
we can now begin drawing our user interface.
We start by initializing the screen as a whole.
I rather like the color scheme 
used by GEM under Atari TOS, so
I elected to use a green background.

    ...
    /* Paint the backdrop */
    workstation_set_fg_pen(wk, 0, 128, 0);
    workstation_rectangle(wk, 0, 0, workstation_width(wk), workstation_height(wk));
    ...

Having a known background, we now draw the calculator to the screen.

    obj_draw(wk, objs, 0);

This tells the objects library to draw `objs`, a vector of `Object` structures,
starting at index 0 (the first in the array).
Each object describes a region of interest on the screen:

    static Object objs[] = {
        {1, 50, 25, 0, 0, OT_WINFRAME, 0},
        {2, 16, 0, 0, 12, OT_TITLE, "Calc"},
        {3, 0, 0, 16, 12, OT_BITMAP, (char *)&close_icon},
        {4, 0, 0, 102, 12, OT_LABEL, "0"},
        {5, 0, 14, 24, 12, OT_BUTTON, "9"},
        {6, 26, 14, 24, 12, OT_BUTTON, "8"},
        {7, 52, 14, 24, 12, OT_BUTTON, "7"},
        {8, 78, 14, 24, 12, OT_BUTTON, "/"},
        {9, 0, 28, 24, 12, OT_BUTTON, "6"},
        {10, 26, 28, 24, 12, OT_BUTTON, "5"},
        {11, 52, 28, 24, 12, OT_BUTTON, "4"},
        {12, 78, 28, 24, 12, OT_BUTTON, "*"},
        {13, 0, 42, 24, 12, OT_BUTTON, "3"},
        {14, 26, 42, 24, 12, OT_BUTTON, "2"},
        {15, 52, 42, 24, 12, OT_BUTTON, "1"},
        {16, 78, 42, 24, 12, OT_BUTTON, "-"},
        {17, 0, 56, 24, 12, OT_BUTTON, "."},
        {18, 26, 56, 24, 12, OT_BUTTON, "0"},
        {19, 52, 56, 24, 12, OT_BUTTON, "="},
        {20, 78, 56, 24, 12, OT_BUTTON, "+"},

        {20, 0, 0, 640, 12, OT_LABEL, "Calculator Version 1.0"},
    };

This array defines how to render the calculator's "window" on the screen.
GEOS doesn't have windowing capability at all,
so applications written for it must take it upon themselves
to provide a window-like visual display.

The `Object` structure, as I've defined it, does not implement a tree,
as they do under GEM.
Here, I took the GEOS-like approach of sticking with a flat list or array.
At the time I wrote the code,
I just didn't have a need for hierarchial relationships between objects.

The first number identifies the *next object to draw* in the array.
The next batch of numbers identifies the left and top edges of the corresponding object,
along with its width and height.
You'll probably notice the coordinates don't look quite right for a nice, rectangular layout.
That's because I fix them up at run-time (just above the call to `obj_draw`):

    objs[1].width = objs[0].width = objs[19].left + objs[19].width + 4;
    objs[0].height = objs[1].height + objs[19].top + objs[19].height + 3;

    for(i = 1; i < 20; i++) {
        objs[i].left = objs[i].left + objs[0].left + 2;
        objs[i].top = objs[i].top + objs[0].top + 13;
    }

    objs[1].left -= 2;
    objs[1].top -= 13;
    objs[1].width -= 16;
    objs[2].left -= 2;
    objs[2].top -= 13;

Basically, the `objs` array stores *relative* offsets for various controls,
but the code above adjusts them to their final location on the screen.
(By implication, all objects are relative to the origin of the *screen*.)
I did things this way for two reasons:
first, I wanted to toy around with approaches for automatic layout, and,
second, I wanted to be able to drag the window around the screen via the titlebar.
I never got either of these to work in the short time I spent hacking, obviously.
However, the vestiges of my efforts remain.

Those `OT_BUTTON` and such identify the *kind* of object which occupies that part of the screen.
This is useful for `obj_draw` to know how to render the object.
GEM's version of an `Object` structure also includes state flags to indicate
if the object is hot (mouse hovering over it), selected (user presses button over it), etc.,
all of which are intended to affect how the control is actually rendered.
GEOS employs a per-object callback, with flags indicating similar things.
For me, I just didn't get that far yet.

Finally, the last element in `Object` structures is a pointer to some type-specific data structure or buffer.
For example, buttons have textual labels, so most "parameters" will point to text strings.

As you can see, rendering a user interface in this GUI is quite simple:
lay out your objects and serialize them in an array of `Object` structures,
then invoke `obj_draw` to render the whole thing in a single call.
It's that simple.

### Event Handling

A user interface is useless if it cannot interface to a user, graphically or otherwise.
My spike, as with GEM and GEOS alike,
depends on event-driven techniques
to enable human interaction.

The first thing the calculator does to prepare for input is to set a number of *callback* functions.

    vec_button_down = on_button_down;
    vec_button_up = on_button_up;

When running under MacOS or Linux, we don't really care about the old callback vectors,
since when the application exits, the whole process dies and you return to the shell.
However, on a real Kestrel, you'd want to save them, so you can restore them later.

Once the callbacks are established, we "return" to the event loop.
Well, in the current implementation, I just call `event_loop()`.
In a real GUI implemented for the Kestrel, the initialization routine itself would be a callback,
just like in GEOS.

    event_loop();

Whenever you click the mouse button,
unlike GEOS,
the GUI makes **no** effort to route the event
to an appropriate handler.
This is something you must do on your own.
The reason is, not all applications
will want to have all their events routed
to the most microscopically precise location.

Consider the Amiga's mouse preferences editor window:

![]({{site.baseurl}}/images/amigaos204-2-1.png)

Just imagine the overhead if each of
the 256 zoomed-in pixels
had to respond to a callback.
Not only would the GUI spend a lot of effort locating the 
appropriate callback to invoke,
but on the receiving side,
one would hope that those callbacks
would point to the same routine,
and so you'd be committing memory to a task
that could be more easily solved with mathematics.
If the callback lacks sufficient parameterization
to tell one fat pixel apart from another,
then you really would need 256 *individual callbacks*
in addition to the 256 object structures,
so as to reinsert the missing information.
No matter which way you look at it,
you lose.

Instead, my GUI lets the application decide how 
it wants to handle
mouse events like button down or up.
A convenient helper function exists
to make the common-case
just about as easy as
fully automatic event distribution.
Using the coordinates of the mouse
when the button was pressed,
we traverse our `objs` list of objects,
and identify which one in the array the
mouse pointer is over.
Based on this information,
typically via a lookup table or a
`switch` statement,
we can then dispatch to an appropriate handler.

    void
    on_button_down(int mx, int my) {
        int i;

        i = obj_find(objs, 1, mx, my);
        printf("Clicked on object %d at (%d, %d)\n", i, mx, my);
    }

If no object is found,
`obj_find` will return `0xFFFF`,
since it's not (generally) possible to have a negative array index.

#### Handling mouse button releases

We handle button releases in almost exactly the same way.

    void
    on_button_up(int mx, int my) {
        int i;

        i = obj_find(objs, 1, mx, my);
        if(i == 2) {
            SDL_Event e;
            e.type = SDL_QUIT;
            SDL_PushEvent(&e);
        }
    }

The only difference is,
we check to see if the user clicked on the window's close button.
If we did, we tell SDL that we want to exit the program.
This will terminate the event loop,
and allow program finalization to happen.

## Summary of influences

|Design Influence|Source|
|----------------|------|
|Describe objects with structures|AmigaOS intuition.library, GEM, GEOS|
|Callbacks for event handling|GEOS|
|Workstations and retargetable graphics|GEM|
|Preference for libraries over frameworks|GEM|
|Full-screen ownership|GEOS|
|Windowing as an adjunct library|GEM|
|Automatic layout as an adjunct library|AmigaOS gadtools.library|

## Lessons Learned

My previous articles listed various lessons learned from writing this crude GUI.
I'll re-summarize them below for convenience.

### Build for modularity.

The GUI's implementation of `object.c`,
which controls how controls are rendered,
is statically linked against everything else in the GUI.
Even if we make the GUI itself a shared object library,
we can only have one, and only one, implementation of `object.c` per process.
For most things, it's not a problem.
However, particularly for theming support,
it's a liability.

Since we desire,
to the greatest extent possible,
a constellation of cooperating modules
rather than stacks of abstractions,
it seems natural to provide modularity
primitives that supports, if not encourages,
this architecture.

In my previous article,
I recommended the use of Component Object Model (COM),
since that's what it was invented for.
Quite literally, COM exists because Microsoft needed a way
to let independent modules work together
without the fore-knowledge of which implementations were in play.
However, the industry doesn't generally like COM.
So, I'm open to alternative suggestions,
provided they make sense.

Making the theme engine a COM component,
our application can instantiate and use it like it would any other
system-provided module.
The application would have statically compiled knowledge that it wants to
render a set of buttons,
but not a specific implementation of the library used to fulfill these requirements.
The runtime environment, then,
would provide the know-how for locating a compatible implementation and
instantiating it on behalf of the application.

We get modularity,
while the binary compatibility rules imposed by COM (or whatever)
would encourage cohesion.

### Minimize shared state.

The format of shared state
is indistinguishable from
an API function signature.
Once you commit to the layout of a record in memory,
it's there for life.

Yet, describing layout data using data structures
sure is damn convenient,
for it lets one use a procedural language like C
as though it were somehow more declarative.
This minimizes the need for dedicated tooling, like
dedicated resource editors or compilers.

A better solution would be the use of nested constructors.
For example:

    return obj_vector(
        obj_desc(50, 25, 0, 0, OT_WINFRAME, 0),
        obj_desc(16, 0, 0, 12, OT_TITLE, "Calc"),
        obj_desc(0, 0, 16, 12, OT_BITMAP, (char *)&close_icon),
        obj_desc(0, 0, 102, 12, OT_LABEL, "0"),
        obj_desc(0, 14, 24, 12, OT_BUTTON, "9"),
        obj_desc(26, 14, 24, 12, OT_BUTTON, "8"),
        obj_desc(52, 14, 24, 12, OT_BUTTON, "7"),
        obj_desc(78, 14, 24, 12, OT_BUTTON, "/"),
        obj_desc(0, 28, 24, 12, OT_BUTTON, "6"),
        obj_desc(26, 28, 24, 12, OT_BUTTON, "5"),
        obj_desc(52, 28, 24, 12, OT_BUTTON, "4"),
        obj_desc(78, 28, 24, 12, OT_BUTTON, "*"),
        obj_desc(0, 42, 24, 12, OT_BUTTON, "3"),
        obj_desc(26, 42, 24, 12, OT_BUTTON, "2"),
        obj_desc(52, 42, 24, 12, OT_BUTTON, "1"),
        obj_desc(78, 42, 24, 12, OT_BUTTON, "-"),
        obj_desc(0, 56, 24, 12, OT_BUTTON, "."),
        obj_desc(26, 56, 24, 12, OT_BUTTON, "0"),
        obj_desc(52, 56, 24, 12, OT_BUTTON, "="),
        obj_desc(78, 56, 24, 12, OT_BUTTON, "+"),
        obj_desc(0, 0, 640, 12, OT_LABEL, "Calculator Version 1.0"),
        NULL
    )

Several disadvantages exist with this approach:

* It's slow.  The GUI layout is constructed at run-time rather than compile-time.
It's actually an O(n^2) problem, because compiler must generate code that creates
and tears down activation frames *n* times,
each of which consists of retrieving *m* statically known attributes,
and ultimately landing inside a data structure behind a library's interface.
For sophisticated GUIs, this can actually become noticeable.
For the calculator, it's probably not much of a concern.

* You need to use accessors to inspect or alter properties of individual objects.

However, the benefits of this approach might outweigh the disadvantages.
Because construction is hidden behind active code (the `obj_desc` and `obj_vector` functions),
the signature of these functions can remain the same throughout time,
while the back-end representation of the data can be wildly different.

Another approach to this problem is to realize that
the activation frames of functions like `obj_desc` are laid out in memory
just like a structure at run-time.
However, this structure is never used or stored by the GUI;
rather, it's used to build internal data structures that the application never sees.
Therefore, as the signature of `obj_desc` would not change over time
without requiring application recompiles,
so it is possible to continue to use a data structure, built at compile-time,
to describe the GUI layout.
The trick, it turns out, is to interpret the data structures used as
*templates* for the constructed data structures behind the scenes.
Something like so:

        static Object objs[] = {
            {1, 50, 25, 0, 0, OT_WINFRAME, 0},
            {2, 16, 0, 0, 12, OT_TITLE, "Calc"},
            {3, 0, 0, 16, 12, OT_BITMAP, (char *)&close_icon},
            {4, 0, 0, 102, 12, OT_LABEL, "0"},
            {5, 0, 14, 24, 12, OT_BUTTON, "9"},
            {6, 26, 14, 24, 12, OT_BUTTON, "8"},
            {7, 52, 14, 24, 12, OT_BUTTON, "7"},
            {8, 78, 14, 24, 12, OT_BUTTON, "/"},
            {9, 0, 28, 24, 12, OT_BUTTON, "6"},
            {10, 26, 28, 24, 12, OT_BUTTON, "5"},
            {11, 52, 28, 24, 12, OT_BUTTON, "4"},
            {12, 78, 28, 24, 12, OT_BUTTON, "*"},
            {13, 0, 42, 24, 12, OT_BUTTON, "3"},
            {14, 26, 42, 24, 12, OT_BUTTON, "2"},
            {15, 52, 42, 24, 12, OT_BUTTON, "1"},
            {16, 78, 42, 24, 12, OT_BUTTON, "-"},
            {17, 0, 56, 24, 12, OT_BUTTON, "."},
            {18, 26, 56, 24, 12, OT_BUTTON, "0"},
            {19, 52, 56, 24, 12, OT_BUTTON, "="},
            {20, 78, 56, 24, 12, OT_BUTTON, "+"},

            {20, 0, 0, 640, 12, OT_LABEL, "Calculator Version 1.0"},
        };

        objects = obj_load(objs);
        if(objects) {
            // Use objects here.
            obj_unload(objects);
        } else {
            // Something dreadful happened.
        }

This should be more runtime efficient, since we aren't constantly
creating and destroying
C activation records.
It should also be more convenient for the programmer as well,
since it enables serialization of the UI to a resource file,
among other niceties.
However, it still retains the characteristic
that you must use accessors to inspect or affect state changes
on individual objects after they've been created in the GUI.

### Assume nothing.

The GUI lets the application render its own display.
It provides helper functions to ease this task,
but they *only* affect the display;
no internal state changes because I invoke `obj_draw_button()`.

When a button is clicked,
the GUI has no immediate awareness of which button was clicked.
Instead, it lets the application discover this for itself,
through whatever means makes sense for it.
A helper, `obj_find`, exists to automate the most common cases.
It adds at most three lines of code to your event handling logic.

This lets the application make use of proper windowing at a later time.
By simply linking against a windowing support library,
it's entirely possible to provide more conventional windowing behavior.

This lesson is a natural consequence of the flat, horizontal module dependency graph.

### Callbacks, so far at least, are a good thing.

In only a small handful of callbacks,
GEOS applications can provide a fully featured user interface.
The GEOS Kernal consumes a meager 16KB of memory.

I like the idea of simply updating global state to, well, change an operating mode.
It has the unique benefit that it *completely* abstracts the event delivery mechanism,
and that this abstraction has very little overhead (zero in a non-multitasking OS,
and a message exchange if multitasking is used).
Another benefit is that,
along with assuming nothing,
it allows one to
compose desired features
instead of relying on layers of abstractions
to provide everything you need.

The disadvantage, of course, manifests when you want to write a multithreaded application.
Shared global state is obviously a problem.
The most common solution to this problem
is to spawn background processing in threads,
and let the threads notify the foreground thread of completion via events.
Otherwise, one would need to store callback vectors as fields of the thread descriptor itself.

## Conclusion

Obviously, I need to play with these concepts more to learn more about their interactions.
However, thanks to this spike,
I have a relatively good idea of where I want to take the Kestrel's GUI moving forward.
Maybe within a year or two,
we can see the first pixels light up on real Kestrel hardware to really put this
to the test.
Until then,
thanks for reading my tomes of blog articles.  :)

