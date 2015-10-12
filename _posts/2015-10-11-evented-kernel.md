---
layout: post
title:  "Event-Driven Kernel for Kestrel-3"
date:   2015-10-11 21:00:00
---

STS Version 1,
the operating system for the Kestrel-2,
provided a traditionally synchronous operating system API.
Combined with implicit hardware limitations,
this imposed I/O constraints
which had tangible effects
on the usability of the system.
After some convincing
from my more vocal
Kestrel followers,
I've decided to make Kestrel-3's operating system,
STS Version 2,
an event-driven operating system.
Between the event-driven architecture
and the Kestrel-3's support for interrupts,
I envision a substantially more user-friendly home computer.
This article attempts to lay out my implementation ideas.


## Historical Context

STS stands for *single-threaded system*.
I wrote a minimal version of STS V1 for the Kestrel-2
to solve the problem of swapping overlays to support programs larger than 16KB.
It was largely successful at addressing this problem for some programs.

MTS stands for *multi-threaded system*.
This operating system would have eventually replaced STS as the OS of choice.
I never got far enough with the Kestrel-2 to write MTS.

I originally intended STS to serve as a stop-gap until I built MTS.
I wanted the simplest possible OS that could possibly work
for my needs.
To that end,
I intended its feature set
to approximate an already-existing, well-known, OS called CP/M.

It exposed a completely synchronous API to applications that ran under it.
This, combined with the CPU's lack of interrupt support,
severely constrained its I/O capabilities.
For example, STS V1 could not detect,
let alone react to,
storage card insert or remove events.
Consequently, removing or inserting a card
would cause STS to deadlock on the next media access
unless you invoked a command to "remount" the storage card.
A command which I never got around to writing, by the way,
in part because I was already running out of memory with what I already had.

Moreover, the Kestrel-2's lack of timer hardware
meant that timeouts had to be calibrated by tweaking
fickle loop counters with a stopwatch in hand.
So, any time you changed the structure of the code,
you had to recalibrate the timeouts to make sure you weren't out of spec.

