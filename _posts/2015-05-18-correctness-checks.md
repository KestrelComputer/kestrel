---
layout: post
title:  "Stepwise Refinement of an Event-Driven Forth Interpreter Part 2: Basic Correctness Checks"
date:   2015-05-18 19:30:00
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
                                tryWordAsNumber.
                                IF not a number error THEN
                                        Set word not found error.
                                ELSE
                                        Push number on the data stack.
                                END.
                        ELSE
                                Execute word implementation.
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
We also know that any errors that happened during the interpretation process have been reported to the human operator.
Any other side effects incurred as a result of invoking Forth words fall outside the scope of this informal proof.

At point (2), an error may or may not exist.
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
We've established those requirements above, and we see that the end of the consequent is compatible with those expectations.
At (2.2), we know we have reported the currently known error to the user,
so there's no further point in hanging on to the error.
At (2.3), our data stack is known to be in a reliable state for the next line of code to be interpreted.
Finally, at (2.4), we know an error occured, so we *don't* know the state of the data stack.

	PROCEDURE resetDataStack.
		Set data stack depth to zero.

	PROCEDURE reportError.
		Print error message to console, where message is i'th entry in a string table, and i = error code.

	VAR errorMsgTable: MAP OF STRING
		NO_ERROR: "No error; should not be seeing this."
		...

	PROCEDURE clearError;
		error = NO_ERROR


Moving on to (3), we've just finished interpreting a line of text at this point.
We don't know the state of the data stack.
(We *do* know the state of the return stack at least allowed control to return to the outer interpreter;
therefore, we heuristically trust the return stack to remain in good condition.)
However, other kinds of errors could potentially have caused early termination of interpretation.
A problem happens when *both* stack over/underflow and any other kind of error happens at the same time.
Since the error condition can only record a single error, which error message do we show?
Since we reset the stack on any error report anyway, I deprioritized the stack bounds error.

	PROCEDURE dstackOutOfBounds: BOOLEAN.
		RETURN (data stack depth < 0) OR (data stack depth > limit)

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
Also, it's entirely conceivable that a "word", as returned by takeNextWord, can be of zero length;
imagine a buffer that contains nothing but whitespace.

Right now, the loop structure is:

                WHILE no error AND line not yet exhausted DO
			Take next word.
			...

however, this doesn't take a zero-length word into consideration.
And, honestly, can a zero-length word still be a "word"?
It doesn't follow, logically.
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

But, this requires we maintain flags and duplicates storage requirements.
The control flow logic between takeNextWord and lineNotYetExhausted is fairly intricate.
I think a simpler approach would be as follows:

	PROCEDURE lineNotYetExhausted: BOOLEAN.
		Skip whitespace, if any.
		RETURN if characters remain in the input buffer to be processed.

	PROCEDURE takeNextWord.
		Mark start of word.
		Skip non-whitespace characters.
		Mark end of word.

This actually simplifies the implementation of takeNextWord somewhat, and
I think delivers on the promise that a word can never be of zero-length for as long as our loop invariant holds.
The only "weird" aspect to lineNotYetExhausted is that it affects state;
it's not referentially transparent.

	
                        Locate its definition in the dictionary.
			(4.2)
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
			(4.1)
