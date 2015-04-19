---
layout: post
title:  "Event-Driven Forth and its Implications"
date:   2015-04-18 17:52:45
---

ANSI Forth, like the ANSI C standard library, assumes you'll be running your software in a threaded environment.  By threaded, I mean that system services *block* until finished.  For example, when you open a file, `OPEN-FILE` will block until the operating system has responded with the file's descriptor.  `KEY` blocks until at least one byte becomes available on the input stream it's currently attached to.  `PAUSE` explicitly relinguishes control of the thread until its been rescheduled.  Et cetera.

Even the very structure of the language itself seems influenced by its threaded past.  The language depends upon "parsing words", including `WORD` and `PARSE`, which can only make sense if you have a complete buffer to parse.  You guessed it; the Forth runtime will block until it has this buffer in-hand.

What would Forth be like if it were almost completely event-driven?  With some effort, you can make it look and feel like a threaded language environment.  For example, using "trampolines," you can write an implementation of `KEY` that actually *returns* to a master event loop under the hood, and resumes Forth execution once the desired event arrives.  However, I'm more interested in the evolution of the Forth implementation given a more direct, event-driven implementation.  How would using it be different?  To what extent can someone make it ANSI-compatible?

## System Software Interface: From Keyboard Events to Behavior

To be truly event-driven, we need to structure the Forth environment as a series of *callbacks*, which causes the Forth environment to *react* to various events.  Not a *lick* of Forth code should be running if the user is not interacting with the program (for brevity, let's ignore periodic activities and other things that require the use of timers).  There are a few ways to accomplish this behavior, but registering *callbacks* with the system software's event loop is the most commonly used technique today.  So, we'll go with that.

One of the first tasks any Forth must do is present an OK prompt to the user.  Indeed, if we loaded the Forth from a storage volume somehow, we'd need to invoke its initialization function to present the initial user interface to the user, and register its initial callbacks.  It'd look something kind of like this:

	: init-app
		page  0 0 at  ." Forth vX.Y" CR
		." OK" CR
		interpret-state
		0 >in !
		['] outer-handler keyboard-vector !
		;

So, at this point, we'd have a binary loaded into memory, and a teeny initialization routine has just run.  This code is now otherwise idle.  The user, of course, sees "Forth vX.Y" and "OK" on the screen, and it looks like it's waiting for commands to enter.  The reality, of course, is it's sitting inside of BIOS (or whatever) waiting for some lower-level event to occur.

Whenever the user types something on the keyboard, the event handler will grab the key from the keyboard, and attempt to do something with it.  If the `keyboard-vector` is 0, however, it just ignores the key event and goes back to what it's doing.  Since we just ran our Forth initialization, though, we know that it points to `outer-handler`, so this is the routine which gets executed for that keypress.

If the user presses the ENTER or RETURN key, then we know we need to interpret whatever the user typed previously.  So, we dispatch to a subordinate handler, `outer-dispatch`.

	: outer-handler ( ch - )
		dup 13 = over 10 = or if
			drop
			outer-dispatch 
			CR ." OK" CR
			0 >in !
			exit
		then

Otherwise, for the sake of brevity, let's assume the user is a perfect typer and just accumulate what the user types into a buffer somewhere.  Line editor functionality would go here ordinarily, but I don't want to bore you with a feature-complete editor interface.

		dup emit
		inbuf >in @ + c!   1 >in +! ;

So, we have the case where `outer-dispatch` is called if, and only if, we have a buffer of text accumulated from the user.  Its job is simply to ferry every accumulated character to the lexer.  Why?  Remember, in our example, we skipped the line editor completely.  But a real Forth implementation would need to account for the user pressing backspace, cursoring around the line, and if it's especially fancy, command-line history and even keyboard macros.  We don't want to bother the lexer with the intermediate state of the buffer.

	: outer-dispatch ( -- )
		>in @ max>in !
		0 >in !
		begin >in @ max>in @ < while
			inbuf >in @ + c@ lexer-char
			1 >in +!
		repeat
		lexer-end-of-input ;

So, although the mechanics of input handling differs wildly from a threaded Forth environment, we see that `>in` behaves in the same manner.  Even if we opt to avoid writing `WORD` or `PARSE`, at least the end-user can write them if desired.  So far so good.

Let's look at the lexer, then.  A character can be either whitespace, or non-whitespace.  We want to skip the whitespace, and just focus on the non-whitespace characters.  Let's assume our lexer defaults to a mode where it expects whitespace, and thus, ignores each character.

	: lex-ws ( ch -- )
		is-whitespace not if
			>in @ token-start !
			['] lex-token is lexer-char
		then ;

So, right away, we see that `lexer-char` has to be a *vector* of some kind (in Forth, these are called *deferred* words, since they're defined by the `DEFER` word).  That means we must account for its proper initialization when the Forth interpreter initializes itself.

	: init-app	( revised )
		page  0 0 at  ." Forth vX.Y" CR
		." OK" CR
		interpret-state
		0 >in !
		['] lex-ws is lexer-char ( ...... new )
		['] outer-handler keyboard-vector !
		;

What happens if the user just types a bunch of whitespace?  Nothing; `outer-dispatch` will iterate the list of characters it's received, and will then return to `outer-handler`, where it'll print another prompt for the user's benefit, and we're right back at our starting state.

If there *is* at least one non-space character in the buffer, though, `lex-ws` will catch it, and set `token-start` to where it found it.  It knows that we're looking at a token at this point, so it changes `lexer-char` to refer to a more suitable handler (namely, one that looks for whitespace again):

	: lex-non-ws ( ch -- )
		is-whitespace if
			>in @ token-start @ - token-length !
			['] lex-ws is lexer-char
			token-start @ inbuf +  token-length @  handle-word
		then ;

What happens when the user types in a word, but doesn't terminate it with whitespace before hitting ENTER?  Unfortunately, it'll get skipped in this situation.  So, as written, we have a bug.  We can fix this by treating the end of input condition explicitly:

	: outer-dispatch ( -- ) ( revised )
		>in @ max>in !
		0 >in !
		begin >in @ max>in @ < while
			inbuf >in @ + c@ lexer-char
			1 >in +!
		repeat
		lexer-end-of-input ( .... new )
		;

	: lex-non-ws ( ch -- ) ( revised )
		is-whitespace if lexer-token then ( .... new );

	: lexer-end-of-input ( -- )
		['] lexer-char ['] lex-non-ws is? if lexer-token then ;

	: lexer-token ( -- )
		>in @ token-start @ - token-length !
		['] lex-ws is lexer-char
		token-start @ inbuf +  token-length @  handle-word ;

You can see where I'm headed with this: `handle-word` is responsible for locating the word in the dictionary, dispatching to it if found, and if not, attempting to convert it to a number, and if *that* fails, establishing an error condition of some kind.  Since we're deeply nested, we have two choices: blow away the return stack and unconditionally invoke our initialization routine again, or we set a global error state, which Forth's outer interpreter recognizes and acts upon.  It's not entirely clear which is better.  However, the latter is at least easier to debug from a functional and integration perspective.  Note that I've omitted handling errors for brevity.

## I/O

Remember how the Forth application's initializer established the system's keyboard event handler?  What if the application written *in* Forth wants access to individual keyboard events as well?  It's not possible to implement `KEY`, for example, without a lot of state manipulation behind the scenes.  What we'd like to do is establish a protocol by which the Forth interpreter and the Forth application it's running can share the `keyboard-vector` variable.

Almost certainly, it'd be impossible to write something like:

	KEY .

to get the ASCII code of a typed character.  This is because the interpreter would have to return to the main event loop before the system software could dispatch on a keyboard event again.  So, in this case, `.` would dump a bogus item on the stack before it'd get a chance to respond to any key press.

Instead, you'll need to alter the `keyboard-vector` yourself:

	keyboard-vector @ old-vector !
	: onChar	.  old-vector @ keyboard-vector ! ;
	' onChar keyboard-vector !

After typing the fourth line, you'd notice the interpreter would print "OK", but when you hit the next key on the keyboard, it'd print the ASCII value of the typed character.  Then behavior would return to normal.

Preventing the "OK" prompt from appearing in the output of a "running" program, you'd need some additional means of communicating when it's OK and when it's not OK for the Forth interpreter to report its prompt to the user.  It'd almost certainly involve another deferred word.

As you might imagine, if you didn't want to write your own line editor, but did want to read in an arbitrary line of text for your own needs, you'd have to revector and restore `outer-handler` in a manner not entirely unlike with `keyboard-vector` above.

	: do-nothing ;

	: on-name ( -- )
	  ." Hello, " inbuf >in @ type cr
	  old-line-vector @ is outer-handler
	  old-prompt-vector @ is .prompt ;

	: hello ( -- )
	  outer-handler is@ old-line-vector !
	  .prompt is@ old-prompt-vector !
	  ['] do-nothing is .prompt
	  ['] on-name is outer-handler
	  ." What is your name? " ;

## Parsing Words

You may have noticed that I have not defined any constants or variables in the pseudo-code above.  That's because constructs like VARIABLE and CONSTANT are *parsing words*; that is, they read ahead in the input stream.  This approach works, as I've indicated above, but it turns out there's a slightly better way to handle this situation.

If we let `handle-word` itself be a vectored word just like `lexer-char`, then we can adjust it contextually.  For example, how many times have you seen Forth code like this?

	VARIABLE X
	VARIABLE Y
	VARIABLE CHARMAP
	80 CONSTANT WIDTH
	25 CONSTANT HEIGHT

In many cases, it'd be easier to collect definitions into higher-level constructs:

	VARS X Y CHARMAP ;
	25 80 CONSTANTS WIDTH HEIGHT ;

Thus, I'm not convinced that a purely event-driven Forth implementation would have a word `VARIABLE` or `CONSTANT`.  Instead, we'd define something like:

	: VARS
	  ['] do-variable-defn is handle-word ;

	: CONSTANTS
	  ['] do-constant-defn is handle-word ;

where `do-variable-defn` and `do-constant-defn` are responsible for populating the dictionary with the appropriate structures necessary to implement a variable or constant, respectively.  Each of these handlers would need to detect when the `;` word appears, so as to restore the previous value of `handle-word`'s vector.

This significantly changes the semantics of the language.  Consider `CREATE`, which you can often find tucked away in definitions like this:

	: ARRAY ( n -- ) \ creates a vector of n cells.
		CREATE CELLS ALLOT ;

	40 ARRAY inbuf  \ create input buffer containing 40 cells worth of bytes.

This constructs a vector of n cells in the dictionary, and binds it to a name.  When you invoke the name, it yields the buffer's address.

But, if `CREATE` were simply a state-changing word, and didn't parse ahead, `CELLS ALLOT` would execute *before* the next word is passed to `handle-word`, and thus, before the `inbuf`'s dictionary entry can be created.  This is clearly undesirable for a number of reasons, the biggest being that we lose our ability to know where our buffer sits in memory.

Instead, we'd need to break ARRAY up into two pieces:

	: ARRAY ( n -- )
		CREATE
		['] finish-array is follow-up ;

	: finish-array ( n -- )
		CELLS ALLOT ;

Now, when `CREATE` executes, it just sets `handle-word` to a creation handler, and then executes its follow-up:

	: CREATE ( -- )
		['] handle-word >body @ previous-handler !
		['] do-creation is handle-word ;

	: do-creation ( caddr u -- )
		( ... code to insert word into dictionary structure goes here ... )
		previous-handler @ is handle-word
		follow-up ;

If you wanted to affix a different behavior for the created word, you would place your `DOES>` code inside `finish-array` above, as normal.

This is a lot of boilerplate to have around for something fairly simple.  What'd probably end up happening, and which would have similar execution semantics, is to abuse the colon definition a word appears in, like so:

	: inbuf ARRAY [ 40 CELLS,

Note that the buffer definition doesn't end with a `;` word; `[` will switch back to interpreter mode, without compiling any return instructions.  Thus, executing `inbuf` results in the `ARRAY` handler being called, with the address of the 40-cell long buffer on the *return stack*.  [ColorForth](http://www.colorforth.com), for instance, exploits this technique frequently, as it lacks any means of forward parsing what-so-ever.

## Sigils and [Stropping](http://en.wikipedia.org/wiki/Stropping_%28syntax%29)

Parsing words, if implemented without the aid of a lexer component like `WORD` or `PARSE`, requires a fair bit of state management.  A better approach would be to implement a more intelligent `handle-word` implementation.  One way to do this is to dispatch based on the first byte of the token parsed.

For example, words that begin with `:` are defined words, while words that begin with `$` might be numeric constants.  We can still use words like `VARS`, of course.  So, a more complete example of a program that asks you your name might look like this:

	VARS :old-line-vector :old-prompt-vector

	PROCS
	:do-nothing ;

	:on-name ( -- )
	  ." Hello, " inbuf >in @ type cr
	  old-line-vector @ `outer-handler
	  old-prompt-vector @ `.prompt ;

	:is@ ( xt -- xt' )
	  >body @ ;

	:hello ( -- )
	  '.prompt is@ old-prompt-vector !
	  'do-nothing is .prompt
	  'outer-handler is@ old-line-vector !
	  'on-name is outer-handler
	  ." What is your name? " ;

As you can see, it'd bear only superficial resemblence to ANSI Forth as we'd know it today.  Indeed, it starts to resemble ColorForth.

## Conclusion

Had Forth been built around an event-driven core, I think it would have been very different than the systems we see today.  Some programs will become more complicated as a result of exposing lower-level control flow to the user, while other operations will become simpler overall.  I think the Kestrel-3 will be an ideal platform to explore these concepts further.  I've talked about the possibility of making its next version of STS an evented operating system; I wonder what it'd take to do the same for an in-ROM Forth implementation.