The original STS API would prove inadequate for another reason.
You might remember something about [Ken's Challenge](http://kestrelcomputer.github.io/kestrel/slides/patientio/index.html#/2),
from a talk I gave some time ago.
To recap,
a fellow Racker named Ken wants me to use the Kestrel-3 at work for a week.
This will necessarily combine keyboard, mouse, network, and storage events.
STS V1 only knew about storage;
it was completely ignorant of other classes of I/O devices.
So, handling asynchrony *in general* was right out of the question.

To support the Kestrel-3,
I'm going to need a new operating system design.
Unlike STS V1,
this version will be asynchronous from the ground up.
So, better get used to [stack ripping,](https://thesynchronousblog.wordpress.com/2008/08/28/the-problem-with-events/)
because you'll be doing a lot of it!

You might recall from previous Forth refinement articles
that I wanted an asynchronous structure to the ROM-resident Forth.
I mention STS V2 above,
as though the refinement below is solely destined for use there.
However, its *first* deployment will definitely be in the Forth implementation
as a proof-of-concept.
So, where you read STS (V2) below, you may safely also assume Forth too.

## The Event Loop

At the core of STS V2 lies the event loop.

The main event loop is responsible for multiplexing the CPU's time amongst the
different sources of interruption that demand its attention.  Each petition for
the CPU's time is called a *step*.

The event loop is structurally the simplest part of the kernel.

    Mainloop:
        forever
            while stepsRemain do
                callNextStep
            end
            
            while not stepsRemain do
                waitForInterrupt
            end
        end

We need a queue of steps to complete.  For now, and at risk of prematurely
selecting an implementation, I'll define a step queue as a circular queue of
steps.  The step queue has a head and tail index.  We know the queue is empty
when the head and tail are equal; or, put another way,

    stepsRemain:
        Answer true if queue head != queue tail; otherwise, false.

Invoking the step requires calling the step's handler function with a
continuation of some kind.  But, when we do this, we must first remove the step
from the queue.  This frees up a hole in case the callback wants to reschedule
itself, and the queue is otherwise full.

    callNextStep:
        getStepHandlerAndContinuation
        removeStepFromQueue
        callHandlerWithContinuation

Removing an element from the queue simply means we increment the head index,
modulo the size of the queue.  Strictly speaking, we needn't check for an empty
queue, but it's good programming practice to do so anyway.  The check is
effectively free, so why not?

    removeStepFromQueue:
        if stepsRemain then
            increment head of the queue.
        else
            panic
        end

## Scheduling Steps to Perform

The main loop is great at dispatching events to process;
but, as you can see, it
fails utterly to encompass the act of event generation.  Thus, we need some way
to add steps to the step queue.  For instance, when a timer expires, we need
to schedule the timer's callback.  When a network packet arrives, we need to
schedule the network stack to route the data to the appropriate program, etc.

At its core, a step is just a function that needs to be called.  It cannot be
called in isolation though; the need to rip the stack of an otherwise blocking
procedure requires we must pass along a pointer to some contextual information
as well, the "continuation", if you will.  All inter-step communication happens
through this context that gets passed from step to step.

Each step represents one quantum of one thread of control.  Therefore, we
know that if our queue can only hold 128 steps, then we logically are limiting
the number of *active* threads to 128 as well.  (We can have an infinite number
of threads waiting for something to do.)  I know from my AmigaOS and early Linux
experience that I won't likely use a system with more than 64 threads when just
sitting at the command-line (and most of those were waiting on resources).
Most of these threads were background processes (device driver helpers, etc.).
Therefore, choosing a fixed queue size of 128 elements should give me a fair
amount of lee-way in the kinds of programs I expect to run; applications will
add only a small number of threads on average.  It's not until you start
implementing servers that we need to consider the possibility of tens of
thousands or even millions of active callbacks.

Based on this reasoning, I think I'm just going to panic when I'm unable to add
a new Callback structure to the step queue.  This simplification eliminates
significant implementation complexity, especially for a first-generation
implementation.

    addStepToQueue:
        if not stepsFull then
            appendStepToQueue
            incrementTailOfQueue
        else
            panic
        end

    stepsFull:
        Answer true if queue tail + 1 == queue head; otherwise, false.

This also has the benefit that the same function is usable by both applications
and interrupt handlers alike, since no dynamic memory management is needed.

## Model of Use

Keyboard, storage, and network I/O will be the largest use-cases for the evented
kernel.  In particular, maintaining an interactive user interface while the
rest of the computer is off doing something else is a requirement to meet Ken's
Challenge.  Storage drivers will need reasonable time-outs, and busy-waiting is
simply not a viable alternative.  Network I/O has all the requirements of
storage *plus* asynchronous notification of freshly received traffic for
processing.  I'm building the kernel to the needs of these requirements
specifically.

### Keyboard

Two possible models exist, and I'm not yet sure which one I'll end up using.

In model 1, the keyboard driver exists as a self-scheduling agent that,
for all intents and purposes,
can be said to run in the background.
When this driver detects an ASCII character,
it uses the kernel to schedule a callback with the character received.

For this model to work,
any client interested in keyboard activity
must register a callback with the keyboard driver
as an initialization step.
This configuration would persist indefinitely until changed by another program.

In model 2, the client application would use the kernel
to schedule execution of the keyboard driver.
To do this,
the client would need to communicate a continuation to the keyboard driver.
This keyboard driver "thread" would self-schedule until a character is received,
at which point it would schedule the continuation and terminate itself.

Although model 2 more closely approximates a sequential, threaded design,
both models suffer from the need to explicitly track resources.
For example, if a program were to crash before receiving a character,
the operating system could clean up the errant task,
but the keyboard driver would have a dangling continuation.

For the Forth environment,
I think I'm going to use model 1.
However, when it comes time to port this to STS V2,
I'm obviously going to need something substantially more robust.
I just don't know what that will be.


### Block Storage

When no I/O is in progress,
the SD/MMC driver remains unscheduled.
The first time an I/O request arrives,
the driver will schedule a self-scheduling driver to handle the request.
For subsequent I/O requests,
control blocks are merely appended
to an I/O request queue that the handler dequeues.
The handler terminates only when the queue is completely empty.

Were it truly just this simple, it'd be a done deal.
However, SD/MMC access also requires that we observe timeouts.
This means not only is there an SD/MMC driver,
but there'll also need to exist a timer driver as well.

### Timed Events

A timed event is scheduled just as SD/MMC I/O requests are scheduled.
An I/O request block for a timer would include a callback and context,
but also the time at which to make the callback.

It's important that timeouts be cancellable.
For example, mounting an SD/MMC card might set a 2 second timeout
which would trigger if we don't hear anything back from the card in that time.
If we do, we obviously don't want that trigger to fire,
so we cancel that timeout.

For this reason,
programs will be able to cancel a pending I/O request.
As long as the timer hasn't scheduled the callback yet,
this is as simple as dequeueing the timer's I/O request block.
If it has already scheduled the callback, however,
we need to make a separate request to the kernel.
Once the timer has scheduled the callback and context,
it's out of the timer's hands.
For this reason, the kernel will also need a function to remove
all callbacks that match some given criteria.

    cancelStepFromQueue: s withContext: c
        for each element in the queue
            if step callback = s and context = c then
                overwrite entry's callback with no-op callback.
            end
        end

We have to do this for each element in the queue,
because (perhaps due to a buggy program)
we might have multiple callbacks scheduled.

Note that this implies a protocol to follow when cancelling a timed callback:
you must first cancel the I/O request block, and then,
you must call upon the kernel to make sure you remove any lingering artifacts of the callback.
Of course, if the scheduler has already issued the callback,
your code must be prepared for this.

### Filesystem Access

Filesystems in traditional, threaded environments
are made to appear as libraries.
In an event-driven world, however,
they need to appear in the same manner as devices.
Otherwise, you get some mighty scary API semantics.

For this reason, filesystem "drivers" will re-use the same infrastructure as
block I/O device drivers, albeit with different command sets.

### Network Packet Drivers

These will follow a similar structure to block I/O devices, for
sending a packet and writing a packet to an SD/MMC card isn't much different.
Where things truly differ, however,
is that a network adapter may asynchronously deliver traffic for consideration.
For this reason, it also combines some of the characteristics of, say,
a keyboard driver.
So, a protocol stack, which *can* be implemented as a library,
may register a callback to one or more compatible packet drivers.

To send frames,
an application would construct buffers containing the data to send,
then issue I/O control blocks to the packet driver's out-bound queue.
The packet driver would, after sending the frame,
schedule a callback so that more data can be sent (if any exists).

Receiving frames requires a source of true asynchrony; typically interrupts.
When a frame has been received,
the packet driver would need to
schedule a well-known callback to handle the frame.
This is much like model 1 of the keyboard driver interface above.
It would suffer many of the same problems as well;
if a program dies, the packet driver would somehow need to hear about this,
so that it can properly clean up any dangling callbacks.

### Video Drivers

You guessed it; these follow the same basic model as block I/O devices.
Video drivers are a particularly useful abstraction
if your hardware supports resources like blitters or shaders.

Video is typically an output-only device,
so no special considerations exist for input-related functionality.
However, if your hardware supports a blitter,
it could interrupt when a blit has come to completion.
The video driver can maintain a queue
of I/O request blocks requesting blitter services,
each kicked off at the end of each preceding blit.

## Conclusion

To be honest,
some of my more participatory Kestrel followers
have voiced overwhelming support for (sometimes pure) event-driven OSes
instead of multithreaded programming environments.
I was (and to a lesser extent than before, still am) skeptical
that it's the simplest solution.
However,
I've seen enough research on the matter
to be convinced that this is a worth-while experiment to conduct.
For example,
through a process called [callback coloring](http://people.csail.mit.edu/nickolai/papers/usenix2003-slides.pdf),
you can make an evented architecture
as performant as multithreaded systems
on multi-core architectures.

We'll see the results of this experiment soon enough,
for the next step in getting the ROM-resident Forth working is
its user interface.
