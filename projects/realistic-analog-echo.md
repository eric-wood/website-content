---
title: Realistic Analog Echo
published_at: 4/1/26 12:00
tags: rust, embedded, analog, pedal
---

This project has been a long-running collaboration with Geoff from Winnipeg Electrical Co with the goal of re-imagining a long forgotten effect with modern features.

Despite having a base building block, this pedal was very much a "starting from scratch" project for me, and is the inception of most of my personal embedded toolkit, which has since found its way into many other projects.

![The echo pedal in all its glory](/content/assets/realistic-analog-echo/rae.webp)

## Backstory

Years ago Geoff and I were brainstorming delay pedals we wanted to release under our own brands.
He was super fond of an old delay unit Radioshack had released in the 80s that sounded especially good on guitar, but was unwieldy and not intended for modern pedalboards.

We started scheming; the core feature set was as minimal as was possible for a delay effect, but with a microcontroller driving the delay line it'd be possible to incorporate some of our favorite features from other delay pedals.
The project would involve a lot of tech that I knew how I wanted to build, but hadn't had the chance to yet.

So we started scheming.

### The Radioshack Realistic "Reverb"

This effect comes from a line of budget consumer electronics Radioshack sold in the 80s and 90s covering a very wide range of products.
They're cool looking, cheap, and in some cases actually pretty decent for the money.
Lots of stereo and hifi equipment, and even a synthesizer co-designed with Moog.

![our echo next to the original that inspired it](/content/assets/realistic-analog-echo/og.webp "The original isn't exactly pedalboard-friendly")

Prior to the 80s, reverb as an effect was limited to actual acoustic echo chambers, springs, and plates.
Technology had just progressed to the point that good algorithmic reverb was possible, albeit expensive.
Gated, nonlinear algoirthmic reverbs were all over the snare drums of yacht rock anthems crowding the airwaves.

I can only guess the sounds the designers of the Radioshack Realistic Reverb were chasing when designing it, but I know for certain it is a reverb in name only.

#### It's a delay, actually

At the heart of the echo is a single MN3207 bucket brigade chip acting as a (very short) delay line.
It is in every sense a classic analog slapback delay, with some interesting tuning.

The repeats control sets the feedback, which is tuned in such a way that it's easy to create long trails of repeats, giving it the quasi-reverb effect.
It's not a lush algorithmic reverb, but the right balance of repeats and wet/dry mix (set by the "depth" control) offers a sparse bed of echos that (unintentionally) work really well on guitar.

None of the supporting circuitry for the delay is all that interesting, and is common on analog delays from this era.
There's a handful of two-pole BJT-based anti-aliasing and reconstruction filters straight from a datasheet.

#### The preamp

For most members of the cult following around these units, the preamp is the star of the show.
It has an absurd gain range (I guess for driving weak dynamic microphones) that is capable of clipping even the weakest signals into a fuzzed out square wave, making it irresistible to guitarists endlessly looking for new sources of distortion.

The preamp is an extremely simple non-inverting op amp gain stage with a max gain of 182, which is guaranteed to slam almost any signal into the op amp rails, giving it the hard distortion character we all crave.
It is a nasty, powerful distortion sound, and makes the delay line after it even more fun and crazy to play with.

## Development

Our end goal was to preserve everything compelling about the original while fixing a few warts and adding features to expand it further.
With the original being an overall primitive design, there was a good amount of low-hanging fruit to chip away at.

Out of the gate, we knew at the bare minimum we wanted:

- To replace the 1024 stage MN3207 with 4096 stage MN3205 for longer delay times
- Modulation of the delay time with a handful of different waveform options
- Companding on the delay line to improve signal to noise ratio
- A momentary self-oscillation mode

### Early stages

Geoff sent me an early prototype he'd designed that was a nearly verbatim copy of the unit with a couple of tweaks and a compander added.
Since I was on the hook for the digital pieces, I needed to pick a microcontroller and stand up a dev board quickly that could piggyback off of the analog pieces of Geoff's board.

I quickly settled on the STM32F030F4Px, the bigger brother of a part I'd been working with and was already fond of.
Running at 48MHz we'd have a very large cycle budget to work with, and the timers and ample flash offered a lot of headroom for the project to grow, all for about a dollar!

The dev board was simple but took a few iterations to get right; I miscalculated how difficult it was to drive the absurd input capacitance of the MN3205, and it wasn't until I added a gate driver that things functioned properly.
For good measure I threw on some programming headers, potentiometers for the digital controls, and an RGB LED because why not.

![development board, revision 4 and dusty as heck](/content/assets/realistic-analog-echo/dev.webp "Yes it took 4 revisions to nail down, and this specific one has been through a LOT")

