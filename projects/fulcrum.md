---
title: Fulcrum
published_at: 8/22/23 12:00
tags: rust, embedded, pedal, analog
---

## Backstory

The tale of Fulcrum is the tale of Heuristic Industries itself and an attempt to make peace with an existential crisis at a career crossroads.

My path to designing pedals started with some kits; I'd always tried to avoid endless gear churn so I could focus on music, but was becoming interested in different overdrive circuits.
Building them myself was significantly cheaper than buying the real thing, and a loophole in my "don't focus on the gear" policy.

Pedal kits don't teach you much beyond soldering skills, but after looking at enough different topologies patterns start to emerge.
Questions begin to form.
Electrical engineering textbooks you swore you'd never open again after everything they'd put you through are dusted off.

Despite a background in computer engineering, I'd spent a decade in industry working on the web.
It was a fun and rewarding time, but I found myself pigeonholed into building the same types of web app over and over, and I found myself longing to sink my teeth into something different.
Guitar pedals presented an exciting opportunity to reconnect with my engineering roots while scratching an artistic itch.

I set my sights high: I wanted to build complex digitally-controlled analog effects that would play to my strengths.
There was a lot of catching up to do, though; I had a lot to learn about designing audio circuits, and I'd never manufactured a physical product.
If I was going to ship anything, I'd need to start with a smaller, more tractable problem and scale up from there.

### The concept

Around this time I'd recorded with my band at [Black in Bluhm](https://www.blackinbluhm.com) and gotten to know Chris.
He shared my enthusiasm for pedal tinkering, and I would stop by with breadboard creations to get his input and occasionally troubleshoot and fix broken gear.

His favorite guitar tone involved a Vox AC50 head set to the edge of breakup, with several boost pedals in front of it to gain stage his desired level of breakup.
I built him my own take on the Zvex Super Duper; two clean MOSFET boosts in a box with a master volume with my own modifications to make the breakup of the second stage when pushed more approachable.

He loved it!
But he wanted to hear less of the boost itself and more of the amp responding to the gain staging.
The more I thought about the problem space the more it seemed like a perfect first product.

## Design

The goal seemed simple on paper: I was going to build the cleanest boost possible, and incorporate optional tone shaping into it.
I'd become fascinated with [tilt EQs](https://www.guitarscience.net/tsc/tilt.htm), often found in mastering equipment but rare in guitar effects.
The studio pedigree and ability to set the frequency response fully flat seemed like a perfect fit for a boost designed for an audio engineer.

### Flavor packet

Some breadboarding and design work later I had a prototype!
It had a fully solid state switching system controlled by an ATTINY85 running some very early embedded Rust I'd written, a random DC-DC converter I'd picked out generating a -9V rail, a class A gain stage, buffer, and of course the tilt EQ running off TL072s.

I started working with another friend named Chris to develop a brand identity, and he helped me design the cool noodle-esque PCB faceplate.
I'd shoved the whole thing in a 1590BB enclosure, and completely screwed up the milling dimensions, forcing me to take a metal file to many of the holes to salvage the prototypes.

![flavor packet pedal](/assets/fulcrum/flavor_packet.webp "The 3D effect of the copper layer is even cooler in person")

Overall, it worked.
The noise floor was pretty bad, in part due to the switching frequency of the DC-DC converter and my own unfamiliarity with switching power supply design (which is a _very_ deep topic).
I'd vastly overestimated how much gain it should have, and all the way up even a low level guitar signal would clip the 18V rails on the op amp, resulting in extremely gnarly and quasi-usable distortion (the TL072 does a nasty phase inversion thing when pushed to the limit).

### Bezier

If the goal was to build a studio-grade boost pedal, I needed to look to actual studio equipment for inspiration.
Line level signals are significantly higher voltages than a raw guitar signal, and 15V bipolar rails are the widely accepted norm.
With 30V of headroom we'd be able to accommodate extremely loud guitar signals as well as outboard equipment like synthesizers.

