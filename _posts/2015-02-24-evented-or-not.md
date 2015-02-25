---
layout: post
title:  "STS V2: Evented or Not?"
date:   2015-02-24 15:00:00
---

## Abstract

A friend recently asked me if an example program for the Kestrel-3 will assume
an event-driven architecture.  Historically, I've been opposed to pervasive
"evented" software architectures on the basis that they're difficult to
maintain at production scales.  In this article, I attempt to outline one
possible event-driven architecture for the Kestrel-3 version of the STS
operating system.  This exploration will hopefully help me better understand
evented architectures, while simultaneously explaining how evented systems
complect solutions to problems.


## Introduction

I was [conversing with Aliaksei
Chapyzhenka](https://plus.google.com/u/0/+AliakseiChapyzhenka/posts/UfmmPnynTdu)
concerning a common, historically significant program for us both.  I got the
idea of maybe using this simple program as a more realistic example to
illustrate how to write Kestrel-3 software, and Aliaksei asked me if I would
make it in an <q>async</q> style.  Several ways of writing async software
exist: multi-threaded, event-driven (a.k.a., "evented"), and reactive come to
mind in contemporary software.  However, since I don't even have a complete
BIOS yet, let alone a full operating system, I responded in the negative.

Nonetheless, this got me thinking &mdash; since the first OS for the Kestrel-3
will be STS (a single-tasking operating system I first wrote for the
Kestrel-2), and it's inevitable that someone would want to write concurrent
programs for it, just what *would* an event-driven reactor library for STS look
like?  Would it simplify or complect the process of writing software for it?
Also, what would the software for it look like to the casual reader?

In other words, is it *worth* persuing?


## Events: The Simplest Possible Concurrency Method

Let's assume a microprocessor which presently has nothing to do.  You could
represent this condition with a busy-wait loop (e.g., `for(;;);` in C), or more
preferably with a halt instruction, which suspends execution until it receives
an interrupt.

    halt();

If we could write the entirety of every application as interrupt handlers, this
literally would be the entirety of an event-driven operating system's kernel.
No joke.

Unfortunately, it's not generally possible to do this.  For example, consider
the case of reading a line of text from the keyboard into a buffer.  What
happens when the user presses the ENTER key?  Some program has to respond to
this event.  Exactly *which* program responds will change as time goes on.  A
spreadsheet will interpret ENTER very differently than, say, a web browser.
Even within a single program, you could be waiting to receive two or more
pieces of information, each handled uniquely.  Therefore, at some point,
software must somehow express, "In the event of a line of text being entered,
I'd like to run this code."

In fact, let's look at a simple, sequential, so-called "synchronous" program:

    extern void input(char *);   // Somehow gets a line of text.
    
    void main(void) {
        char name[80];
    
        printf("Hello world.  What is your name?  ");
        input(name);    // This blocks until you press ENTER.
        printf("Well, %s, nice to meet you!\n", name);
    }

I list the equivalent code in a hypothetical version of STS that supports
asynchronous software through events:

    // This routine would be executed in response to the event that
    // the user wanted to run this program.
    void start_up(Event *e) {
        InputControlBlock *icb;

        printf("Hello world.  What is your name?  ");
        icb = malloc(sizeof(InputControlBlock));
        icb->buffer = malloc(80);   // Name buffer
        icb->length = 0;
        icb->capacity = 80;
        icb->callback = print_name; // when we have a name to print.
        schedule(input, icb);
    }

    // This gets executed by the input handler when the user presses ENTER.
    // It knows to call here because we specify this routine by name in the
    // InputControlBlock structure above.
    void print_name(Event *e) {
        InputControlBlock *icb = e->data;
        char *name = icb->buffer;

        printf("Well, %s, nice to meet you!\n", name);
        free(name);
        free(icb);
    }

Some new things to notice in this approach:

1.  STS would now consider the user naming a command to execute on the shell
*an event unto itself.*  This means that the STS shell could load the module,
locate the `start_up` event handler, and dispatch the event accordingly.  (It
would do this asynchronously, of course.)  Imagine if every Unix command you
enter into Bash implicitly had a `&` appended to it; it's a real possibility
with this architecture, while consuming virtually no additional resources.

2.  All event handlers receive a parameter, a pointer to an `Event` structure.
Through this structure, parameters to handler-specific state may be obtained.

3.  The `schedule` system call would create an `Event` structure, and put it at
the end of a work queue.

4.  Dispatching the event dequeues the `Event` structure.  After its handler
runs, and assuming the event isn't rescheduled, no further reference to the
event can possibly exist.  Thus, the event loop itself manages the memory for
an `Event` structure.

5.  The `input` handler needs to know how to handle when the user presses
ENTER.  Thus, we configure it with a callback to schedule.  This implies that
handlers can schedule other handlers as appropriate.

To make this whole thing work, we need to augment our simple kernel above with
a real event loop:

    typedef struct Event *Event;
    struct Event {
        // ...
        void (*callback)(Event *);
        void *data;
        int scheduled;
    };

    static Queue work_queue;

    void event_loop() {
        Event *e;

        // Since STS would be built as an async OS, the event loop by
        // definition runs forever.
        for(;;) {
            // If we have nothing else to do, let interrupt handlers run the
            // show.
            while(queue_empty(work_queue) && !*quitFlag) {
                halt();
            }

            // Otherwise, let's try to retire our work as quickly as possible.
            // Interrupt handlers will still function normally as we work.
            while(!queue_empty(work_queue) && !*quitFlag) {
                e = queue_pop(work_queue);
                e->scheduled = 0;
                e->callback(e);
                if(!e->scheduled) free(e);
            }
        }
    }

This simplistic event loop would probably solve a lot of async problems for
most programming tasks.  Indeed, let's now take a look at our `input` handler:

    void input(Event *e) {
        InputControlBlock *icb = e->data;
        BYTE v;

        // If we've reached our buffer capacity, we "return" the buffer to
        // its handler.  Note that we do not reschedule input, thus breaking
        // the 'loop'.
        if(icb->length >= icb->capacity) {
            schedule(icb->callback, icb);
            return;
        }

        // We assume we can synchronously read the input port quickly enough.
        v = read_port();

        // No byte available; reschedule ourselves.  This also prevents the
        // kernel from disposing of our Event structure, since it'll be reused.
        if(!v) {
            reschedule(e);
            return;
        }

        // If the user pressed the ENTER key, we're just as done as if we
        // filled the input buffer.
        if((v == 0x0D) || (v == 0x0A)) {
            schedule(icb->callback, icb);
            return;
        }

        // Support backspace.
        if(v == 0x08) {
            if(icb->length > 0) icb->length--;
            reschedule(e);
            return;
        }

        // At this point, we have a byte.  Stuff our buffer and return to
        // the event loop again.
        icb->buffer[icb->length] = v;
        icb->length++;
        reschedule(e);
    }

This code would allow the input loop to handle simple text entry, including the
ability to backspace over previously typed characters.  It does not support
cursor motion, but that's an implementation detail.  With a more sophisticated
InputControlBlock, you can support an entire gap-buffer implementation and all
the editing features it allows.

I note at this time that we can support multiple invokations of `input` at the
same time.  Input multiplexing would have to somehow be handled by `read_port`,
but it's entirely possible to have several outstanding `Event`s in the kernel's
event loop, each referencing `input`.  From the user's perspective, this is
indistinguishable from (cooperative) multitasking.

## Device Drivers

So how do we handle device drivers?

In a classical, threaded operating system, drivers typically (or, perhaps more
contemporarily, *used to*) expose two API entrypoints:

1.  `schedule` typically takes a request and breaks it down into smaller tasks.
The driver then schedules each of these smaller tasks amongst its current work
load.  For example, a floppy disk driver would take a read request and break it
down into a separate seek and one or more individual read-sector tasks.  To
minimize the amount of time the drive spends seeking a cylinder, it might
insert the seeks and sector reads in the *middle* of its current work-load,
particularly if it has outstanding requests for I/O at smaller and larger
cylinder numbers.  I refer you to the [Elevator
Algorithm](http://en.wikipedia.org/wiki/Elevator_algorithm). 

2.  `interrupt` typically examines the state of the driver, retires the current
I/O request, pops the driver's own work queue, and starts the next I/O
operation.

Notice anything familiar?  When an application's I/O call eventually lands at
`schedule`, that's just like invoking STS' own `schedule`, albeit with the
additional capability of inserting events willy-nilly as needed.  When the
driver's own interrupt handlers fire, that's just like our event loop waiting
for interrupts when it otherwise has nothing to do.  The classic architecture
for a driver matches almost exactly the centralized event queue discussed
above!

But, what about drivers that lack interrupt support, such as the KIA (Keyboard
Interface Adapter) in the Kestrel-2?  You'll need to *poll* these devices.
Bootstrapping the driver requires initially scheduling the poller manually,
where it'll take care of itself thereafter.

    void kia_loop(Event *e) {
        // check to see if the KIA reports a PS/2 keycode here, and respond
        // accordingly.

        // Reschedule so that we keep polling.
        reschedule(e);
    }

In this way, device drivers are, like processes in a microkernel, absolutely no
different than ordinary programs.  The OS needs to have some means of letting
programs rendezvous and communicate requests and such, but that's beyond the
scope of this article.

## Termination

Consider the Kestrel-2's KIA device.  Without explicit support in the loop,
though, there'd be no way to cancel the loop; thus, no way to unload the device
driver once it's no longer used.  Since drivers are normal programs, that also
means that applications you kick off via the shell *also* never get unloaded.
This results in a memory leak.

Let me better illustrate this effect by showing the definition of `print_name`
from our introductory example above:

    // This gets executed by the input handler when the user presses ENTER.
    // It knows to call here because we specify this routine by name in the
    // schedule() call above.
    void print_name(Event *e) {
        InputControlBlock *icb = e->data;
        char *name = icb->buffer;

        printf("Well, %s, nice to meet you!\n", name);
        free(name);
        free(icb);
    }

Once the application completes, it just returns to the event loop.  However,
the module remains loaded, ready for handling additional events in the future.
One need only find a way to `schedule` either its `start_up` routine or its
`print_name` function.  This works great for event handler libraries; it's what
we want.  But if we want to retain Unix shell-like semantics for user
convenience, we need a way of unloading programs that no longer "run." This
requires we add some kind of expunge event to all applications, libraries,
device drivers, etc.  And in order for *that* to work, it also means we need
the ability to remove unprocessed events from the event loop based on their
association with a particular program.

Thus, we can change our `Event` structure to keep track of which program it
belongs to (we assume `schedule` enforces the association):

    struct Event {
        // ...
        void (*callback)(Event *);
        void *data;
        int scheduled;
        Program *program;
    };

We'd now need to maintain a "current program" reference somewhere in the OS, so
that when we call `schedule`, it can reference the current program for the new
`Event` structure.  We can also use it to properly tell the OS that, yes, our
program has successfully finished.

    void print_name(Event *e) {
        InputControlBlock *icb = e->data;
        char *name = icb->buffer;

        printf("Well, %s, nice to meet you!\n", name);
        free(name);
        free(icb);

        unload(e->program);
    }

Of course, for the purposes of launching a *new* program, we'd also need a
system call like `schedule`, but one which takes the desired `Program` pointer
as a parameter.  Indeed, `schedule` could be implemented in its terms:

    // Somewhere in the kernel...
    void schedule(void (*callback)(Event *), void *data) {
        schedule_as(callback, data, current_program);
    }

Of course, this requires that we adjust our event loop one more time:

    void event_loop() {
        Event *e;

        // Since STS would be built as an async OS, the event loop by
        // definition runs forever.
        for(;;) {
            // If we have nothing else to do, let interrupt handlers run the
            // show.
            while(queue_empty(work_queue) && !*quitFlag) {
                halt();
            }

            // Otherwise, let's try to retire our work as quickly as possible.
            // Interrupt handlers will still function normally as we work.
            while(!queue_empty(work_queue) && !*quitFlag) {
                e = queue_pop(work_queue);
                e->scheduled = 0;
                current_program = e->program;   // New
                e->callback(e);
                current_program = NULL;         // New
                if(!e->scheduled) free(e);
            }
        }
    }

## Asynchronous I/O

STS V1 implemented completely synchronous I/O because it didn't have enough
space for anything else.  STS V2 would require the same for bootstrapping
purposes, but once booted, new drivers could be loaded that implemented
asynchronous I/O.

Synchronous I/O consists, typically, of a blocking open call, followed by a
series of blocking reads and writes, followed by a blocking close call.  How
would these look in a fully asynchronous environment?

Let's just look at an open call for a moment.  The open call does several
things: it verifies correct syntax of the filename, it resolves a volume device
driver, it issues appropriate device driver requests to scan through a
directory, and if and only if all that succeeds, we return a stream control
block (SCB), or NULL if not successful.

So at the top-most level, we'd need to use the following program structure to
use existing STS V1 open semantics in V2:

    void file_opened(Event *e) {
        OpenControlBlock *ocb = e->data;
        SCB *scb = ocb->scb;

        if(scb) {
            // File opened successfully; do something with it.
        } else {
            // File not found.
        }

        // etc...
    }

    void do_file_operation(Event *e) {
        OpenControlBlock *ocb;

        // etc...

        schedule(async_open, ocb);
        ocb->callback = file_opened;

        // etc...
    }

I see that we can implement multi-valued "returns" explicitly as one nice
advantage of the async model.  That is, we can pass more detailed success or
failure criteria, without the need for a separate global `errno` value.
Unfortunately, we pay the price by manually managing what amounts to activation
records (e.g., `OpenControlBlock`).

## A Hypothetical Program

Here's a hypothetically complete program for some mythical version of STS V2
employing all async code.  As you can imagine, since this version of STS V2
doesn't exist (yet?), it's not tested code.  But, it should give you a feel of
what to expect if you write async code for STS.  Let me know what you think --
is async worth it, or would you be happy with a DOS-like, single-tasking
environment?

    #include <magical_sts_header_files_here.h>

    void read_header(Event *);
    void print_header(Event *);

    static ProgramControlBlock *pcb;

    // Our start-up code would drop us here first.  This replaces main() in
    // traditional C programs.
    void start_up(Event *e) {
        OpenControlBlock *ocb;

        pcb = (ProgramControlBlock *)e->data;

        if(pcb->argCount < 2) {
            printf("I need at least one argument, a file to print.\n");
            // Exit with return code 1.
            // pcb->exit would have to call unload() for us.
            pcb->rc = 1;
            schedule(pcb->exit, pcb);
            return;
        }

        ocb = malloc(sizeof(OpenControlBlock));
        ocb->filename = pcb->argv[1];
        ocb->callback = read_header;
        schedule(async_open, ocb);
    }

    // Once the file opens, control "returns" here.
    void read_header(Event *e) {
        OpenControlBlock *ocb = (OpenControlBlock *)e->data;
        SCB *scb = ocb->scb;

        if(scb) {
            rcb = malloc(sizeof(ReadControlBlock));
            rcb->buffer = malloc(101);
            rcb->capacity = 100;
            rcb->scb = scb;
            rcb->callback = print_header;
            schedule(async_read, rcb);
            schedule(async_close, scb);
        } else {
            printf("Failed to open file.\n");
            pcb->rc = 1;
            schedule(pcb->exit, pcb);
        }
        // We don't need the OCB anymore.
        free(ocb);
    }

    // Once the read succeeds, we print the header of the file here.
    void print_header(Event *e) {
        ReadControlBlock *rcb = (ReadControlBlock *)e->data;
        rcb->buffer[100] = 0; // force null termination.
        printf("%s\n", rcb->buffer);
        if(rcb->length == rcb->capacity) printf("...etc...\n");

        // We don't need the RCB anymore.
        free(rcb);

        // Exit the program.
        schedule(pcb->exit, pcb);
    }

Notice that we schedule `async_close` immediately after `async_read`.  This
guarantees that the file referenced by the file's SCB always closes, regardless
of how successful the read actually was.  We're depending on the inherently
ordered nature of the STS event queue to ensure that the close happens after
the read attempt.  However, we *cannot* guarantee that the close will always
run before `print_header` (that's an implementation detail).

One problem I see with this example: I can't think of a reasonable alternative
to storing the `ProgramControlBlock` in anything except a global variable.  We
could use "program-local storage" (something like the evented equivalent of
thread-local storage, I suppose), but that seems inconvenient for illustration
purposes.

The frequency of memory allocations and frees concerns me as well.  Each
control block includes a reference to the next handler(s) to execute;
literally, we're constructing *continuations* in memory.  `malloc` and `free`
would need startling efficiency in order for async programs to run anywhere
near the speed of a synchronous application with normal stack allocation.  When
you look at environments like [Node.js](http://nodejs.org) or
[Twisted](https://twistedmatrix.com), you'll realize that the use of a
higher-level language like Javascript or Python automates this for you.  You
need to remember to do this yourself if you're coding in C, Forth, or similar
language.

## Conclusion

I've shown several examples of how adopting an event-driven runtime environment
would influence programming for the Kestrel.  On the one hand, it offers a lot
of support for asynchronous I/O and other concurrency features that one would
expect from any cooperative multitasking kernel.  However, it comes at a cost:
you have to manually create and destroy activation records, and you have to
manually thread them to create useful programs.  Perhaps with the right systems
programming language, much of this drudgery can be abstracted away.  Neither C
nor Forth will be able to cut it though.  Perhaps some Lisp variant?

Let me know what you think.  Should I support asynchronous I/O via an evented
architecture for STS V2.0?

## Acknowledgements

I'd like to thank Allie Prather, Glyph, and Aliaksei Chapyzhenka for helping to
review this article before publication.