Most of the early development was done this way, with the dev board jumpered to the analog one.
Being able to hear the results of the framework I was building for this project was crucial and helped speed things along.

### Oscillators

Adding modulation to the delay line was one of our top features to check off, and it meant building out a series of low frequency oscillators (LFOs).
The complexity of a digital oscillator is highly dependent on its range; really fast or really slow oscillators stress either the underlying timer or the precision of the numeric type used.

I wanted to keep the implementation simple: the LFOs themselves would oscillate between 1 and -1 and get multiplied by a value to determine the depth of the modulation.
This is straightforward if you have the luxury of arbitrary precision floating point numbers, but unfortunately the Cortex M0 processor in the microcontroller I'd chosen lacked an FPU and I was left to fend for myself with 32-bit integers.

To represent the fractional parts of the LFO I used fixed point precision, and hastily built [a Rust crate](https://github.com/eric-wood/mini-fixed32) to make the type representations and bit shifting required to convert values more ergonomic.
With fixed point math, extra care must be taken to avoid overflow.
There was a balancing act involved in figuring out the smallest number of whole number bits I could get away with in order to maximize the prevision of the fractional part.

Really early on in this process I realized developing this on-device would be a chore, especially since I wanted to visualize the waveforms.
I whipped up a simple graphing UI using the [egui](https://github.com/emilk/egui) Rust library that let me run the same LFO code I was writing for the microcontroller.
Sometimes it's best to tune an audio product with your ears, but in this case issues with the LFO implementations were abundantly clear from visual inspection.

![the oscillator test bench GUI](/content/assets/realistic-analog-echo/lfo.webp "Lots of other LFO shapes from more recent projects too")

The first version of the basic LFOs (triangle, saw, square, and random) were free-running and stateful; every tick of the timer the previous value would get incremented based on whatever logic the LFO required.
This got us off the ground, but when connected to the actual control we realized every waveform change would reset the LFO abruptly, which sounded awful.
I rewrote them again, this time using a phase accumulator and designing each LFO as a function of its phase.
This method allows for the waveform to change on the fly, as there's no previous state required to calculate the next sample.

While the precision I'd settled on was enough for the end result, errors would build up over long cycles and manifest in waveform overshoot, aliasing, and other unwanted artifacts.
Lots of tuning was required to get things where I wanted them, including tricks like subtracting the calculated (with error!) total phase from the phase accumulator from its final result instead of resetting it to zero.
The sample rate the LFOs ran at was also a balancing act; higher sample rates helped cut down on error, since many calculations involved dividing by the sample rate, but would require significantly more CPU cycles.
With some patience I was able to nail down a good middle ground that didn't sacrifice a noticeable amount of quality.

### Bucket brigades

The platform described here is the same one as [Alone](/projects/alone), where I've written significantly more about the operating principles of BBDs and how to interface with them from digital devices.
Give it a read!

Because the MN3205 has significantly more stages than the MN3207 in Alone, there was extra stress on the gate driver due to the extra input capacitance.
Longer delay times mean we have slower clock frequencies to deal with, many of which are in the audio range, making layout more of a chore since extra care had to be taken to keep the two paths separate.

### Controls

Delay is an incredibly interactive effect that rewards tinkering on the fly.
This is difficult to do with both hands on a guitar.

Having digital controls opened up a lot of possibilities for foot-based pedal control; we had a footswitch and an input for an expression pedal, but needed to give users a straightforward interface for putting them to use as part of a performance.

#### Momentary modes

Holding down the footswitch needed to do...something.
Probably many things, after all, every single control did something cool if moved while playing.

Using sliders with LEDs for the digital controls opened up a lot of user experience possibilities; it was now possible to move one control to select other controls and have it clearly indicated.
We added a tactile switch users could hold down while moving the waveform slider to select which control was active when the footswitch was held down.
With the footswitch held, the selected control would either be moved to its minimum or maximum value, depending on where it was currently set.

This proved to be a lot of fun in early testing, and I added an additional "slew" parameter that can be set by holding the alt switch and moving the time slider to change how long it takes to transition between settings.
When the footswitch is released the slew continues to apply and the controls are gradually shifted back to their original settings.
Being able to ramp settings up and down on command makes for some really interesting effects, like approximating a rotary speaker or really abstract pitch shifting by slowly moving the time setting.

One of Geoff's original ideas from day one was a "chaos" mode that temporarily sets all of them to a random value.
The utility of this was debatable, but in practice it's silly, fun, and inspiring, which is very much in the spirit of the original.

With no controls selected, holding down the footswitch puts the delay into self-oscillation by using a CMOS switch to bypass the feedback potentiometer, slamming repeats back into the BBD input.
This is a very important delay feature that is very fun to use in live performance, so I'm very happy we were able to include it.

#### Expression pedal

Treadle-based controls for guitar pedals began their life with the advent of the "wah-wah" and over many decades a loose specification has emerged for plugging generic ones into pedals that don't have them built in.
The movable foot pedal opens up a lot of interesting options with its support for in between positions and ability to sweep a full range of motion.
Being able to change several parameters simultaneously with one foot is very compelling with a delay pedal, and we _had_ to support it.

We wanted the interface for setting this up to be as immediate as possible, so remapping and experimentation of controls on the fly was enjoyable.
Ultimately we settled on the following sequence of events:

- Double-tapping the alt button enables expression setting mode (slider LEDs begin to blink)
- The user moves the sliders into the desired toe-down position for the treadle
- Pressing the alt button again returns to normal operation
- All slider positions represent the settings for the heel-down position of the treadle

The most common expression pedal interface is a TRS jack with the expression pedal containing a single potentiometer with each leg wired to each of the connections.
With a reference voltage and ground applied to the correct pins it forms a voltage divider, and the resulting output can be read through an ADC like we would any other potentiometer.

Internally, we create virtual potentiometers that have their range limited to the two different slider settings.
When an expression pedal is connected (we use a normaled connection on the jack connected to a GPIO pin) these virtual versions of the potentiometer are used over the actual reading, allowing the pedal to morph between the two settings.

### Analog stuff

While the digital pieces took a bit of time to fully bootstrap, once the building blocks were in place iteration was extremely quick and efficient.
This is not the case for any analog project I have worked on, and was especially the case on this one.

![the internals of the pedal](/content/assets/realistic-analog-echo/guts.webp "Some of these prototype units have gone through a lot. Spot the bodge!")

#### Noise

At its core, the echo pedal is a perfect storm of tricky design and layout considerations:

- Mixed signal, with MHz-range clock sources and sensitive analog parts
- There's a high gain preamp feeding said sensitive analog parts
- Reasonably large voltage and high current clock signals in the audio range
- All in the same enclosure, sometimes impossible to separate!

Some amount of noise and jankiness is part of the vibe we wanted to preserve from the original, but there's a fine line between musical artifacts and obnoxious and undesirable cruft that is best left filtered out.
BBDs are inherently noisy and lossy devices, and having a high gain preamp feeding into them requires extra care to ensure the noise floor stays low enough to remain usable.

Design and layout were done as defensively as possible; potential sources of interference were kept as far away as physically possible, gain stages were bandwidth-limited, every trace was scrutinized.
I still found myself playing the dreaded "where is this noise coming from" game, and every iteration we chipped away at different sources of noise.

The last revision I re-thought some large pieces of the supporting circuitry, removing a completely unnecessary charge pump and -9V rail, simplifying the overall design and BOM.

#### Switching

The echo uses a TMUX4053-based buffered bypass solid state switching scheme I've used on other pedals.
This alone would be great and there would be no section on switching, but delays are in a class of effect where a "trails bypass" mode is desirable.

When in trails bypass mode the effect output stays connected to the pedal output even when switched off, allowing the delay line to trail off and empty its buffer.
This can be really useful for long delay times when a smooth transition is needed in musical passages and cutting off the output of the effect abruptly would sound disorienting.

Early design attempts creatively tried to make economical use of all three switches on the 4053, resulting in creative impedance problems and popping.
Leaving the preamp connected with its gain maxed out while the effect was off would leach noise into the output.

Further reflection brought on the realization that trails as a feature makes more sense for longer, pristine delay pedals.
With longer beds of repeats it would still be useful in ours, but it wasn't worth the extra time and BOM costs to do perfectly.

This yielded a delightful design simplification: when in trails mode and bypassed, only the delay line would be cut off, and the "dry" signal would still run through the preamp and mixing stages to the output.
While it's a bit unorthodox, the end result is a way to make use of the preamp without the delay line (something we think users will appreciate), and only two of the three switches being required.

Freeing up an extra CMOS switch allowed me to design out the self-oscillation JFET, which relied on the negative power rail to function properly.
Overall, the new scheme is a huge win and the concessions made are better aligned with the overall ethos of the pedal.

## Release

As I write this I'm waiting on the final revision of the analog board.
If all goes well, we've finally made it and I can hand things back off to Geoff for production.

It was hard to keep this a secret, and once we reached the point of no return with it where we knew we had something we started teasing it on social media.
The response has been incredible!
Even with little information out there on what it actually does people are hungry for a fresh take on the original, and if anything just appreciate that it looks cool.

I'm cautiously optimistic about ramping up production, but overall really excited to finally close out this chapter.
The entire project feels fully baked now, and the journey to get to this point has been the best education in digitally controlled analog I could have asked for.

Stay tuned as we push this over the finish line!