Getting ±15V off of a single 9V input isn't a trivial task for someone new to the world of switching power supply design.
A majority of the research on this project was trying to familiarize myself with this world enough to even begin to choose a class of part that would get me there without blowing my budget.

Eventually I landed on a topology discovered deep in the bowels of the LT1054 datasheet; using a handful of external diodes and some large-valued capacitors it was possible to configure a charge pump to invert and double an input into bipolar unregulated outputs.
Our 9V input could become ±17V (accounting for losses from diode voltage drops), and with linear regulators we could convert that to a regulated ±15V supply while staying without our budget.

I was determined to stay with solid state switching, but the CD4053 I was working with tops out at 24V, and I was forced to use a much more expensive DG-series switch from Vishay that could handle the 30V rail.
While it worked in theory, in practice it ended up producing a loud popping sound when switching no matter what I did to balance the DC values on either side of the switch due to its large charge injection, an important analog switch property I hadn't been aware of.

![Bezier circuit board as shipped from the fab](/assets/fulcrum/bezier.webp "I was in my curvy traces era")

Prior to this revision I'd binge-read [Small Signal Audio Design](http://douglas-self.com/ampins/books/ssad3.htm), and like any disciple of Douglas Self had adopted the NE5532 op amp for my buffers, retaining the TL072 for the gain stage and EQ section.
The 5532 has slightly more headroom than the TL072, and has superior line-driving capabilities, allowing it to drive the 10kΩ input impedance of line-level studio equipment.

This revision of the concept came with a MOSFET-based over-voltage protection circuit I designed to protect the charge pump as well as TVS diodes for ESD protection on all of the inputs.

Assembly times on the last revision were longer than I'd like, so I made the move to PCB-mounting all of the jacks on this board to speed up the build process, but neglected to account for the curvature of the larger 125B-sized enclosure this one would be using.

### Finally, Fulcrum

The vision was starting to finally take shape.
I loved the potentiometers with detents that "snapped" into a middle (fully flat) position for the tilt EQ, and extrapolated that out to the boost control itself, allowing it to either boost or cut 20dB (10x).
If we were already bucking the boost pedal trend, it made sense to turn this pedal into the ultimate gain staging machine.
The detents made it easy to keep the gain or EQ controls neutral so they could be used independently.

With both controls pivoting around a fixed point in the middle, the name "fulcrum" just made sense.

