---
layout: post
title:  "Stepwise Refinement of an Event-Driven Forth Interpreter Part 2: Basic Correctness Checks"
date:   2015-05-20 19:30:00
---

Last time, I had arrived at a basic set of pseudo-code which, I *think*,
would describe a Forth interpreter for the Kestrel-3 computer.
You can find the complete description [here]({{site.baseurl}}/2015/05/17/stepwise-refinement-of-forth-interpreter/).

This time, I want to hopefully illustrate that the design is "correct",
by which I mean that the design is self-consistent and matches my understanding of how a Forth environment ought to work.

# Outer Interpreter

Below, I reproduce the pseudocode for `interpretLine`.
I've inserted `(n)` comments interstitially, so that I can clearly identify when and where something is (assumed to be) true.
You'll notice that I number the points *backwards*.
That's because, when using Floyd-Hoare logic, it's easier to work backwards using proof by contradiction and induction.

        PROCEDURE interpretLine.
                Start at beginning of line.
                Clear any error conditions.
		(4)
                WHILE no error AND line not yet exhausted DO
			(4.4)
                        Take next word from the input stream.
			(4.3)
                        Locate its definition in the dictionary.
			(4.2)
                        IF not found THEN
				(4.2.5)
                                tryWordAsNumber.
				(4.2.4)
                                IF not a number error THEN
                                        Set word not found error.
                                ELSE
                                        Push number on the data stack.
                                END.
				(4.2.3)
                        ELSE
				(4.2.2)
                                Execute word implementation.
				(4.2.1)
                        END
			(4.1)
                END
		(3)
                IF data stack out of bounds AND no error condition THEN
                        Set stack bounds error.
                END
		(2)
                IF error condition THEN
			(2.4)
                        Reset data stack.
			(2.3)
                        Report error condition.
			(2.2)
                        Clear error condition.
			(2.1)
                END
		(1)
                getAndRunCommandLine.

The first and most obvious point in the code above is at (1), where we assume that any previous line of text has been successfully interpreted.
At this point, we know that our pointer inside the supplied line of text must refer to the end of the buffer.
We also know that any errors that happened during the interpretation process have been reported to the human operator, and cleared appropriately.
And, since any pending errors have been dealt with, we also know the data stack is in good working condition.
Thus, our final state matches our interpreter loop invariant, which is that we have a clean slate when grabbing what's next to perform from the user.
Any other side effects incurred as a result of invoking Forth words fall outside the scope of this informal proof.

## Handling Errors

At point (3), and by extension at (2), some interpretation of the previous line of input has occurred, and so an error may or may not exist.
If it does, the antecedent will evaluate true, thus letting the consequent of the `IF` block run.
The last step of the consequent clears the error condition;
thus, by the time we reach (1), the error condition will definitely have been resolved.

To satisfy the post-condition at (1), we need:

* a variable which records the current error state, and,
* a procedure which yields true if an error is known to exist.


		VAR error: ERROR;

		TYPE ERROR = (NO_ERROR);

		PROCEDURE errorExists: BOOLEAN
			RETURN error # NO_ERROR;

Now, I'll attempt to (informally) prove the consequent of (2), again by working backwards.

At (2.1), to be compatible with (1), we know that the error condition has to be clear,
and the data stack needs to be in good, working order.
We've established those requirements as part of the outer interpreter's loop invariant,
and we see that the end of the consequent is compatible with those expectations.

At (2.2), we clear the error condition; regardless of what value it once had, it's definitely clear now.
At (2.3), we reset our data stack; regardless of what value it once had, it's definitely in a known good state now.
Finally, at (2.4), we *just* finished interpreting a line of text *and* we discovered a error happened.
We *don't* know the state of the data stack at this point,
hence all the steps to bring the interpreter back into a working state.

		PROCEDURE resetDataStack.
			Set data stack depth to zero.

		PROCEDURE reportError.
			Print error message to console, where message corresponds to the error detected.

		VAR errorMsgTable: MAP OF STRING
			NO_ERROR: "No error; should not be seeing this."
			...

		PROCEDURE clearError;
			error = NO_ERROR


