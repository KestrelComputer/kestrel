---
layout: post
title:  "Prototype 2-Pass Assembler Works!"
date:   2014-12-31 23:00:00
---

In the previous article, I briefly mentioned problems I ran into while trying to support forward references in my own assembler for the RISC-V architecture.
I had mentioned that I threw away the old code because I had coded myself into a corner, and could not figure out where to go from there.
Today, I spent some time looking further into the problems of writing a multi-pass assembler (2-pass specifically), since I had the day off.
I'm happy to report that I've solved my immediate problems with the old assembler design, and am ready to start anew on a home-made RISC-V assembler.

### The Original Architecture

The original assembler design relied on a Pratt parser to effect changes to the code and/or data sections directly.
Provided symbols were defined before their use, this approach offered elegance and responsiveness.
This one-pass approach, of course, had the problem of not supporting forward references to as yet undefined symbols.
Thus, it became impossible to write something even as simple as this:

    ; Map the source string to a set of offsets to add to the string
    ; to achieve a ROT13 effect.  Assumes fully capitalized input.
    ;
    ; A0 -> input string; A1 -> output vector.
    planRot13:
            lb      t0,a0,0
            beq     t0,x0,done      ; BOOM -- forward reference unresolvable
            addi    t1,x0,'N'
            slt     t1,t0,t1        ; t1 = (t0 < 'N')? 1 : 0
            addi    t1,t1,-1        ; t1 = (t0 < 'N')? 0 : -1
            andi    t1,t1,-26       ; t1 = (t0 < 'N')? 0 : -26
            addi    t1,t1,13        ; t1 = (t0 < 'N')? 13 : -13 ;-)
            sb      t1,a1,0
            addi    a0,a0,1
            addi    a1,a1,1
            jal     x0,planRot13
    done:   jalr    x0,ra,0

### Inspiration

