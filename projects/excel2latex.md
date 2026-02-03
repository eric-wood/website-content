---
title: excel2latex
published_at: 8/29/12 12:00
tags: web, javascript
---

## Backstory

This project grew out of several layers of distraction and procrastination as I finished my computer engineering degree.
It was my final semester, I'd already accepted a job, and I was spending most of my free time in a dark windowless room hunched over a copy of Cadence drawing individual transistors by hand for my [VLSI](https://en.wikipedia.org/wiki/Very-large-scale_integration) class.
Lab reports always involved taking data on a variety of different simulation criteria, which I would jot down in a spreadsheet in OpenOffice and export onto a thumb drive.

Like many students taking computer science classes, I had been exposed to [LaTeX](https://en.wikipedia.org/wiki/LaTeX) and was smitten. I would painstakingly shoehorn it into every single assignment I could, sometimes even trying to adapt templates to satisfy a technical writing class that required Times New Roman (do not do this).
The little sprinkle of Knuth-ian magic was intoxicating, and while my equations and prose were masterfully typeset, I often lost hours of time tweaking templates or trying in vain to embed graphs and other figures.

Tables in LaTex are not what I would consider an ergonomic syntax, and after a few lab reports I was eagerly looking for a simple way to export my spreadsheets into something I could copy and paste into my lab reports.
Outside of some Excel macros that didn't run on the Mac version of Excel, there was nothing.
An opportunity to procrastinate some very tedious schoolwork presented itself to me, and I took the bait.

## How it works

XSLX files are an [open standard](https://www.iso.org/standard/65533.html) composed of numerous XML files and packaged in a `.zip` file.
The standard is very long and has a lot of words in it, but if you're in a hurry to throw together a tool it doesn't take long to unzip the file and figure out where the tabular data is stored and how to map that to the strings table.

This was an exciting era for web development, and with a smattering of new APIs available for dealing with file uploads and even drag and drop building this as a static client-side application seemed like a fun way to update my knowledge.
Thankfully, someone had build a very complete ZIP implementation I was able to leverage, and the rest was traversing the files to assemble the data and throwing the results in a text field.

For a hack that took no more than a few hours, it worked surprisingly well.
I bought a domain name and threw it up on Github Pages, then shared the URL a few places online I'd seen people looking for tools like this.

## Legacy

Not long after the first release I graduated and set aside my LaTeX ambitions for good.
Meanwhile, excel2latex grew in popularity.
A niche tool for a niche problem plaguing grad students across the globe, none of whom were as happy as I was to set aside their schoolwork and build something themselves.

I still occasionally receive exceptionally nice emails from happy users from around the world.
People would create Github accounts to report bugs, and I would do my best to fix them with the limited free time I had.
I cherished every interaction; it was incredible to see anyone finding value in it!

Sometimes I would feel guilt for how half-baked the whole thing was, and take some time to attempt to fix long-lingering issues like number formatting only to get pulled away to other projects.
There didn't seem to be an "easy way out" for it either; my little bespoke XLSX parser wasn't great, but many full-featured libraries for reading the format would neglect large portions of the spec and didn't address any of my most-reported issues.
I get it.
It's not a simple spec.

Enthusiasm for the tool seems to have tapered off, but I do intend on giving it some love eventually.
The code is the sort of sloppy mess you'd expect from someone learning Javascript, and there's a lot of useful features left on the table.
I'm a much more mature engineer now than I was when I first built it, and a rewrite to bring things full circle is very tempting.
Still, it's tough to work hard on a tool when you haven't had a need for it in over a decade.