At (3), we've just finished interpreting a line of text at this point.
We don't know the state of the data stack.
We *do* know the state of the return stack at least allowed control to return to the outer interpreter;
therefore, we heuristically trust the return stack to remain in good condition.

Other kinds of errors could potentially have caused early termination of interpretation.
A problem happens when we detect *both* stack over/underflow *and* any other kind of error happened prior.
Since the error condition can only record a single error, which error message do we show?
We reset the stack on any error report anyway, so I decided to deprioritize the stack bounds error.

		PROCEDURE dstackOutOfBounds: BOOLEAN.
			RETURN (data stack depth < 0) OR (data stack depth > limit)

## Scanning and Interpreting the Input Text

At (4), we have no errors, our data stack is in good condition, and we still have our source text to interpret.
This happens to meet our loop invariant at (4.4).
But, at (4.1), after we've invoked arbitrary software, we may not be so sure.
We could have invoked the very last word of the input stream.
Or, we could have encountered an error in resolving a word to a definition to execute.

In retrospect, I should move the data stack bounds check inside this `WHILE` loop.
Since I expect the cost of interpretation to be in the dictionary look-ups,
I cannot justify moving data stack bounds checking outside the loop on performance grounds.
Thus, I've discovered my first real design defect, which I'll correct below.

At (4.2), we actually make something happen.
Either we invoke the desired code, or we push a number onto the stack, or we generate an error if neither are possible.
This implies that at (4.2), we must not have any existing error condition to begin with.
Thankfully, our loop predicate guarantees that.

At (4.3), we have extracted a word from our input stream.
For this to happen, we must have input to work with in the first place,
which thankfully, our loop invariant guarantees as well.

		PROCEDURE takeNextword.
			Skip over whitespace, if any.
			Mark the start of the word.
			Skip over non-whitespace, if any.
			Mark the completion of the word.

		VAR startOfWord, lengthOfWord: BUFFER INDEX.
		VAR lineInputBuffer: BUFFER.

This implies that a "word", as a data type, is just a subrange of characters in the input buffer.
However, it's entirely conceivable that a "word", as returned by `takeNextWord`, can be of zero length;
imagine a buffer that contains nothing but whitespace.

Right now, the loop structure is:

                WHILE no error AND line not yet exhausted DO
			Take next word.
			...

however, this doesn't take a zero-length word into consideration.
And, honestly, can a zero-length word still be a "word"?
I'm inclined to think, no, it can't.
We generally call such things "whitespace."
Intuitively, we can change the code as follows:

		Take first word.
		WHILE no error AND word is not zero-length DO
			...
			Take next word.

While this can (and does!) work, I feel that it undermines what a "word", as a data type, means.
Ideally, I'd like to be able to have greater rigor in my code.

One approach to addressing this problem is to define our support procedures this way:

		PROCEDURE grabWord.
			Skip over whitespace, if any.
			Mark the start of the word.
			Skip over non-whitespace, if any.
			Mark the completion of the word.

		VAR startOfWord, lengthOfWord: BUFFER INDEX.
		VAR lineInputBuffer: BUFFER.

		PROCEDURE lineNotYetExhausted;
			IF lengthOfWord = 0 THEN RETURN FALSE; END.
			grabWord.
			RETURN lengthOfWord # 0.

		PROCEDURE takeNextWord.  
			currentStart = startOfWord; currentLength = lengthOfWord
			grabWord
			RETURN currentStart, currentLength

Yuck!  This requires we maintain flags and duplicates storage requirements.
The control flow logic between `takeNextWord` and `lineNotYetExhausted` is fairly intricate.
I think a simpler approach would be as follows:

		PROCEDURE lineNotYetExhausted: BOOLEAN.
			Skip whitespace, if any.
			RETURN if characters remain in the input buffer to be processed.

		PROCEDURE takeNextWord.
			Mark start of word.
			Skip non-whitespace characters.
			Mark end of word.

