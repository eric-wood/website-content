---
title: KiSkeleton
published_at: 12/14/25 12:00
tags: kicad, python
---

[Project link](https://github.com/eric-wood/kiskeleton)

## The problem

I love [KiCad](https://www.kicad.org).
It is dependable, infinitely hackable, and has one of the nicest open source communities I've interacted with.
With the rise of affordable PCB prototyping came a renewed interest in OSS ECAD tooling, with KiCad at the forefront, and loads of improvements and new functionality coming each release.

Much of the guitar pedal world is still stuck on Eagle, which is now fully discontinued after being acquired by Autodesk.
Migrating off of software you've built a career on is a long and painful endeavour, and I've made it a pet project to help as many people as possible in the community make the switch to KiCad.

KiSkeleton was born out of an interesting conversation with John from [Electronic Audio Experiments](https://eae.zone) on library management.
For components like passives, the default KiCad workflow has you using generic symbols and assigning values and any other metadata.
Companies with a large catalog of parts used in their products have preferred choices for each part value shared across their entire product lines, with lots of additional metadata for BOM artifacts consumed by fabs and contract manufacturers.
In this environment it's a huge time-saver to have a symbol library with entries for each value with the proper metadata pre-filled.

Building a library like this by hand for every E96 resistor value would be tedious and time-consuming, especially when a version of this data already exists in a spreadsheet elsewhere.
Tools existed for editing a symbol library as a spreadsheet, but were limited in scope and didn't handle the creation of new entries well.

## Building a solution

The concept was simple overall: build a CLI tool that takes in spreadsheets and spits out KiCad symbol libraries.
Each row would reference an existing symbol to template off of and allow for the assignment of arbitrary columns in addition to the default ones required by KiCad.

I opted to use Python, in part because it's already the lingua franca of KiCad and very likely to be available for use by our target audience.

### Parsing

One of KiCad's biggest strengths when it comes to hackability is the fact that it uses a human-readable [s-expression format](https://dev-docs.kicad.org/en/file-formats/sexpr-intro/index.html) for all of its file types that is very simple to read and write.

Surprisingly, outside of the Python SDK built into the application itself there's very little in the way of strong libraries for reading KiCad files with Python.
While s-expressions format is fully specified, the interpretation of the data as it applies to each type of file is much murkier, mostly undocumented, completely unversioned, and subject to change with each new KiCad release.
Many libraries I've attempted to work with when building KiCad tooling fall into the trap of over-specifying the format, relying heavily on property ordering and choking on the presence of new symbol types.
Sure enough, the addition of some new font-rendering attributes added in a recent version broke all of the libraries I auditioned at the start of this project.

To give a taste of how convoluted the KiCad file format can be, these expressions would all be treated as a boolean property named `thing` in most cases (not all!):

```
(thing) 
(thing true)
(thing yes)
```

It's enough of a problem there's now [guidelines to avoid it](https://dev-docs.kicad.org/en/file-formats/sexpr-intro/index.html) in the file type, and recent efforts are underway to fix inconsistencies like this, which adds even more churn to assumptions you can't make about the file format.

Normally I wouldn't advocate for a bespoke parser, but our problem space is very bounded in that we only care about a handful of very stable properties in the symbol library file format.
Treating sections like the graphical representation for each symbol and anything else we don't care about as raw s-expressions ensures our parser will maintain some amount of backwards and forwards compatibility, barring any massive overhauls.

### Output

With the parser out of the way there's not much else going on.

KiCad symbol libraries have a notion of a "template" symbol that other symbols extend to avoid duplicating the same shared graphics and properties, and I make use of that as much as possible, since in most cases these libraries will all be using the same underlying symbol for each row.

### Future improvements

As-built it works great, but does a poor job surfacing errors related to data it can't make sense of.

I hope to revisit it in the near future and overhaul error handling completely so error messages offer more guidance than just a Python stack trace.
Additionally, it should be fault tolerant and skip over and report bogus rows while still producing output for the ones that work.

## Reception

Several guitar pedal builders (including one very prominent company I probably shouldn't name) have successfully onboarded onto KiSkeleton and are using it to generate symbol libraries.

That is about as much success as I could have asked for, and I look forward to more people stumbling across it in the future!
