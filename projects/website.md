---
title: This Website
published_at: 3/6/26 12:00
tags: web, rust
---

Personal websites have been a part of my life since I wrote my first HTML tag in middle school.
Early versions had all of the trappings of classic Geocities sites, complete with marquees and vivid colors.
Publishing something of my own on the internet was an intoxicating experience and quickly became an obsession.

The sites matured as my tastes and skills did, incorporating exciting new technologies like CSS and `XMLHttpRequest`.
My college internships had me working with web technologies more seriously, and my sites transitioned into portfolios.
As I entered the working world iterations were less frequent, with most updates happening when I'm looking for work or want to promote something new.

### Another iteration

September 2025 I became a father.

Being at home with a newborn as the non-birthing parent is an exciting, draining, and surprisingly quiet experience.
My contributions were fairly limited biologically, and while I was bearing great responsibility, there was a surprising amount of downtime spent in a hazy purgatory-like state.

Housebound (and a little rudderless, if I'm being honest), I found myself looking for a project.
I needed something rewarding, familiar, and low-stakes.
Something I could hack away on in the throes of sleep deprivation and chip away at between fatherly duties.

Time for a new website.

### Guiding principles

I wanted to do things a little differently this time.

My past sites had been a snapshot of me at a specific point in time; I'd given up on any notion of keeping an active blog or making frequent updates.
The most rewarding personal websites to stumble onto were ones that felt rich and alive, with an archive of interesting things to read and content to thumb through.
This version needed to capture some of that magic in a way that met me where I was—content should stream in from applications and tools I was already using, so updates would happen organically.

In an effort to wrestle back some control from the world of SaaS products I was going to do things the "hard way" and self-host it all.
Having a sandbox to play around in without worry of subscription pricing and changing terms felt right for something that was meant to be personal, and I'd be free to grow things however I wanted in the future.

## How it all works

So here's what I've built.
I'm really happy with the results, and excited to keep adding more features and tinkering with the ones I've already built.
Just like me, it's an imperfect system that's constantly improving.

### Hardware

Everything is powered by a single Lenovo ThinkCentre packing an i5 processor and 8GB of RAM running Debian Linux.
I got it for next to nothing on Ebay from a seller that configures the hardware to your specs, but odds are you can find these for free from office or school liquidations locally.
I bought it mostly because the form factor is nice and tiny and it's cute.

![the server, in all its glory](/content/assets/website/server.webp "See? It is cute.")

This is the first computer I've installed Linux on where the ethernet port doesn't work out of the box.
Many hours of debugging and I came to the conclusion there was a hardware issue with the motherboard itself, so it now sports a USB to ethernet dongle.

### Networking

Exposing a server to the public from a dynamic home IP is usually ill-advised unless you know what you're doing.
I mostly know what I'm doing, but I don't want to bear the responsibility of defending my poor little server from the big bad internet, especially in the age of out of control LLM crawlers.

To sidestep all of this, I opted to use [Cloudflare's tunnel product](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/).
It's free, somehow, and runs a daemon that tunnels (valid) requests from the open internet to destinations on my server.
They manage the DNS for me, and setting up new subdomains and routes is effortless while keeping me from having to mess with my own reverse proxy to route everything.

Having a CDN in front of my site throttles any load from sudden bursts in popularity, and relatively aggressive caching headers cut down on the load significantly.
During power outages or other downtime events the site will continue to stay up, albeit in a less capable fully static form.

I've also set up [Tailscale](https://tailscale.com) so I can (safely) access it from anywhere without having to expose SSH to the outside world.

### Software

The site itself is built entirely in Rust with a small web "framework" I've pieced together on top of [axum](https://github.com/tokio-rs/axum).
It loosely follows an MVC-style architecture inspired by Rails, but is very explicit and Rust-y at its core.
Despite having written a decent amount of embedded Rust, this was my first real foray into targeting a "real" computer with it, and having access to a heap was really fun!

As the scope of the project balloons with more features I hope to revisit all of this and apply more Rust knowledge.
There's more boilerplate required to add new routes and views than I'd like, and I want to see what I can accomplish with macros and dynamic dispatch.

The pages themselves are as lightweight as possible, with the CSS and JS required to render any given view inlined into the page itself and generous caching headers applied to almost every response.
Wherever possible, I lean on the web platform itself, and little snippets of JS are purely additive to the experience whenever possible.

The app itself runs as a systemd service I can update through git pushes.
[This blog post](/blog/deploying-services) has more details on how that aspect of it works.

#### Photos

Building this section of the site is what originally piqued my interest in the project; I'd been getting deep into photography and was starting to accumulate a body of work I was really proud of and wanted to share.
Social media websites make a mess of displaying photos in different aspect ratios (Instagram especially!) and apply lossy compression, while dedicated photography sites gate important features behind subscriptions.
I wanted control over how my artwork was presented to the world, and a novel system that let people explore my work.

I manage all of my photos in the Apple Photos app, and the photos destined for the website all live in an album.
Periodically, a [tool I built](https://tangled.org/ericwood.org/photo-album-extractor) on top of the amazing [osxphotos](https://github.com/RhetTbull/osxphotos) library runs and extracts all of the photos from that album into a directory on my computer. Select metadata (including tags automatically applied by Apple's machine learning algorithms) for the photos gets pulled into a SQLite database and thumbnails are created. The resulting directory is then `rsync`'d to the server and the app is restarted.

The site works off of the SQLite database when showing the gallery, and is able to efficiently query for unions of different tags, handle pagination, and anything else I dream up in the future. Rendering a gallery of images with different aspect ratios wasn't possible in pure CSS (well, until the masonry stuff is more widely supported), and required [building an algorithmic layout](/blog/photo-gallery) to pack each row.

This has worked beautifully in practice, as I can go about managing my photo library as I would anyways and select a handful of photos from each roll to share with the world without extra steps.
It's easy for me to link people to individual photos without re-uploading them everywhere, and they get to see the full, unadulterated image.
The tag system has been really fun, and I regularly find myself looking back at old photos on the site using it.

#### Blog/projects

Everything post-shaped on this website is powered by markdown files in a [separate repository](https://github.com/eric-wood/website-content).
On boot, the application runs through the different post types and extracts metadata from the frontmatter embedded in each file to build an in-memory data store used for rendering the index pages.

The contents of the pages themselves are rendered using the wonderful [Comrak](https://comrak.ee) crate, which I've tacked on some customizations to for extracting the table of contents shown on each page.
Because these pages are all extremely static and bounded, the application pre-renders them all as raw HTML files when it boots up in production mode.
It's maybe a bit of an over-optimization given the whole site is fronted by a CDN with aggressive caching, but it's a nice optimization that lets static content get served directly from disk.

#### Themes

I added these when I needed a break from writing all of the initial content for the site.
Themes are constructed from a foreground and background color set as [CSS custom properties](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Cascading_variables/Using_custom_properties); all interstitial colors are created with opacity using [`color-mix`](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/color_value/color-mix).
The currently selected theme gets persisted to local storage.

#### Music

Just like with the photos section, I want to share the music I'm creating and listening to directly from the apps I'm consuming it from.

I just don't know what that looks like yet.
Extracting a playlist from Apple Music to share on here doesn't allow me to write about why I love a song, and I need to spend more time thinking about how I want it all to work.

For now, the page is a placeholder, but it's something I plan on returning to once inspiration strikes.
