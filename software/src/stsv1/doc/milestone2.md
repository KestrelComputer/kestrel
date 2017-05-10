# Milestone-2 File Format

This document attempts to establish the file format used
by the slide deck presentation program, Milestone-2.

* Status: **DRAFT**
* Date: Tue Nov 24 20:16:24 PST 2015

## Types

A "byte" is a single 8-bit quantity.

A "half-word" is a single 16-bit quantity.
This quantity, unless otherwise specified,
is little-endian.

## Coordinates

Text would appear on a fixed character coordinate system, with
(0, 0) corresponding to the upper-left-hand corner.
(79, 0) corresponding to the upper-right-hand corner,
(0, 17) corresponding to the lower-left-hand corner,
and (79, 17) corresponding to the lower-right-hand corner.

Double-width text would appear on a fixed character coordinate system as well,
with (0, 0) corresponding to the upper-left-hand corner.
(39, 0) corresponding to the upper-right-hand corner,
(0, 17) corresponding to the lower-left-hand corner,
and (39, 17) corresponding to the lower-right-hand corner.

Graphical constructs would appear on a 640x200 bitmapped coordinate system.
(0, 0) corresponding to the upper-left-hand corner.
(639, 0) corresponding to the upper-right-hand corner,
(0, 199) corresponding to the lower-left-hand corner,
and (639, 199) corresponding to the lower-right-hand corner.

Graphical coordinates are exclusive:
that is, they describe the boundaries *between* pixels;
they do not address the pixels themselves.
For example, here is a line segment that is five pixels wide,
and some representative instructions to produce the desired image:

     99 +---+---+---+---+---+---+---+---+
        |   |   |   |   |   |   |   |   |
    100 +---+---+---+---+---+---+---+---+
        |   |###|###|###|###|###|   |   |
    101 +---+---+---+---+---+---+---+---+
        |   |   |   |   |   |   |   |   |
    102 +---+---+---+---+---+---+---+---+
        0   1   2   3   4   5   6   7   8

    HLINE(100, 1, 6)

        (or)

    FBOX(1, 6, 100, 101)

## Overall File Layout

A deck with *n* slides will typically contain *n*+1 1024-byte blocks of information.
Most of this space will be unused;
however, the layout was reasonable considering the limitations of the Kestrel-2.

### Block 0

Block 0 contains an index into subsequent blocks, one per actual slide.  The
first half-word (offset 0) contains the number of slides in the deck.
Subsequent half-words (offsets 2, 4, ..., 1022) contains the *byte* offset from
the start of the file of the corresponding slide's data stream.

For example, if a deck contains five slides, the first 12 bytes will often look
like this:

        0000: 05 00 00 04 00 08 00 0C 00 10 00 14 xx xx xx xx
              ===== =============================
                |                |
                |                +---- Table of slide offsets.
                |
                +--------------------- Five slides exist in this deck.

The remaining bytes (starting with `xx` above) are essentially garbage.

### Validation

Since the index block cannot exceed 1024 bytes,
two of which are a count of blocks,
and each reference to the corresponding data block also takes two bytes,
it follows that the slide count field can never exceed (1024-2)/2 = 511.
Milestone-2 data files with a slide count exceeding 511
are guaranteed to be invalid files.

### Blocks 1 through *n*

Slide offsets do not have to be block aligned;
however, they were as a matter of convenience.
A milestone-2 file can *never* exceed 65535 bytes in length, however.

Starting at offset 0 of a slide block
lies a byte-coded slide description instruction stream.
Although opcodes are only 8-bits in size,
they were always aligned to half-word boundaries.
Padding bytes (illustrated by `pp` below) could take on any value;
they are ignored.

Several classes of instructions exist:

        Class 1         NOP             00
                        END             01

        Class 2         TEXT            10
                        DWTEXT          11

Additional classes were specified, but never actually implemented.

        Class 3         HLINE           20
                        NELINE          21
                        SELINE          22

        Class 4         BOX             30
                        FBOX            31

        Class 5         VLINE           40


#### NOP

        00 pp

Altered nothing on the display.

#### END

        01 pp

Terminated the graphics rendering used to display the slide.

#### TEXT

        10 YY XX LL .. .. .. text follows .. .. .. [pp]

        0 <= XX < 80
        0 <= YY < 18

Draws a single width, single-height string of text at the coordinate (XX, YY).
The coordinates are 80-column character coordinates;
(0,0) corresponds to the character in the upper left-hand corner of the screen.
If LL is odd, then a padding byte must follow the text.

#### DWTEXT

        10 YY XX LL .. .. .. text follows .. .. .. [pp]

        0 <= XX < 40
        0 <= YY < 18

Draws a double width, single-height string of text at the coordinate (XX, YY).
The coordinates are 40-column character coordinates;
(0,0) corresponds to the character in the upper left-hand corner of the screen.
If LL is odd, then a padding byte must follow the text.

NOTE: This instruction was never implemented.

#### HLINE

        20 YY LL LL RR RR

        0 <= LLLL <= RRRR <= 640
        0 <= YY <= 200

Draws a white, one-pixel thick, horizontal line
from (LL, YY) to (RR, YY), exclusive.
Semantically equivalent to FBOX(L, R, T, Y, Y+1).

#### NELINE

        21 YY LL LL RR RR

        0 <= LLLL <= RRRR <= 640
        0 <= YY <= 200

Prior notes for this instruction do not exist.

I believe I wanted this instruction to draw a vector in the north-easterly
direction, at a fixed 45 degree angle, and where north was the top of the
screen.

This instruction was never implemented.

#### SELINE

        22 YY LL LL RR RR

        0 <= LLLL <= RRRR <= 640
        0 <= YY <= 200

See NELINE above, excepting that the direction of the vector is in a
south-easterly direction, and a fixed angle of -45 degrees.

#### BOX

        30 pp LL LL RR RR TT BB

        0 <= LLLL <= RRRR <= 640
        0 <= TT <= BB <= 200

Draw a white, one pixel wide outline of a rectangle from (L, T) to (R, B),
exclusive.

This instruction was never implemented.

#### FBOX

        31 pp LL LL RR RR TT BB

        0 <= LLLL <= RRRR <= 640
        0 <= TT <= BB <= 200

Draw a solid white, filled rectangle from (L, T) to (R, B), exclusive.

This instruction was never implemented.

#### VLINE

        40 xx LL LL TT BB

        0 <= LLLL <= 640
        0 <= TT <= BB <= 200

Draw a white, one pixel wide vertical line from (L, T) to (L, B), exclusive.
Semantically, this is equivalent to FBOX(L, L+1, T, B).

This instruction was never implemented.

