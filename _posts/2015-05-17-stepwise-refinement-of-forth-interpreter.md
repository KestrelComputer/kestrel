---
layout: post
title:  "Stepwise Refinement of an Event-Driven Forth Interpreter"
date:   2015-05-17 19:30:00
---

The Kestrel-3 development environment is now to a point where I'm quite satisfied with it.
Motivated by compatibility problems across different development environments,
I ported the assembler away from Forth to Python,
and in the process,
upgraded it to a proper 2-pass assembler to make writing assembly code that much easier.
The Polaris CPU emulator now supports enough of the [RISC-V Privileged ISA specifications](http://riscv.org/spec/riscv-privileged-spec-v1.7.pdf) that
I can reliably trap illegal instruction accesses, breakpoints, and system calls.
The CPU now boots from high memory (`$FFFFFFFFFFFFFF00`), and
supports a fully programmable `mvtec` configuration register,
allowing the exception vector table to appear on any 512-byte boundary in memory.
It defaults to `$FFFFFFFFFFFFFE00` though, and honestly, I have no reason to change it.

I once wrote that I wanted feature parity with the 6502 to be the first milestone for Polaris.
I think I've definitely reached that goal (in emulation, of course).
I even have a working, if only skeletal, [machine language monitor](https://leanpub.org/k3ug) for it.
Were I to burn this configuration into an FPGA development board,
I would produce a 64-bit computer with the overall usability of an Altair 8800, or maybe an Apple-I.

Despite the huge memory addressibility and the huge word width, I'm not happy with this configuration.
In order to achieve my dream of a computer that is a true successor to the likes of the Commodore 64,
I need the computer to be usable to a human operator with minimum mental burden,
as soon as he or she turns the unit on,
**without** attached storage.

Commodore, Apple, Atari, and many others decided to include a dialect of BASIC with their computers.
I, too, have considered using BASIC.
In fact, I may yet produce firmware which includes a BASIC interpreter as an option.
However, for years, I've been promising a computer that ships with *Forth* as its boot-up language.
I intended on delivering on that promise.

This article,
and perhaps follow-on articles,
attempts to catalog my attempts at using
[stepwise refinement](http://sunnyday.mit.edu/16.355/wirth-refinement.html)
to arrive at a working Forth environment.
As my Twitter and Google+ followers might know by now,
I've attempted to port several Forth environments to the Kestrel only to fail for one reason or another.
This time, I intend on taking a proven approach
(Niklaus Wirth used stepwise refinement to help implement his Oberon System,
both for the language Oberon and the eponymously named operating system).
The goal of this exercise is to discover gotchas and other sources of frustration as early as possible,
thus making their correct easy and inexpensive.
I hope it will provide a kind of *map* to guide development wth.

Without further ado, let's begin.

# Design of the Outer Interpreter

All interpreters share a basic structure, and Forth is no exception.
Forth implements the *read*, *eval*, and *loop* bits of a *read-eval-print-loop* (REPL).

        Announce Forth to the user.
        LOOP
                Print OK prompt.
                Wait for line of input from the console.
                Interpret line.
        END

Announcing that Forth is running is a trivial matter, and I won't refine it here.
It basically involves pumping characters to a debug port at present,
for which I already have working, [known-good code in the MLM](https://github.com/KestrelComputer/kestrel/blob/master/3/src/mlm/mlm.asm#L559-L610).
Similarly with printing the OK prompt.

I'll get to line input later.
For now, I'd like to focus on the actual meat of the matter: interpretation.
Who says that the user will write sensical code?
Due to its lack of type safety and checking (runtime or otherwise),
it's all too easy with Forth to corrupt arbitrary memory by accident
(including the data and return stacks).
Thus, if we get into a bad state,
the user should be able to press the reset button and have everything return to normal.


        PROCEDURE coldBoot.
        |       Reset data stack pointer.
        |       Reset return stack pointer.
        |       startForth.

        PROCEDURE startForth.
                Announce Forth to the user.
                LOOP
                        Print OK prompt.
                        Wait for line of input from the console.
                        Interpret line.
                END

If stack corruption happens, and we can detect it,
then we should take action to prevent further corruption of program state.
However, we don't want to do this all the time, during normal usage.
It's valid for a user to type something like `1 2`, `+`, and, `.` on separate lines
with the expectation that it'll behave just like `1 2 + .` on a single line.

        PROCEDURE coldBoot.
                Reset data stack pointer.
                Reset return stack pointer.
                startForth.

        PROCEDURE startForth.
                Announce Forth to the user.
                LOOP
        |               constrainDataStack.
                        Print OK prompt.
                        Wait for line of input from the console.
                        Interpret line.
                END

        PROCEDURE constrainDataStack.
        |       IF data stack pointer falls outside data stack bounds THEN
        |               Print data stack bounds error message.
        |               Reset data stack pointer.
        |       END

What if the return stack becomes corrupted?
Control will almost certainly never return to the interpreter, at least not directly.
We rather expect the computer to start executing illegal instructions at some point as a result.
Thus, we can use the CPU's trap mechanism to catch these issues and recover.

        PROCEDURE coldBoot.
        |       Announce Forth to the user.
                Reset data stack pointer.
                Reset return stack pointer.
        |       outerInterpreter.

        PROCEDURE outerInterpreter.
        |       IF trap occurred THEN
        |               Show cause of trap.
        |               Reset data stack pointer.
        |               Reset return stack pointer.
        |               Clear trap.
        |       END
                LOOP
                        constrainDataStack.
                        Print OK prompt.
                        Wait for line of input from the console.
                        Interpret line.
                END

        PROCEDURE constrainDataStack.
                IF data stack pointer falls outside data stack bounds THEN
                        Print data stack bounds error message.
                        Reset data stack pointer.
                END

        PROCEDURE machineModeTrapHandler.
        |       IF not interrupt THEN
        |               Record cause of trap.
        |               Return directly to outerInterpreter.
        |       END
        |       Return from exception.

Note that I don't just reset the data and return stacks in the exception handler.
I chose to do it inside the `outerInterpreter` procedure because
it seemed like a more correct place to put that functionality.
Exception handlers should always be as simple as possible.

Let's move on to interpreting a line of text entered by the user.

        PROCEDURE coldBoot.
                Announce Forth to the user.
                Reset data stack pointer.
                Reset return stack pointer.
                outerInterpreter.

        PROCEDURE outerInterpreter.
                IF trap occurred THEN
                        Show cause of trap.
                        Reset data stack pointer.
                        Reset return stack pointer.
                        Clear trap.
                END
                LOOP
                        constrainDataStack.
                        Print OK prompt.
                        Wait for line of input from the console.
                |       interpretLine.
                END

        PROCEDURE constrainDataStack.
                IF data stack pointer falls outside data stack bounds THEN
                        Print data stack bounds error message.
                        Reset data stack pointer.
                END

        PROCEDURE machineModeTrapHandler.
                IF not interrupt THEN
                        Record cause of trap.
                        Return directly to outerInterpreter.
                END
                Return from exception.

        PROCEDURE interpretLine.
        |       Start at beginning of line.
        |       Clear any error conditions.
        |       WHILE no error AND line not yet exhausted DO
        |               Take next word from the input stream.
        |               Locate its definition in the dictionary.
        |               IF not found THEN
        |                       Set word not found error.
        |               ELSE
        |                       Execute word implementation.
        |               END
        |       END
        |       IF error condition THEN
        |               Report error condition.
        |       END

As written, the interpreter doesn't support numbers.
We'd like to be able to input numbers as well.

        ...
        PROCEDURE interpretLine.
                Start at beginning of line.
                Clear any error conditions.
                WHILE no error AND line not yet exhausted DO
                        Take next word from the input stream.
                        Locate its definition in the dictionary.
                        IF not found THEN
        |                       Try interpreting word as a number.
        |                       IF not a number error THEN
        |                               Set word not found error.
        |                       ELSE
        |                               Push number on the data stack.
        |                       END.
                        ELSE
                                Execute word implementation.
                        END
                END
                IF error condition THEN
                        Report error condition.
                END

You might be wondering why I handle errors inside of `interpretLine` instead of
inside `outerInterpreter`.
Since these two procedures are so closely linked, it probably doesn't much matter where error handling goes.
However, `outerInterpreter` currently requires `interpretLine` to handle the complete interpretation of a line of text.
If the semantics of garbage input implies printing an error message,
then that's what it means to interpret garbage.

I think this completes the outer interpreter.
But, we're not done yet.
To create a functional environment, we need to know what it means to interpret a word as a number.

# Design of Numeric Parsing

The simplest way I know how to convert a word into a number is to step through the word character by character.
I don't think we can take any short-cuts on this one.

        ...
        PROCEDURE interpretLine.
                Start at beginning of line.
                Clear any error conditions.
                WHILE no error AND line not yet exhausted DO
                        Take next word from the input stream.
                        Locate its definition in the dictionary.
                        IF not found THEN
        |                       tryWordAsNumber.
                                IF not a number error THEN
                                        Set word not found error.
                                ELSE
                                        Push number on the data stack.
                                END.
                        ELSE
                                Execute word implementation.
                        END
                END
                IF error condition THEN
                        Report error condition.
                END

        PROCEDURE tryWordAsNumber.
        |       Start at beginning of word.
        |       Clear accumulator.
        |       WHILE no error AND word not exhausted DO
        |               Take next character from word.
        |               IF character is a letter THEN
        |                       Make sure it's uppercase.
        |               END
        |               Convert to binary.
        |               IF digit exceeds the set numerical base THEN
        |                       Set not-a-number error.
        |               ELSE
        |                       Accumulate digit.
        |               END
        |       END

For notational convenience to the user,
we'd like to be able to denote hexadecimal numbers independent of the current numeric base as well.

        ...
        PROCEDURE tryWordAsNumber.
        |       Preserve numeric base.
                Start at beginning of word.
        |       IF next character = "$" THEN
        |               Set base to 16.
        |               Advance to next character.
        |       END
                Clear accumulator.
                WHILE no error AND word not exhausted DO
                        Take next character from word.
                        IF character is a letter THEN
                                Make sure it's uppercase.
                        END
                        Convert to binary.
                        IF digit exceeds the set numerical base THEN
                                Set not-a-number error.
                        ELSE
                                Accumulate digit.
                        END
                END
        |       Restore base.

We need to support negative numbers as well.

        ...
        PROCEDURE tryWordAsNumber.
                Preserve numeric base.
                Start at beginning of word.
        |       Clear negation flag
        |       IF next character = "-" THEN
        |               Set negation flag.
        |               Advance to next character.
        |       END
                IF next character = "$" THEN
                        Set base to 16.
                        Advance to next character.
                END
                Clear accumulator.
                WHILE no error AND word not exhausted DO
                        Take next character from word.
                        IF character is a letter THEN
                                Make sure it's uppercase.
                        END
                        Convert to binary.
                        IF digit exceeds the set numerical base THEN
                                Set not-a-number error.
                        ELSE
                                Accumulate digit.
                        END
                END
                Restore base.
        |       IF negation flag set THEN
        |               Negate number.
        |       END

If you notice the previous two refinements, we are "wrapping" existing code to support new behavior.
This suggests that we can refactor the code to simplify things (particularly worthwhile for testing).

        ...
        PROCEDURE tryWordAsNumber.
                Preserve numeric base.
                Start at beginning of word.
                Clear negation flag.
                IF next character = "-" THEN
                        Set negation flag.
                        Advance to next character.
                END
        |       eitherHexOrDecimal.
        |       IF negation flag set THEN
        |               Negate number.
        |       END
                Restore numeric base.

        PROCEDURE eitherHexOrDecimal.
        |       IF next character = "$" THEN
        |               Set base to 16.
        |               Advance to next character.
        |       END
        |       tryUnsignedNumber.

        PROCEDURE tryUnsignedNumber.
        |       Clear accumulator.
        |       WHILE no error AND word not exhausted DO
        |               Take next character from word.
        |               IF character is a letter THEN
        |                       Make sure it's uppercase.
        |               END
        |               Convert to binary.
        |               IF digit exceeds the set numerical base THEN
        |                       Set not-a-number error.
        |               ELSE
        |                       Accumulate digit.
        |               END
        |       END

That we have a numeric base to keep track of implies some initialization work:

        PROCEDURE coldBoot.
        |       initializeForth.
                Announce Forth to the user.
                Reset data stack pointer.
                Reset return stack pointer.
                outerInterpreter.

        VAR     base : INTEGER.

        PROCEDURE initializeForth.
                Set base to 10.
        ...

The user may want to run programs which wants to convert text into numbers without the fear of
accidentally introducing an error condition for the interpreter.
Therefore, we should isolate conversion from error discovery.

        ...
        PROCEDURE eitherHexOrDecimal.
                IF next character = "$" THEN
                        Set base to 16.
                        Advance to next character.
                END
                tryUnsignedNumber.
        |       IF characters remain to be converted THEN
        |               Set not a number error.
        |       END

        PROCEDURE tryUnsignedNumber.
                Clear accumulator.
        |       Clear unconvertable character position.
        |       WHILE no unconverable character position AND word not exhausted DO
                        Take next character from word.
                        IF character is a letter THEN
                                Make sure it's uppercase.
                        END
                        Convert to binary representation.
                        IF digit exceeds the set numerical base THEN
        |                       Set unconvertable character position.
                        ELSE
                                Accumulate digit.
                        END
                END

# Event Driven Architecture

Up to now, the pseudocode written thus far assumes Forth will dominate control over the computer.
However, I'd prefer an event-driven architecture.
Event driven architectures seem significantly easier to get working due to reduced accounting requirements.
For example, if we used a (cooperative) threaded environment,
each thread would require a fixed allocation of memory for CPU registers (512 bytes for Polaris, at least),
a fixed allocation of space for Forth's so-called "user" variables,
plus unique data and return stacks.
It wouldn't surprise me if 4KB of memory would be required per thread.

With an event-driven architecture,
you need to take care to preserve what's important to you;
but, the space required scales linearly with your requirements.
Also, a single data and return stack can be re-used among a number of different event handlers.
Finally, the overhead of having to preserve and restore 1024 bytes worth of CPU state
(512 bytes to save state of the old thread, 512 bytes to restore the state of the new thread)
on every thread change is saved.
Add 2048 bytes additional performance overhead if using a floating point unit.

Finally, computers are *built* in an event-driven manner.
CPUs have interrupt request pins for a reason.
Extending this metaphor to system- and user-level software seems like a natural extension.

Threads become valuable when you have a lot of *compute-bound* jobs to complete.
If you're not *computing* something, then you're better off handling events.

To make Forth event-driven, we need to work with a central kernel of some kind.
This kernel will be responsible for letting Forth know when it's ready to be initialized,
and for scheduling jobs that Forth needs done.

        PROCEDURE coldBoot
        |       Reset return stack pointer.
        |       Initialize default callback vectors.
        |       Initialize event dispatcher.
        |       initializeForth.
        |       Start event loop.

        PROCEDURE initializeForth.
                Set base to 10.
        |       Announce Forth to the user.
        |       Reset data stack pointer.
        |       getAndRunCommandLine.

        PROCEDURE getAndRunCommandLine.
        |       Print OK prompt.
        |       Schedule wait for console input, then interpret line.

        PROCEDURE machineModeTrapHandler.
        |       IF not interrupt THEN
        |               Record trap information.
        |               Reset return stack.
        |               Reset data stack.
        |               Initialize event dispatcher.
        |               Schedule trapDiagnostic.
        |               Return directly to event loop.
        |       ELSE
        |               Pass interrupt up to kernel.
        |       END

        PROCEDURE trapDiagnostic.
        |       Reset callback vectors to defaults for outer interpreter.
        |       Show what caused the trap.
        |       getAndRunCommandLine.

        PROCEDURE interpretLine.
                Start at beginning of line.
                Clear any error conditions.
                WHILE no error AND line not yet exhausted DO
                        Take next word from the input stream.
                        Locate its definition in the dictionary.
                        IF not found THEN
                                tryWordAsNumber.
                                IF not a number error THEN
                                        Set word not found error.
                                ELSE
                                        Push number on the data stack.
                                END.
                        ELSE
                                Execute word implementation.
                        END
                END
        |       IF data stack out of bounds AND no error condition THEN
        |               Set stack bounds error.
        |       END
        |       IF error condition THEN
        |               Reset data stack.
        |               Report error condition.
        |               Clear error condition.
        |       END
        |       getAndRunCommandLine.

        ...

This change introduces some fragility in the face of some exceptions.
If a program makes a bad memory access or executes an illegal instruction,
then we reset the return and data stacks directly inside of Forth's exception handler.
We then re-initialize the event loop exactly as if we were rebooting the machine.
As a result, *any pending events will be lost.*
Thus, if you were using the event loop to run multiple jobs concurrently,
and any *one* job causes a CPU trap,
*all* of them would simply stop running.
Forth would be in a state not entirely unlike having just been rebooted.
This can potentially be a defect for some classes of software,
but I don't expect any problems for the code I personally want to write.

# Module Design

Here's the current stepwise refinement of the interpreter so far.
You'll notice a lot of stuff remains to be fleshed out, but that's OK.
I'm just focusing on the guts of the Forth interpreter for now.

        PROCEDURE coldBoot
                Reset return stack pointer.
                Initialize default callback vectors.
                Initialize event dispatcher.
                initializeForth.
                Start event loop.

        PROCEDURE initializeForth.
                Set base to 10.
                Announce Forth to the user.
                Reset data stack pointer.
                getAndRunCommandLine.

        PROCEDURE getAndRunCommandLine.
                Print OK prompt.
                Schedule wait for console input, then interpret line.

        PROCEDURE interpretLine.
                Start at beginning of line.
                Clear any error conditions.
                WHILE no error AND line not yet exhausted DO
                        Take next word from the input stream.
                        Locate its definition in the dictionary.
                        IF not found THEN
                                tryWordAsNumber.
                                IF not a number error THEN
                                        Set word not found error.
                                ELSE
                                        Push number on the data stack.
                                END.
                        ELSE
                                Execute word implementation.
                        END
                END
                IF data stack out of bounds AND no error condition THEN
                        Set stack bounds error.
                END
                IF error condition THEN
                        Reset data stack.
                        Report error condition.
                        Clear error condition.
                END
                getAndRunCommandLine.

        PROCEDURE tryWordAsNumber.
                Preserve numeric base.
                Start at beginning of word.
                Clear negation flag.
                IF next character = "-" THEN
                        Set negation flag.
                        Advance to next character.
                END
                eitherHexOrDecimal.
                IF negation flag set THEN
                        Negate number.
                END
                Restore numeric base.

        VAR     base : INTEGER.

        PROCEDURE eitherHexOrDecimal.
                IF next character = "$" THEN
                        Set base to 16.
                        Advance to next character.
                END
                tryUnsignedNumber.
                IF characters remain to be converted THEN
                        Set not a number error.
                END

        PROCEDURE tryUnsignedNumber.
                Clear accumulator.
                Clear unconvertable character position.
                WHILE no unconverable character position AND word not exhausted DO
                        Take next character from word.
                        IF character is a letter THEN
                                Make sure it's uppercase.
                        END
                        Convert to binary representation.
                        IF digit exceeds the set numerical base THEN
                                Set unconvertable character position.
                        ELSE
                                Accumulate digit.
                        END
                END

        PROCEDURE machineModeTrapHandler.
                IF not interrupt THEN
                        Record trap information.
                        Reset return stack.
                        Reset data stack.
                        Initialize event dispatcher.
                        Schedule trapDiagnostic.
                        Return directly to event loop.
                ELSE
                        Pass interrupt up to kernel.
                END

        PROCEDURE trapDiagnostic.
                Reset callback vectors to defaults for outer interpreter.
                Show what caused the trap.
                getAndRunCommandLine.

If I extract the unrefined operations and data accessors, and attempt to classify them by gross functionality,
I get a useful map of the set of modules comprising the interpreter.

        Module  Function Description
        ======  =========================================================
        CHAR    Check if character is a letter.
        CHAR    Convert to binary representation.
        CHAR    Enforce character is uppercase.

        DICT    Check if word not found.
        DICT    Locate a definition in the dictionary.

        DSTK    Check if data stack out of bounds AND no error condition.
        DSTK    Push number on the data stack.
        DSTK    Reset data stack.

        ERR     Check if a number error exists.
        ERR     Check if error condition exists.
        ERR     Clear any error conditions.
        ERR     Report error condition.
        ERR     Set not a number error.
        ERR     Set stack bounds error.
        ERR     Set word not found error.
        ERR     Show what caused the trap.

        KRNL    Check if not interrupt.
        KRNL    Initialize default callback vectors.
        KRNL    Initialize event dispatcher.
        KRNL    Pass interrupt up to kernel.
        KRNL    Record trap information.
        KRNL    Return directly to event loop.
        KRNL    Schedule procedure callback.
        KRNL    Start event loop.

        NUMB    Accumulate digit.
        NUMB    Check if digit exceeds the set numerical base.
        NUMB    Check if negation flag set.
        NUMB    Check if unconvertable character position exists.
        NUMB    Clear accumulator.
        NUMB    Clear negation flag.
        NUMB    Clear unconvertable character position.
        NUMB    eitherHexOrDecimal.
        NUMB    Negate number.
        NUMB    Preserve numeric base.
        NUMB    Restore numeric base.
        NUMB    Set base to 10.
        NUMB    Set base to 16.
        NUMB    Set negation flag.
        NUMB    Set unconvertable character position.
        NUMB    tryUnsignedNumber.
        NUMB    tryWordAsNumber.

        OINT    Announce Forth to the user.
        OINT    Execute word implementation.
        OINT    getAndRunCommandLine.
        OINT    initializeForth.
        OINT    interpretLine.
        OINT    Print OK prompt.

        RSTK    Reset return stack.

        SCAN    Check if line exhausted.
        SCAN    Start at beginning of line.
        SCAN    Take next word from the input stream.

        WORD    Advance to next character.
        WORD    Check if next character = "-".
        WORD    Check if next character = "$".
        WORD    Check if word exhausted.
        WORD    Start at beginning of word.
        WORD    Take next character from word.
        ======  =========================================================

(Whoever said writing a Forth interpreter was easy is clearly lying.)

From the above list,
I can identify nine modules that the outer interpreter requires before the it can function on its own.
The total known set of modules so far is as follows:

        CHAR    Character manipulation facility.
        DICT    Dictionary facility.
        DSTK    Data stack management facility.
        ERR     Error tracking and reporting facility.
        KRNL    Event-driven kernel.
        NUMB    Number conversion facility.
        OINT    Forth's Outer Interpreter.
        RSTK    Return stack facility.
        SCAN    Input scanning facility.
        WORD    Forth word manipulation facility.

Each of the routines identified above has pre-conditions and post-conditions that they must meet for the interpreter to function as written.
This blog article is getting long enough as it is,
so I'll skip specifying what these are.
Maybe in a later article, I'll attempt to prove correctness of selected portions of this design.
Of course, "correctness" means, in this case, that the design is self-consistent.
This doesn't necessarily mean that the design implements what I want to see in the interpreter yet.

# Conclusion

I've performed an informal stepwise refinement of a Forth interpreter to what I think is a viably implementable program.
It allowed me to identify, ahead of time, a number of modules.
These modules may *or may not* be necessary in actual practice;
the level of abstraction is still too high to know for sure.
I believe the refinement above is sufficient to let me discover invariants about the program,
check them against and/or develop the requirements of the unrefined steps,
and implement test suites to check my understanding of the code.
I'll try to keep you posted with my progress!
