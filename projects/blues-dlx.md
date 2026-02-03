---
title: WEC Blues DLX
published_at: 7/13/24 12:00
tags: rust, embedded, pedal, analog
---

## Backstory

Geoff from Winnipeg Electrical Co and I have been friends for some time; we first bonded online over the complexities of trying to run small pedal businesses and would often swap engineering and business tips.

My most-used creation of his was a riff he'd done on my favorite drive circuit: the Boss BD-2.
Despite the name, the BD-2 is a genre-bending drive pedal with lots of grit and a surprisingly wide frequency range.
Geoff took the base architecture, funky discrete op amps and all, hot-rodded it to have a wider gain range, and replaced the single tone control with a 3-band Baxandall tone stack.
The "fuzz" switch on it is take on a classic BD-2 mod that pushes the pedal into a really versatile fuzz sound.

He sent me one with a ghost screen printed on it (did I mention all of his pedals are screen printed by hand?) as a halloween gift, and I was hooked.
The fuzz control in particular become a favorite, but really wanted to access it with a footswitch instead of a toggle so I could turn it on while playing.
After bugging him for a few months, he relented and we got to work on a "deluxe" version.

## Making it "deluxe"

We sketched out a feature-set for this new take on his pedal:

- The circuit itself will only get some minor tweaks Geoff had wanted to do anyways
- Replace the fuzz toggle switch with a dedicated footswitch
- Both footswitches would have a fancier "hold for momentary" switching scheme
- The costly relay used on the original would be replaced with solid state CMOS switching

### Analog

While the circuit itself would be mostly untouched, the overall plumbing would need to change to accommodate the new switching scheme.
CMOS switches are best not left exposed to the world, so we'd need input and output buffers surrounding them (which ends up being better for signal integrity anyways).
The fuzz mode would need to be reworked to allow the microcontroller to switch it.

The buffers were easy, and I slapped a design I'd successfully used elsewhere onto it along with the venerable [TMUX4053](https://www.ti.com/product/TMUX4053) using two of its three switches for the bypass switching.
I reached for the classic [NE5532](https://www.ti.com/product/NE5532) for the buffers themselves, due to its affordability, low noise, and exceptionally good driving abilities (down to 600Ω!).

#### Fuzz mode

Switching the fuzz mode was a bit more involved; the mod itself is absurdly simple: a single large-valued capacitor is applied directly to the feedback path of the main gain stage.
Most overdrive pedals do a good amount of high-pass filtering before their main clipping stages, as lower frequency content ends up creating more higher-order harmonics as the signal is clipped, often crowding out more desirable harmonic content.
The added capacitor gives the low frequency content a way in and boosts the entire effect into a blown out sound reminiscent of a fuzz pedal.

It was tempting to throw the remaining switch from our TMUX4053 at the problem, but we would have to take special care to avoid "popping," as the switching is very fast and we have to take extra care to ensure both sides of the switch are biased to the same DC values.
In the feedback path of an op amp this is risky, as the usual methods of using pull-up resistors could alter the properties of the amplifier themselves.

Instead, I opted for a JFET switch in series with the capacitor.
JFETs are great for audio switching, in that it's possible to slow the switching action down and crossfade between the two states.
They're also very quirky devices with extraordinarily low tolerances, and the [J112](https://www.onsemi.com/pdf/datasheet/j111-d.pdf) part I wanted to use could require the gate voltage to be 5V below the lowest signal peak in a worst case scenario to fully turn off!

#### Charge pump

Pedal power supplies are unipolar 9V, but a -9V rail would help keep the JFET switch fully off across the full range of the gain stage while giving us extra headroom for our buffers.
It's no uncommon to see [charge pumps](https://en.wikipedia.org/wiki/Charge_pump) used in pedal power supply designs to invert the 9V rails, and I chose a classic one I've had a lot of experience with for our design, the [LT1054](https://www.ti.com/lit/ds/symlink/lt1054.pdf).

Switching power supplies take time to properly bootstrap, and I took extra care to wait for the microcontroller to fully boot before pulling the enable pin on the charge pump high.
When people have many guitar pedals running on the same power supply, the initial power-up phase can be extremely nasty, so avoiding excessive inrush current makes our design a good pedalboard citizen and ensures conditions are right for sensitive parts of our design.

### Digital

The switching system we wanted to build would allow users to press and hold footswitches to enter a "momentary" mode, where rather than toggling the effect, it's enabled then disabled when the switch is released.
It's a small detail, but is extremely helpful for turning effects on briefly for solos and other short musical sections without having to tap dance to toggle them on and off.

It may seem like overkill, but this functionality is best handled by a microcontroller.
For this design, I [reused a system](https://github.com/heuristic-industries/two-switch) I'd built on top of the STM32F030F4Px, which while it does seem like overkill is a very small and cost-effective solution.

Mechanical latching switches are able to keep track of the state of each switch between power cycles, but we need to use an EEPROM to do it. A cheap ($0.20) part and a simple write-leveling algorithm allows us to add this functionality to our fully digital switching system while using momentary SPST switches with 100x the lifespan.

## Reception

The end result came out really well, and is now one of my all-time favorite drive pedals (I use it daily!).
It was such a hit that Geoff ended up discontinuing the original version we based it on, and it's easily one of his best-selling products.

I'll let it speak for itself:

<iframe class="youtube" src="https://www.youtube.com/embed/pZDwIhbrTW8?si=swR-MKI8l2jQdpCc" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

<iframe class="youtube" src="https://www.youtube.com/embed/BKiowyTpw3I?si=IDJ2rRMSEz2twwCL" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

<iframe class="youtube" src="https://www.youtube.com/embed/B3DFy9onzKg?si=qYTIu8pzCtP13Llu" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