I completely overhauled the construction and armed with some very gorgeous designs worked with [Obscura MFG](https://www.obscuramfg.com) to mill, powder coat, and print the enclosures.
Jacks and protection circuitry were now mounted on a separate board and joined with JST headers.
Purely mechanical and sacrificial protection parts could now be swapped by customers in the event of failure without the need for sending the whole pedal in or soldering.

![Fulcrum revision 1 guts](/assets/fulcrum/fulcrum_rev1_guts.webp "Now we're getting somewhere")
To get it out the door I swallowed my pride and opted for a 5V small signal relay for switching over CMOS switches, as I wasn't having much luck finding the right part.
The ATTINY85 I was using for "hold for momentary" operation was also frustratingly hard to source, so I created a combination SOIC/DIP footprint that would allow me to use whichever form factor I could source easily at the time.

Moving to four layer boards made the layout process significantly easier and having a massive ground plane did wonders for noise, especially given the proximity of the switching power supply and microcontroller to the sensitive audio circuits.
I fully moved away from ancient op amps and used the OPA1678, a modern CMOS op amp with amazing audio characteristics and a shockingly small price tag.

I thought it would be fun to make the status LED dimmable and added a trimpot that I don't think anyone has ever touched.
This added extra time to the assembly process for little gain and was promptly dropped the next time I ordered boards.

#### Power supply issues

The first versions of this I sent to friends to test received great feedback, but a few had intermittent power issues where the pedal would boot up but not pass audio.
Weeks of troubleshooting, research, and attempting to recreate the issue (I could only under very specific circumstances, but never consistently), I got to the bottom of the problem: inrush.

When a board with many pedals on it boots up, every pedal is competing for current, with many of them sucking up large quantities of it to charge bypass and decoupling capacitors, LEDs, etc. all at once.
Different power supplies combat this in different ways, but at the end of the day the entire system is in a state of duress for a period that can be as long as several seconds until a steady state is achieved.

Switching power supplies are at their core a fancy wrapper around an oscillator, and stability is paramount to successful operation.
Under certain circumstances during boot the inrush of the entire system could be large enough to result in the output pin being brought negative long enough to prevent the charge pump from bootstrapping.

The solution ended up being hilariously simple: I added a pull-down resistor to the enable pin on the charge pump, then brought it online by pulling it high with the microcontroller after a set period of time.
While it was difficult to prove it worked, with the fix in place the issue never manifested again.

#### Shipping

And with that, we were good to go!

I painstakingly assembled and packed up all 30 pedals in the first batch and opened the online store for business.

![A line of Fulcrum circuit boards lined up, mid-assembly](/assets/fulcrum/assembly.webp "You can tear through a lot of podcasts soldering this many pedals")

The first batch sold out overnight, and the reception was better than anything I could have ever asked for.

### Revision 2

As long as people kept buying them, I kept building them, and Fulcrum saw a few minor revisions to ease assembly.

In the meantime, I was doing more and more work with other pedal builders and learning a lot in the process.
It eventually made sense to apply some of this knowledge back to Fulcrum and solve some issues that had bugged me about the design.

Working with analog switches more on other projects had taught me a lot, and I finally had a part number for one that could handle the large voltage rails while keeping charge injection low enough to avoid popping.
The relay was ripped out and power consumption as well as bill of materials costs improved!

![the insides of revision 2](/assets/fulcrum/fulcrum_rev2_guts.webp "Much more professional this time")

One user reported really odd self-oscillation that would only occur in his practice space.
I spent a long time trying to recreate this problem, and was eventually able to inconsistently; it seemed to be input-dependent, and using the guitar's tone control could squelch the oscillation entirely.

While I was carefully bandwidth limiting gain stages in the circuit, the input buffer only had a high-pass filter on it.
Adding a capacitor to ground to low-pass filter the input kept any input frequencies limited to the audible range and seemed to make the issue disappear entirely.
It seems as though some strong supersonic frequencies were knocking the op amp into self-oscillation.

The X5R and X7R MLCCs I was using in the audio path seemed to work fine (especially since no bias was applied), but in the name of safety I swapped them all for C0G variants to avoid any microphonics or other nasty behavior.

By this point I'd been tinkering with ARM-based microcontrollers more and had a much more complex [bypass system](https://github.com/heuristic-industries/two-switch) developed that was somehow still cheaper and more robust than a single ATTINY85.
This found its way into this revision, and I could sleep easier at night knowing this external EEPROM would be durable beyond my lifetime.

## Legacy

In the end, Fulcrum accomplished everything it set out to do.
Meditating on a "simple" genre of effect and going from nothing to full production runs was the best thing I could have done given where I was in my guitar pedal career.
Had I picked a more complex effect I would still be iterating, and all of the lessons I learned along the way have paid huge dividends in other projects.

It's difficult to convince guitarists used to conventional dirty boosts to try something new, but Fulcrum found a niche amongst people looking for a precision tool.
The feature set is still somewhat unique, and I still hear from people that it's something they keep in their studio toolbox because of its flexibility.

![a black and white fulcrum next to each other](/assets/fulcrum/fulcrum_pair.webp "I eventually made a black version too")

While pedals in this "boring but good" genre will never be massive sellers, I hope to keep building some variation of it for as long as it makes sense.

Shipping a high quality product opened a lot of doors that I am eternally grateful for.
Without Fulcrum none of my later projects and collaborations would have materialized.
