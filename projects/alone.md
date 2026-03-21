---
title: Alone
published_at: 9/22/25 12:00
tags: rust, embedded, pedal
---

In a world of full-featured pedals with endless knobs, Alone is a stripped down, finely-tuned, and shockingly powerful flanger and chorus machine dreamt up by Alec Breslow of Mask Audio Electronics and given a digital brain by yours truly.

![Alone pedal, sitting on a bed of rocks](/content/assets/alone/alone.webp)

Alec set out to build a companion to his beloved [Neckbrace phaser pedal](https://maskaudioelectronics.com/collections/pedals/products/neckbrace) utilizing the same platform and "less is more" philosophy.
You get two knobs: rate, and depth, and a toggle to go between modes; the rest of the parameters are hidden and dialed in by Alec.

Early on in the development, it became clear that supporting different parameters for each mode in a purely analog design was untenable, and a digital control scheme would grant us more flexibility to dial every parameter for each mod individually.

## How it works

### Modulation in a nutshell

Most modulation effects are achieved using small delay lines, and Alone is no different.
Chorus and flanging in particular rely on a cool property of delay lines: modulating the delay time plays back samples already in the buffer at a different rate, changing the pitch.

In most analog effects, delay lines are constructed from [bucket brigade devices](https://en.wikipedia.org/wiki/Bucket-brigade_device) (BBDs).
Internally, these chips consist of a series of stages of [FETs](https://en.wikipedia.org/wiki/Field-effect_transistor) connected to small capacitors; every clock pulse, a sample is taken from the input and moved through each stage, gated by the FET and stored in the accompanying capacitor.
For digitally-brained folks, think of it like an analog shift register.
To construct a very long delay time for an audio signal you need a lot of these, and for our application we're using the MN3207, which tops out at a theoretical 51.2ms (although it can go much longer).

BBDs are very quirky, lossy devices, and preserving signal integrity across a very wide frequency range is an artform.
Our application follows a common topology seen in most audio effects, although the secret sauce ends up being how each stage is configured.

![chorus](/content/assets/alone/chorus.svg "Chorus")
![flange](/content/assets/alone/flanger.svg "Flange")

- **Compressor/expander**: compresses then expands the signal to lower/increase dynamic range before and after the BBD, bringing it higher above the noise floor
- **Anti-aliasing filter**: a low-pass filter that bandwidth-limits the signal, removing higher frequencies the BBD cannot reproduce that would be "aliased" into the audible range by
- **Reconstruction filter**: converts the discrete samples output by the BBD into a continuous analog waveform, again bandwidth limiting to remove any aliasing artifacts and clock noise from the BBD itself

Note that the flange and chorus diagrams are almost identical, with the flange adding a feedback path from the delay line output back into itself; this and the delay time are the biggest differences between the two effects.

#### Why

This is usually the point in the explanation where seasoned engineers stop me and ask me why us pedal people play with these things.
Delay lines are trivial in digital signal processing, why go through all of this effort to work with a device that clearly hates you?

The answer is simple: because it's cool. And sounds cool too.

All of the supporting circuitry required to get a usable signal out of a BBD defines its sound as much as the BBD itself.
Companding isn't perfect and impacts the dynamics (and therefore "feel") of the effect.
The filters on either end happen to coincide with frequencies that are very flattering on guitar and in many cases help it sit better in a mix.

There's no shortage of really good plugins and pedals that emulate these things, but if you're taking the trouble to own a dedicated hardware device for the effect you might as well use the real thing.
And harnessing exotic and weird tech of the past for musical purposes is undeniably punk as hell.

### Digital control

With Alec's modulation topology in hand, I set out to build digital controls for it.
This enables us to set our min and max parameters for each mode, along with the delay time and even the taper of the control when needed.

#### Driving the BBD

BBDs are clock-driven devices, and microcontrollers are clock-generating machines.
It's a perfect pairing.
The complimentary clock required by the MN3207 for our lowest delay time ends up around 500kHz, which is trivial for most PWM peripherals.

From the start we have a few problems:

- Our BBD needs a 9V clock
- The clock pin input capacitance is 700pF (!!!)

The input capacitance is a huge buzz kill.
Most BBDs are very primitive devices, and there's no clock buffer.
As far as I can tell, the gate of every single FET is tied directly to the clock pin, resulting in the high capacitance number.

Coupled with the input impedance, this capacitance forms a low-pass filter, which muddies up our clean clock signal and keeps the transistors from turning on exactly when we need them to.
Overriding this capacitive effect requires large amounts of current, quickly.
I will spare you the math, but on larger BBDs this number can approach 1A of current draw very quickly!

This problem is not unique to BBDs; switching power supplies and motor control systems suffer from similar issues, usually switching a massive power MOSFET, and there is a whole category of IC designed to solve it: gate drivers.
Paired with a fairly large decoupling capacitor to store and supply the instantaneous current required to drive the BBD, the gate driver converts our 3.3V clock signals to an extremely beefy 9V one while providing the full current required to override any filtering effects.

#### The microcontroller

I reached for an old friend with this design: the venerable [STM32F030C8](https://www.st.com/en/microcontrollers-microprocessors/stm32f030c8.html).
It's extremely affordable, reasonably powerful, and has more than enough IO and flash to accomplish the task at hand.
Most importantly, though, I'd already vetted it in the form of a development board for applications like this.

The PWM peripheral on these is very powerful and up to the task of generating the complimentary clock directly, while we have more than enough clock cycles to handle the control logic and generate the low-frequency oscillator.

As with all of my embedded projects, I'm reaching for Rust and [Embassy](https://embassy.dev), and to make the fixed point math we'll be doing a little easier my own [mini-fixed32](https://github.com/eric-wood/mini-fixed32) crate.

#### Controls

Potentiometers are wired directly to the ADC inputs on the microcontroller.
Built-in ADCs tend to be very noisy with mediocre resolution, but it's more than enough for this application if extra care is taken.

Raw control values are passed through a low-pass filter (I am fond of Andrew Simper's [dynamic smoothing filter](https://cytomic.com/files/dsp/DynamicSmoothing.pdf)!), and we least-significant bit, which has a tendency to flicker at a lower frequency than is reasonable to filter.
The internal sampling is set to avoid "ghosting" due to the internal capacitor on the ADC.

![alone prototype next to neckbrace flanger](/content/assets/alone/neckbrace.webp "Twinning")

The mode switch is wired up to GPIO pins, and its second pole is used to switch the feedback path on for the flange mode.
The footswitch and internal relay get wired directly to the microcontroller, which let me add a fun "hold" mode that kicks in when the switch is held to temporarily minimize or maximize the value of the rate control hands-free.

#### LFOs

The chorus and flange modes use the same triangle wave low-frequency oscillator, ranging from 0.05-7Hz, while the "warble" mode is a random oscillator with a simple DSP low-pass filter applied with the cutoff at the LFO frequency.

Since we don't have access to a true random peripheral, the random oscillator uses the [wyrand](https://github.com/wangyi-fudan/wyhash) brand of [LFSR](https://en.wikipedia.org/wiki/Linear-feedback_shift_register) in the [tinyrand](https://github.com/obsidiandynamics/tinyrand) crate.
On boot (and once an hour or so), I generate a seed by pulling the least-significant bit from the ADC (muxed to the internal temperature sensor) over and over.
The end result is more than random enough to be perceived as truly random, and every power cycle results in a new sequence.

## Development process

Like any good project, this one took a few iterations.

Working on hardware remotely is a challenging process, and feedback loops can be long.
There's a lot of waiting on packages, PCB fabrication, firmware.
It takes a few iterations to get things right.

The first PCB revision I had given Alec the wrong pinouts and the potentiometers had to be bodged to pins that were actually wired to the ADC.
Sorry about that, Alec.
I should know better.

![PCB with cut trace and several bodge wires running everywhere](/content/assets/alone/bodge.webp "Bodges galore. Thanks, Eric!")

Control ranges were dialed in by sending Alec a ZIP file with a handful of different firmwares he could flash and compare.
This worked well but it would have been a lot more fun to meet up and knock it all out in an afternoon in person.
Maybe next time.

Once we'd finalized the design, the first batch of production PCBs was ordered.
Alec quickly noticed as he started building them up that roughly half of them suffered from a severe noise issue that wasn't present on any of the prototype runs.
It's normal to find issues as production runs scale up, but we were surprised to find something show-stopping and inconsistent this late, especially with a non-trivial amount of inventory that needed to be fixed.

Debugging it was a nightmare.
A few PCBs with "BAD" written on them arrived on my doorstep and I got to work.
Hours of sanity checking and the first clue finally presented itself: touching a specific capacitor next to an op amp temporarily fixed the problem.
Something was capacitively-coupled to something it wasn't supposed to be, and it seemed like supersonic noise from part of the digital system was making the op amp unstable.
Further examination of the schematic, a capacitor bodged into the feedback path to bandwidth limit the op amp, and the noise was gone.

On to production!

## Reception

I love this pedal.
I've never been much of a chorus or flanger user in my own music, but the limited control set was a breath of fresh air and I find myself reaching for it regularly to add some movement to guitar parts.

Seeing what people made with it in the demo videos was absolutely incredible, and to this day I see people recommend it organically online with some frequency, which is the greatest compliment you could ask for when it comes to music gear.

Emily Hopkins not only did a whole video on it, she awarded us the _prestigious_ Emma award in the flanger category!

<iframe class="youtube" src="https://www.youtube.com/embed/5N04Emjlp5w?si=Gjxw-jogmo2kCGHs&amp;start=1906" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

<iframe class="youtube" src="https://www.youtube.com/embed/G_RfWj7B2jg?si=dFFeAtg-s9lLodvO&amp;start=1906" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

Some of my favorite demo artists made some incredible videos featuring it.

<iframe class="youtube" src="https://www.youtube.com/embed/Vzgq9KX6bx4?si=SWqs2-QGqPRAU_aL" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

<iframe class="youtube" src="https://www.youtube.com/embed/AOEJnaBRrIE?si=uaNObp_L2dpskrmg" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

<iframe class="youtube" src="https://www.youtube.com/embed/u7kVn8_bqDw?si=EjadHNGr65sClGUo" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

<iframe class="youtube" src="https://www.youtube.com/embed/wjQDZUdExT8?si=aR-lMh63lPC7ObMK" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

## Thanks

I want to thank Alec for taking a chance on me and for being an amazing collaborator!

This is the kind of project that would take one person a very long time, and being able to lean into our (very complimentary) core competencies made this something it never would have been otherwise.

Here's to more projects together in the future!