This actually simplifies the implementation of `takeNextWord` somewhat, and
I think delivers on the promise that a word can never be of zero-length for as long as our loop invariant holds.
The only "weird" aspect to `lineNotYetExhausted` is that it affects state;
it's not referentially transparent.

# Locating a Word in the Dictionary

First, what even *is* a dictionary?
For the purposes of Forth, it's an ordered list of definitions,
with the *most recent* definitions searched first.
We can model a dictionary as a singly linked list.

		TYPE WordHeader = POINTER TO WordDescriptor
		     WordDescriptor = RECORD
		         next : WordHeader
		         name : STRING
		         ...
		     END

This is a very simple model, but it's the simplest that can possibly work for our needs.

With that in mind, looking up a word means simply scanning through a list of `WordHeader`s.

		PROCEDURE findWord: MAYBE WordHeader.
			Start at most recently defined word.
			WHILE not at end of list DO
				IF word header's name matches word's name THEN
					RETURN word header.
				END
				Move to next word header.
			END
			RETURN not found.

		TYPE ERROR = (NO_ERROR, WORD_NOT_FOUND)

		VAR errorMsgTable: MAP OF STRING
			NO_ERROR:       "No error; should not be seeing this."
			WORD_NOT_FOUND: "Undefined word"
			...

I should point out that we don't want to set an interpreter error every time we can't find a word.
Thus, `RETURN not found` does not actually set an error condition; however,
it might mean we need a sentinel or separate flag to indicate failure to locate the word.

There are more sophisticated dictionary models in practice;
some Forth systems support multiple word-lists (sometimes called "vocabularies").
Others optimize word search using complex data structures like B-trees.
However, they all employ the same basic programmer's interface.
Given a string, look up the definition.

## Numbers, not Words

To help prevent excessive scrolling, I'll repost the relevant section of the outer interpreter here.

			(4.2)
			IF not found THEN
				(4.2.5)
				tryWordAsNumber.
				(4.2.4)
				IF not a number error THEN
					Set word not found error.
				ELSE
					Push number on the data stack.
				END.
				(4.2.3)
			ELSE
				(4.2.2)
				Execute word implementation.
				(4.2.1)
			END

What happens if the word we specify in the input buffer cannot be found?
Two possibilities exist in this case: either it's genuinely not defined, *or*, it's actually a number.
But, if the word's definition exists, we should execute that definition.
In either case, we have some post-conditions to verify.

The simplest possible case is when a word's definition exists, and we invoke it.
Upon return, we know the return stack exists in a consistent-enough state that it allowed control to come back to the interpreter.
So we assume that the return stack is "good enough."
If it's not, we rely on the trapping capability of the CPU itself to fix the problem later.
However, the word might have a imbalance on the data stack.
So, we don't actually know the condition of the data stack.
This meshes with (3)'s precondition expectations.

Supposing the word is actually a number, we will need to push that number on the data stack.
The act of doing this could overflow the data stack;
consider, if we have a data stack capable of holding 8 numbers, and we attempt to push a ninth number, where does that ninth number go?
Thus, at (4.2.3), we *also* don't know the state of the data stack.

(Now you know why I want to relocate the data stack check inside the inner interpreter loop, just in front of (3).)

At (4.2.4), we should see no observable changes in the interpreter state at all.
At this point, we attempted to convert the current word into a number, which could have failed.
Since this is with intent for interpretation, if the attempt failed, we do expect the error state to reflect the results of the conversion.
However, for the purposes of correctly reporting the error, we translate the "not a number" error that we expect into a more appropriate "not defined" error.

		TYPE ERROR = (NO_ERROR, WORD_NOT_FOUND, NOT_A_NUMBER)

		VAR errorMsgTable: MAP OF STRING
			NO_ERROR:       "No error; should not be seeing this."
			WORD_NOT_FOUND: "Undefined word"
			NOT_A_NUMBER:   "Malformed number"
			...

At (4.2.5), we simply don't know if the word is genuinely missing or if it's actually a number.

# Current Refinement

