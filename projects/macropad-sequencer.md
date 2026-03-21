---
title: Macropad Sequencer
published_at: 1/12/26 12:00
tags: rust, embedded
---

[Project link](https://github.com/eric-wood/macropad-sequencer)

(Before reading make sure to go watch the video embedded in the project README)

## Backstory

Knowing I love to tinker, my sister got me this very cool [Adafruit macropad](https://www.adafruit.com/product/5128) for Christmas.
I was excited but a little ambivalent; development boards with cool peripherals are irresistible, but I worried it suffer the same fate as many of other projects gathering dust in my closet.
It couldn't hurt to make the LEDs blink at least, right?

Reveling in once again having time to myself in the wake of the holidays, I started hacking away.
Some future projects on my docket would demand more complex embedded work, and I was looking to try out new concepts I'd learned for working with [Embassy](https://embassy.dev) in a risk-free environment.

Eventually I had to pull myself away and move on to more important things, but the end result is fun and I'm overall pretty happy with how it was built.

## Highlights

There's nothing groundbreaking going on here; for most of the more complex peripherals I was able to leverage the amazing embedded Rust ecosystem and found an [embedded-graphics](https://github.com/embedded-graphics/embedded-graphics) crate for the specific display driver chip used, as well as a crate for the single-wire SPI protocol the daisy chained RGB LEDs beneath each key use.
I got to use a built-in PIO program for the rotary encoder, and Embassy's USB stack didn't take much wrangling to speak USB MIDI.

### Embassy tasks

My main focus was how to structure the underlying Embassy tasks and UI for as much flexibility as possible.

I'd been given the following advice by more experienced Embassy users that roughly boiled down to:

- Have each input and output owned by its own Embassy task
- Pass messages from these tasks to a central coordination task

Most input tasks are sitting idle and consume no CPU; each button, for example, is stuck in an `await` fired by a hardware-level interrupt and it makes sense to have a pool of these tasks with one task per key.
Input tasks do little more than respond to stimulus and fire off a message to the central controls task.

The bulk of the logic behind the UI is a single task that waits for messages on a channel.
Incoming messages are an enum of different types of control events that are matched against.
State information is local to this task, and outputs are updated by sending messages to the relevant output tasks.

In practice this worked exceptionally well; the core business logic for the UI lives in one place, and there's almost no global mutable state.
Inputs are dealt with in the order they arrive, and outputs that require multiple async steps (e.g. writing to the display) happen out of band without blocking.
This made implementing the non-trivial modal UI required by the sequencer a breeze, and future additions can be slotted into place without rethinking the entire architecture.

### Menu system

I think I spent more time on this than any other part of the project, honestly.
Menus are difficult: they're heterogeneous collections of different control types, hold state, respond to inputs, and report value changes.

The vision I had for the menu code involved being able to statically define each menu and its options as a single struct.
This turned into a whole adventure investigating different design methodologies before settling on the [final approach](https://github.com/eric-wood/macropad-sequencer/blob/main/src/menus/mod.rs).

Menus are built off of a top-level `Menu` struct with generics for the underlying state value as well as a dynamic function pointer to a callback for when the state is updated.
We don't have a heap, so individual menu items are stored as an array of dynamic pointers with a const genereric for the number of items, since they're known at compile time.

Each menu item is implemented as its own struct off of a `MenuItem` trait that defines a shared interface for rendering the menu, handling input, and reporting value changes.
For each rotary encoder step the active menu item is passed a step delta and mutable pointer to the overall value it can update.

Overall, I'm pretty happy with how this turned out, although I'd love to revisit it with some simple macros to make menu definitions more ergonomic, as there's still more boilerplate required than I'd like.

## Future additions

While I've moved on to other things now, I want to revisit this project to test out other ideas in the future.
The hardware isn't ideal for this application, but is a great opportunity to experiment with other concepts, such as:

- Measure "velocity" on the rotary encoder to make larger menus faster to navigate
- Add a synth engine using the second core and play it using the built-in speaker
- More complex computational stepping such as "swing" or step nudging
- Scrollable menus with more than 4 options