On a whim, I decided to check out how some other multi-pass assemblers worked.
I tried looking at [nasm](http://nasm.us) and [fasm](http://flatassembler.com),
but these projects are *so* big I couldn't even figure out where to start looking for the information I sought.
Trying to find information on websites like [stackoverflow.com](http://stackoverflow.com) proved similarly fruitless.
While plenty of questions exist on how to implement such an assembler,
all the answers provided were vague and generic.
Few websites had any kind of specifics;
those that did were not applicable to my project for one reason or another (implementation complexity usually being the primary reason).

Finally, I tried for something smaller, like the 6502 microprocessor.
I found a *great* project which,
while it didn't answer my questions directly,
nonetheless provided a spark of inspiration for my own assembler.
It turns out the 6502 has a 2-pass *symbolic* assembler that can fit inside of *two kilobytes*.
It's called [2KSA](http://6502.org/source/monitors/2ksa.pdf) (PDF).

2KSA, it turns out, translates your assembly code a symbolic representation which happens to match the emitted code size.
This lets the assembler manipulate, and even relocate, chunks of code prior to final binary production.
Only when the user provides the `-ASSEM` command does the assembler compile down to the final binary.
This second pass happens very quickly and easily, since it's almost entirely table-driven.

This got me thinking &mdash; what if I could employ a similar technique for my own assembling needs?
At first I came up with a design similar to Martin Richards' BCPL compiler.
It would translate the source into a parse tree;
however, with all the links pointing everywhere, it took up quite a chunk of memory.
Even though I have many gigabytes of RAM to play with,
I would like to eventually port the assembler to the Kestrel itself,
which imposes a 16MB memory limitation with my current hardware,
so I strongly desired a more compact representation.

Then it occurred to me, as I worked on the Forth compiler detailed in the previous article:
why not use a stack machine interpreter inside the assembler for the second pass?
I'm already doing that for the Machine Forth compiler, after all.
It's not hard to get working, and the reduced quantity of structure fields contributes to its smaller representation.

Thus, the code you see in this article was born.


### The New Architecture


Out of sheer convenience, I used the Go programming language to write my prototype.
Since I want to eventually port the assembler to the Kestrel itself at some point,
I'll probably write any finished assembler in Forth,
since Forth ports much more easily than C (and, thus, any languages build via C).

The code examples below will only show the relevant code excerpts.
You can find the full source code [here](https://github.com/KestrelComputer/kestrel/commit/5f86f2a267c26585c5187fef4f4e11a3495db029).

#### Syntax

The assembler only recognizes the `DD` (Define Double-word) command, which lays down a 64-bit integer to the compiled image.
It recognizes decimal and hexadecimal integers (but no strings or character constants),
and how to subtract two numbers.
It's just enough to compile the following test code:

                dd  65
                dd  0
        B:      dd  iuart-B
        L:      dd  0
                dd  L
        iuart:  dd  $0F00000000000000

Notice that the command at `B` has a forward reference to `iuart`, and it's used in an expression to boot.

To help the lexer identify the various tokens in the above source listing,
it's really convenient to identify each type of token with a unique identifier.
This isn't just a convenience for parsing;
it's actually *very* useful during pass 2, for it greatly simplifies handler dispatch.

    const (
            TokSpace = iota
            TokName
            TokNumber
            TokComma
            TokColon
            TokMinus
            TokDollar
            TokUnknown

            // These are the non-terminal tokens.
            TokDD
    )

I maintain assembler state globally.
It's so much simpler this way.
I could have used a structure for this stuff, but it didn't buy me anything.

`insrc` and `inpt` maintain where the lexer points in the current input file.
The former holds the entirety of the source file in memory, while the latter merely indexes into it.

    var (
            insrc []byte
            inpt int

The assembler stores the pass-1 location counter in `loc`.
I use `loc2` for the pass-2 location counter, but separate variables aren't required.
I used them only to compare the results while debugging.
In a real assembler, it's plenty sufficient to reset `loc` back to 0 and just re-use it.

            loc, loc2 int64


When discovering the value of a label, we need to remember that value in a data structure.
I could have used Go's built-in maps for this purpose, but wasn't thinking about it at the time.
I use, instead, a singly linked list (as I would in Forth or C).
Most likely, I probably thought about making it as close to the final form as possible.

    type Label struct {
            next    *Label
            name    string
            value   int64
    }

    // in var block
            labels *Label

A function named `nextToken` helps maintain the illusion of a stream of tokens.
`token` holds the current token.
We implement a look-ahead of 1 token (to support LL-style parsing) with `next`.

    type T struct {
            kind    int
            text    string
            val     int64
            err     error
    }

    // in var block
            token, next *T

While performing pass 1 parsing, we build up a list of instructions for the second pass to execute.
`p2src` holds a list of tokens in RPN format, which serves to direct pass-2 activities.

            p2src []*T

While executing this plan, however, we need a data stack to hold intermediate computations on immediate values.

            stk [NSTK]int64
            sp int
    )

#### Pass 1

The first pass is, despite the sheer volume of code behind it, moderately simple.
We want to assemble all the files on the command-line in the order given into the same project.
So, given a command like:

    bin/ap file1.asm file2.asm file3.asm

we expect a behavior identical to:

    bin/ap a-fictional-file.asm

with the following statements inside `a-fictional-file.asm`:

    include "file1.asm"
    include "file2.asm"
    include "file3.asm"

The following two functions cooperate to achieve this effect.
The assembler invokes `p1` first to conduct the first pass.
`p1` then invokes `assembleFile` for each filename discovered on the command line.
It reads in the source file completely, primes the lexer for the new file, and starts or resumes the assembly pass.

    func assembleFile(f string) error {
            var err error

            r, err := os.Open(f)
            if err != nil {
                    return err
            }
            defer r.Close()
            insrc, err = ioutil.ReadAll(r)
            if err != nil {
                    return err
            }
            inpt = 0
            nextToken()     // prime token stream 
            return assemble()
    }

    func p1() (string, error) {
            for _, f := range flag.Args() {
                    err := assembleFile(f)
                    if err != nil {
                            return f, err
                    }
            }
            return "", nil
    }

At this point, we expect only assembler directives and instructions.
The assembler thus dispatches control based on the currently available token.
If we don't find a label definition, directive, or instruction token type, we issue an error.

    func assemble() error {
            var err error

            for {
                    err = nextToken()
                    if err != nil {
                            break
                    }
                    if token.kind == TokDD {
                            err = handleDD()
                            if err != nil {
                                    break
                            }
                            continue
                    }
                    if token.kind == TokName {
                            err = defineLabel()
                            if err != nil {
                                    break
                            }
                            continue
                    }
                    return &E{msg: fmt.Sprintf("Illegal directive '%s'", token.text)};
            }

            if err == io.EOF {
                    err = nil
            }

            return err
    }

The `handleDD` function handles the `DD` directive at the syntax level.
We parse out its expression, which serves as our operand.
Please note that by the time this operation completes,
we will have already generated the RPN needed to evaluate the expression during pass 2.
Thus, we need only record the `DD` operation in `p2src` after expression parsing.
Since we know the length of each double-word matches eight bytes,
we advance our (pass 1) location counter accordingly.

    func handleDD() error {
            op := token
            err := p1expr()
            if err != nil {
                    return err
            }
            p2src = append(p2src, op)
            loc = loc + 8
            return err
    }

Please note: I wrote a very naive implementation for `DD`.
Elementary enhancements makes `handleDD` and its `DD` directive more useful in real-world programming.
Let's suppose we want to store four dwords into our program image.
Most assemblers lets you use a comma-delimited list of expressions to accomplish this goal.
It's easy enough to retrofit this behavior into `handleDD`.
Just make sure to record your `DD` directive after each item in the `p2src` list.
In other words, given the input:

    DD 1,2,3,4

we want to record it in `p2src` as if you typed this instead:

    DD 1
    DD 2
    DD 3
    DD 4

We'll talk about expression parsing below.

For defining new labels, we have `defineLabel`.
We want to make sure we check for the `:` after the label;
otherwise, we run the risk that every misspelled name (be it a legitimate label, directive, or instruction) becomes a newly defined label.

    func defineLabel() error {
            name := token.text
            err := nextToken()
            if err != nil {
                    return err
            }
            if token.kind == TokColon {
                    l := &Label{
                            next: labels,
                            name: name,
                            value: loc,
                    }
                    labels = l
                    fmt.Printf("\t%s: ($%016X)\n", l.name, l.value)
            } else {
                    err = &E{msg: fmt.Sprintf("Ambiguous label declaration for '%s'", name)}
            }
            return err
    }

Again, I deliberately wrote a naive implementation.
A real assembler would also support `=` as a token to follow the name,
so that the programmer may assign arbitrary expressions.
Indeed, this:

    label:

and this:

    label = *

mean exactly the same thing.
Since I'm just checking a proof-of-concept, obviously, I skipped implementing this syntax.
However, the reader should see from the code above how to implement this behavior.

I handle expression parsing with a traditional LL(1) parser in this assembler.
In a real-world assembler, I would choose to use a Pratt parser instead.
(Particularly if I'm coding it in Forth; the Pratt parser architecture meshes nicely with ANSI Forth wordlists.)

You can see how minimal the parser is;
it lacks support for negative numbers (however, you can easily compute them using 0-N, for some N),
and only supports subtraction.
A real assembler would support at least the four arithmetic functions,
the seven boolean functions (`AND`, `OR`, `XOR`, `NOT`, shift left, logical shift right, and arithmetic shift right),
and the comparison operators (`==`, `!=`, `<`, `<=`, `>`, `>=`).

    func p1term() error {
            err := nextToken()
            if err != nil {
                    return err
            }
            p2src = append(p2src, token)
            return nil
    }

    func p1expr() error {
            err := p1term()
            if err != nil {
                    return err
            }

            if next.kind == TokMinus {
                    err = nextToken()
                    if err != nil {
                            return err
                    }
                    op := token

                    err := p1expr()
                    if err != nil {
                            return err
                    }

                    p2src = append(p2src, op)
            }
            return nil
    }

So far, I discussed only <q>high level</q> behavior.
The code assumes, magically, that tokens exist.
The `nextToken` function, however, performs the dirty work of token management.
It maintains the "pipeline" of tokens (implemented by `token` and `next` variables) on behalf of its caller.
Additionally, if it thinks it parsed a name, it double-checks to make sure it's not really a keyword first.
If it is, it adjusts the token's classification accordingly.

Token lexing starts by skipping any pending white-space.
`start` records the beginning of the token (if any).
The giant `if` construct attempts to classify the kind of token based on leading character.

Depending on the kind of token it sees, `nextToken` relies upon any one of a handful of skip functions.
The skip function skips over characters in the input buffer as long as some predicate holds.
For example, `skipNumber` will skip characters as long as `isDigit` yields true.
`start` refers to the start of the token.
By the time the appropriate skip function comes back, `inpt` will point just past the last character of the next token.
Thus, all characters between `start` and `inpt` comprise the next token (see assignment to `next.text` below).

Some tokens are only a single character long.
These tokens are special-cased.
I'm sure there's a more elegant method of handling them;
I just can't be bothered to find a better solution at this time.

    func nextToken() error {
            token = next
            next = &T{}
            skipWS()
            start := inpt
            if inpt >= len(insrc) {
                    next.kind = TokSpace
                    next.err = io.EOF
                    return token.err
            } else if isStartOfName(insrc[inpt]) {
                    skipName()
                    next.kind = TokName
            } else if isDigit(insrc[inpt]) {
                    skipNumber()
                    next.val, next.err = strconv.ParseInt(string(insrc[start:inpt]), 10, 64)
                    next.kind = TokNumber
            } else if insrc[inpt] == ',' {
                    inpt++
                    next.kind = TokComma
            } else if insrc[inpt] == ':' {
                    inpt++
                    next.kind = TokColon
            } else if insrc[inpt] == '-' {
                    inpt++
                    next.kind = TokMinus
            } else if insrc[inpt] == '$' {
                    inpt++
                    skipHexNumber()
                    next.val, next.err = strconv.ParseInt(string(insrc[start+1:inpt]), 16, 64)
                    next.kind = TokNumber
            } else {
                    next.kind = TokUnknown
                    next.err = &E{msg: fmt.Sprintf("Illegal character '%c'", insrc[inpt])}
                    return token.err
            }

            next.text = string(insrc[start:inpt])
            if next.kind == TokName {
                    needle := strings.ToUpper(next.text)
                    for k, v := range keywords {
                            if needle == v {
                                    next.kind = k
                                    break
                            }
                    }
            }

            if (next.err == nil) && ((inpt - start) < 1) {
                    next.err = io.EOF
            }

            return token.err
    }

    var (
            keywords = map[int]string {
                    TokDD: "DD",
            }
    )

Here are the various skip functions supported:

    func skipNumber() {
            for {
                    if inpt == len(insrc) {
                            break
                    }
                    if !isDigit(insrc[inpt]) {
                            break
                    }
                    inpt++
            }
    }

    func skipHexNumber() {
            for {
                    if inpt == len(insrc) {
                            break
                    }
                    if !isHexDigit(insrc[inpt]) {
                            break
                    }
                    inpt++
            }
    }

    func skipName() {
            for {
                    if inpt == len(insrc) {
                            break
                    }
                    if !isName(insrc[inpt]) {
                            break
                    }
                    inpt++
            }
    }

    func skipWS() {
            for {
                    if inpt == len(insrc) {
                            break
                    }
                    if insrc[inpt] > 32 {
                            break
                    }
                    inpt++
            }
    }

Finally, our obligatory character classification predicates:

    func isLetter(b byte) bool {
            return (('A' <= b) && (b <= 'Z')) || (('a' <= b) && (b <= 'z'));
    }

    func isDigit(b byte) bool {
            return ('0' <= b) && (b <= '9')
    }

    func isHexDigit(b byte) bool {
            return isDigit(b) || (('A' <= b) && (b <= 'F')) || (('a' <= b) && (b <= 'f'))
    }

    func isStartOfName(b byte) bool {
            return isLetter(b) || (b == '_');
    }

    func isName(b byte) bool {
            return isLetter(b) || isDigit(b) || (b == '_');
    }

#### Pass 2

If, as claimed above, we treat the first pass as "moderately simple",
then the second pass counts as "utterly trivial."

One of the things you might have noticed in the code above is
how `p2src` gets tokens appended to it in response to parsing activity.
Also, note that the assembler uses the same `p2src` for all input files.
Thus, when the second pass runs,
the assembler already has a complete picture of the program being assembled.

The `p2` function implements the stack virtual machine that basically *is* the second pass.
We just iterate over all the instructions accumulated in the first pass,
relying on token types to decide which handler functions to invoke.
For example, numbers of type `TokNumber` are handled by `pushNumber`, etc.
See the definition of `tasks` inside the function.
It provides a mapping of token type to handler function.

(See, I told you those token types would come in handy during the second pass!)

That's .... basically it.  :)
Don't say I didn't warn you: the second pass really is this simple.

    func p2() error {
            loc2 = 0
            sp = 0
            tasks := map[int]func(*T)error {
                    TokNumber: pushNumber,
                    TokName: primLabel,
                    TokMinus: subtract,
                    TokDD: layD,
            }
            for _, t := range p2src {
                    err := tasks[t.kind](t)
                    if err != nil {
                            return err
                    }
            }
            return nil
    }

Numbers are handled by pushing them onto an assemble-time stack.
Note that I omit error checking for brevity, not only here, but in all other handlers.
In a real-world assembler, I'd of course handle errors
(e.g., if I exceed the stack depth, then I can generate an expression too complex error).

    func pushNumber(tok *T) error {
            stk[sp] = tok.val
            sp++
            return nil
    }

Labels are handled by pushing their value onto the stack.
Note that, at this point, all labels *should* have definitions, thanks to the work performed in pass one.
If this isn't the case, however, we generate an appropriate error.
This can happen, for example, if you make a forward reference and just forget to define it later.

    func primLabel(tok *T) error {
            l := labels
            for{
                    if l == nil {
                            break
                    }
                    if l.name == tok.text {
                            stk[sp] = l.value
                            sp++
                            return nil
                    }
                    l = l.next
            }
            return &E{msg: fmt.Sprintf("Pass 2 error: Undefined symbol %s", tok.text)}
    }

`subtract` calculates the difference between two on-stack numbers, leaving the result on the stack.

    func subtract(_ *T) error {
            sp--
            stk[sp-1] = stk[sp-1] - stk[sp]
            return nil
    }

`layD` lays a Double-word in memory.
The name is allegorical;
in this proof-of-concept, I just print what I would dump into memory on the screen.

    func layD(_ *T) error {
            sp--
            fmt.Printf("%016X  %016X\n", loc2, stk[sp])
            loc2 = loc2 + 8
            return nil
    }

`layD` shows something unexpectedly important:
because we expect all symbols to have definitions at this point,
we don't need to back-patch our assembled image.
Thus, we don't *actually* need to have our image resident in memory, like you do with a one-pass assembler.
We can actually step sequentially through the `p2src` instruction sequence, and just dump values to an output channel, file, socket, etc. if we wanted.
(For the convenience of interactive debugging, though, I'll probably implement an in-memory buffer anyway.)

That's it for the second pass.  I told you it'd be trivial!

#### Assembler Main Entry

The main entry point for the assembler follows.
It's pretty straight-forward;
dump a banner to the screen, perform the first pass, then the second.
If any errors are reported, display them and exit fast.

    func main() {
            flag.Parse()
            fmt.Println("I am ap, the 2-pass assembler prototype.")

            token = &T{}
            next = &T{}
            p2src = make([]*T,0)

            f, err := p1()
            if err != nil {
                    fmt.Printf("%s:Pass 1:%s\n", f, err.Error())
                    return
            }
            err = p2()
            if err != nil {
                    fmt.Printf("-:Pass 2:%s\n", err.Error())
            }
    }

#### Conclusion

I've shown a very basic, two-pass assembler (written in Go), easily adjustable for just about any CPU architecture I can think of.
You should have no difficulty porting it to other programming languages (e.g., C, Forth, etc.) either,
since I deliberately elided the bulk of an assembler's implementation complexity.
Once you get the basic fundamentals down, adding the necessary complexity appropriate for your target CPU becomes a much simpler task.
I sure wish I had access to a blog article like this three weeks ago!
I'm hoping my experiences and guidance will help others trying to understand how to write their own assemblers.