I'm satisfied that I've verified self-consistency, and in the process refined the design to a somewhat finer grain of detail.
Below, I list the latest stepwise refinement of the entire Forth interpreter as I currently understand it:

	MODULE DICT

		TYPE WordHeader = POINTER TO WordDescriptor
		     WordDescriptor = RECORD
			 next : WordHeader
			 name : STRING
			 ...
		     END

		PROCEDURE findWord: MAYBE WordHeader.
			Start at most recently defined word.
			WHILE not at end of list DO
				IF word header's name matches word's name THEN
					RETURN word header.
				END
				Move to next word header.
			END
			RETURN not found.

	MODULE ERR

		TYPE ERROR = (NO_ERROR, WORD_NOT_FOUND, NOT_A_NUMBER)

		VAR errorMsgTable: MAP OF STRING
			NO_ERROR:       "No error; should not be seeing this."
			WORD_NOT_FOUND: "Undefined word"
			NOT_A_NUMBER:   "Malformed number"
			...

		PROCEDURE reportError.
			Print error message to console, where message corresponds to the error detected.

		PROCEDURE clearError;
			error = NO_ERROR

	MODULE DSTK

		PROCEDURE resetDataStack.
			Set data stack depth to zero.

		PROCEDURE dstackOutOfBounds: BOOLEAN.
			RETURN (data stack depth < 0) OR (data stack depth > limit)

	MODULE SCAN

		PROCEDURE lineNotYetExhausted: BOOLEAN.
			Skip whitespace, if any.
			RETURN if characters remain in the input buffer to be processed.

		PROCEDURE takeNextWord.
			Mark start of word.
			Skip non-whitespace characters.
			Mark end of word.

	MODULE KRNL

		PROCEDURE coldBoot
			Reset return stack pointer.
			Initialize default callback vectors.
			Initialize event dispatcher.
			initializeForth.
			Start event loop.

	MODULE FORTH

		PROCEDURE initializeForth.
			Set base to 10.
			Announce Forth to the user.
			Reset data stack pointer.
			getAndRunCommandLine.

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
				IF data stack out of bounds AND no error condition THEN
					Set stack bounds error.
				END
			END
			IF error condition THEN
				Reset data stack.
				Report error condition.
				Clear error condition.
			END
			getAndRunCommandLine.

	MODULE NUMB

		VAR	base : INTEGER.
			accumulator : INTEGER.
			unconvertableCharacterPosition : INDEX.

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

There's still a lot of unrefined stuff here; however, except for the kernel, I think I have enough to go on and start writing tests for various modules.

# Module Dependencies

Stepwise refinement is very much a *top-down* method of designing software.
However, it's probably best to implement the software *bottom up.*
You can, of course, implement top-down as well, but doing so means you'll need to write mocks of your dependencies (per the usual TDD practices known today).
So, to help prioritize what I'll work on first, here is how I see the modules fitting together so far.
As usual, things can and almost certainly will change once implementation actually begins.

	OINT --+-- SCAN
	       |
	       +-- DICT
	       |
	       +-- NUMB --+-- WORD
	       |	  |
	       |	  +-- CHAR
	       |	  |
	       |	  +-- MATH
	       |	  |
	       |	  +-.
	       |            |-- ERR
	       +------------'
	       |
	       +-- DSTK
	       |
	       +-- CON ----- KRNL
	       |
	       +-- KRNL

You'll notice I've added a few more modules on the graph:

* **CON**.  This module handles console input and output.
* **MATH**.  The Polaris CPU does not support integer multiply or divide instructions.  I need to implement this functionality as subroutines.

I didn't account for these before because I knew I'd need to revisit the refinement later on.
But, since I'm satisfied (so far) with what I have, I wanted to record that I needed these modules before I forgot about them.

# Next Steps

I think my next task will be to work on the lower-level modules: ERR, CHAR, WORD, and MATH.
I'll defer working on KRNL, because I still definitely need to perform a stepwise refinement on that component.
However, ERR, CHAR, WORD, and MATH do not have any dependencies on the kernel, and the kernel has no dependency on them.
This makes them ideal candidates to develop my coding techniques (unit testing in pure assembly language).

Until next time!

