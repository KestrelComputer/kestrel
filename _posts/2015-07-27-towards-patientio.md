---
layout: post
title:  "Towards a performant, scalable, and consistent I/O subsystem for the Kestrel-3"
date:   2015-07-27 18:41:00
---

Today, I presented a tech-talk on what I'm currently thinking the Kestrel-3's I/O architecture should be.
I'm calling the I/O implementation "PatientIO", as a pun on "RapidIO."
For the purposes of this talk, PatientIO and RapidIO can be thought of identically.
PatientIO differs from RapidIO only in how device enumeration happens, and on supported interconnect media;
however, these topics are not covered.

This talk covers the following topics:

* Motivation and problem statement.
* *Very* high-level overview of current solution.
* Anticipated data rates.
* Anticipated impact on CPU performance (it's deleterious; however, it should still be usable).
* Security &mdash; how I work to prevent [RowHammer](https://en.wikipedia.org/wiki/Row_hammer)-like exploitation of the I/O interconnect.

[You can view the slides here]({{site.baseurl}}/slides/patientio/index.html).

