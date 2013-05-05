# Kestrel

With each passing day, technically capable consumers of computing technology
increasingly lose their rights with computer hardware.  The successful
deployment of UEFI in the market, with Microsoft controlling which operating
systems receive a key that permits it to be booted, poses a potential threat to
OS development freedom.  While some look to prominent Linux suppliers as an
escape from the Intel/Microsoft monopoly, I have taken a different route -- I
decided to build my own computer completely from scratch.  My computer
architecture is fully open; anyone can review the source, learn from, and hack
it to suit their needs.

## Introduction and Background

The Kestrel project is all about freedom of computing and self-education using
all-homebrew design, right down to having openly documented hardware and
software at all levels, from schematics and register-transfer logic all the way
up to OS API and user tutorials.  Its design is informed from a variety of
sources based on my experience:

* Excellence in Hardware Engineering
    * **Atari 800**, for demonstrating how small modules that do one job exceptionally well can interact to comprise a hardware system of exceptional capability for minimum cost.
    * **Atari ST**, for demonstrating how commodity hardware can be assembled to form a long-lived, fan-supported environment that transitioned from a primarily closed-source to open-source community.
    * **Commodore Amiga**, for the same reasons as the Atari 800, except adjusted for newer capabilities afforded by faster bus architectures and wider data paths.  (This comes as no surprise to anyone familiar with Atari hardware, for the Amiga OCS chipset was designed by the same engineers as the Atari 800 chipset, and shares much in the way of architecture.)
* Excellence in Accessible and Usable Documentation
    * **Commodore 64/128**, for having a single volume that provided all levels of knowledge, hardware (including schematics and data sheets) to OS-level system calls.
    * **Commodore Amiga**, for having exceptionally well-written programmers reference manuals that were easy to follow, contained numerous tutorial material, and never sacrificed its value as a reference.
* Excellence in System Software Design
    * **CP/M**, for being the simplest possible thing that could possibly work.
    * **Commodore 64/128**, for pre-dating many concepts later independently rediscovered by the authors of Plan 9 from Bell Labs.  ("Everything is a GPIB device", versus, "Everything is a file," and the use of command channels instead of dedicated system calls like `ioctl()`.)
    * **Commodore Amiga**, for demonstrating the effectiveness of preemptive multitasking in a consumer product, without requiring many megabytes of memory.
    * **Jupiter ACE**, for demonstrating what's really possible with only 2KiB of system RAM, of which half is dedicated to video memory.
* Excellence in User Experience
    * **Commodore Amiga**, for demonstrating real-time GUI concepts that set the bar for UX that wasn't matched for more than a decade thereafter.
    * **Jupiter ACE**, for demonstrating that Forth _can_ in fact be packaged for consumer use.
    * **Tripos**, for providing an excellent user experience at the shell.

## Installing and Testing

t.b.d.

## Contributing

### Branching

The "master" branch must always be a valid build, and as such, always represents the current release.
Changes queued for the next release will be placed on a branch named "working".
Feature branches, therefore, must be derived off of the working branch.

To create a feature branch:

    git checkout working
    git pull
    git checkout -b featureBranch
    git checkout -b featureBranch-wip

Perform all your edits in the WIP branch.
Commit as often as you feel comfortable.
You may even open pull requests on the WIP branch;
however, no PR opened from a WIP branch will ever be merged.

To merge code, squash all your commits into the non-wip branch, like so:

    git checkout featureBranch
    git merge --squash featureBranch-wip
    git commit -a
    git push -u origin featureBranch

You may now open a pull request from your featureBranch into the working branch.  Pull requests into master will be categorically closed.

The "git commit -a" step will open a text editor allowing you to enter a commit log.
This log should answer the following questions, where appropriate:

1. What is the problem?
1. Why is it a problem for you?
1. What is your solution?
1. How does your solution work?  (Recommended for non-trivial changes.)
1. Why should we use your solution over someone elses?  (Recommended especially if multiple solutions are proposed.)

Remember that monster-sized pull requests are a bear to code review, so having helpful commit logs are an absolute must to review changes as quickly and easily as possible.

Finally, if you break the build or environment, you're ultimately responsible for fixing it.

### Source Representation

The age of 80-column punch cards are over; I think most people have monitors capable of showing at least 132 columns of text these days.  Use them.
However, remember that the longer the line, especially those exceeding 132 characters, the more likely splitting a line might make some sense.
Use best judgement here; I regularly break long lines, but I also regularly exceed the 80-character limit too.

### Unit and Integration Tests

Pull requests that lack adequate tests will be called out, or even rejected.  Make sure your code is tested.  Where applicable, try to write your tests _first_, following [test-driven development](http://en.wikipedia.org/wiki/Test-driven_development) practices.

