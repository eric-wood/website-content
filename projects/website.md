---
title: This Website
published_at: 3/6/26 12:00
tags: web, rust
---

## Eric, online

### The early days

When I was first starting high school I asked my dad how websites worked; he showed me I could right click and "view source" on any webpage, sending me down a rabbit hole I have yet to emerge from.
Since then, I've had some form of personal website.
They've taken many forms; early ones had all of the trappings of a classic Geocities page, usually hosted on whatever sketchy free hosting service I could find with a web editor (crucial for being able to tinker with it from locked down school computers).
Each iteration was more complex than the last as I honed my CSS, JS, and overall design skills.
Hours were spent experimenting, refining, and cursing the browser wars.

In college I bought this domain name (all of the other good TLDs with my name were taken) and continued the tradition.
As my career path guided me more and more towards working on the web, the iterations of this site have become more of a resume and any aspirations of hosting dynamic content were abandoned in the face of reality: I was busy!

### Another iteration

Fast forward to September 2025: I've just become a father!
My paternity leave was full of responsibility and purpose, but between feeds and naps and making sure my wife was comfortable I had a surprising amount of down-time spent nearby, ready to jump into action at a moment's notice.
I really needed a project; something already in my wheelhouse I could hack away with minimal mental context switching overhead.
Something I could have a little bit of control over as I submitted myself to the process of raising a newborn.
Something that was fun and comforting.

Time for a new website.

### Guiding principles

Taking everything I've learned from past websites, both as a producer and consumer, I settled on a few ground rules for this iteration:

#### Simple

This is a passion project meant to occupy my rapidly vanishing free time.
Maintenance should be relatively effortless after the initial setup, and while I aim to design a resilient system, the goal is not five 9's of uptime.

#### Self-hosted

I've been burnt more times than I can count by hosting providers.
Platforms come and go, and sometimes they claw back previously cheap or free tiers as the economics change.

This website is meant to be a reflection of me, and I want to have full self-determination for how it's built down to the hosting layer.
The resources required to keep it online are minimal, and a one-time cost of a cheap/free server will allow me to operate it in perpetuity using commodity hardware.

#### Alive

Unlike my past websites, I want this one to feel like a living, breathing entity that rewards repeat visits.
Even if visitors never return, the entire experience feels different when there's recent content.

Publishing content requires a time investment, which is increasingly tough to with a kid in the picture.
If I rely solely on publishing blog posts, the whole endeavour is a non-starter and doomed to languish like every other website I've built.
Success hinges on lowering the activation energy requires to publish, and having content streams beyond low-frequency high-effort ones like blog posts.

The site should tie together all things Eric from the source, which means building automations into the apps and tools I'm already using, and when necessary building them to make the updating process easier.
There should be a clear value add for having something published to the site, too, e.g. if I share photos being able to give people access to the full-resolution images (a rare feature on most photography sharing websites).

## How it all works

So here's what I've built.
I'm really happy with the results, and excited to keep adding more features and tinkering with the ones I've already built.
As any reflection of me should be, it's an imperfect system that's constantly improving.

### Hardware

Everything is powered by a single Lenovo ThinkCentre packing an i5 processor and 8GB of RAM running Debian Linux.
I got it for next to nothing on Ebay from a seller that configures the hardware to your specs, but odds are you can find these for free from office or school liquidations locally.
I bought it mostly because the form factor is nice and tiny and it's cute.

TODO: pic of server

These are popular Linux targets it turns out, so everything works out of the box with minimal fiddling.
Mine is special in that it's the only Linux machine I have ever set up in my life where Wifi worked out of the box but wired ethernet would no work no matter what I tried.
After wasting a lot of time on debugging it I've chalked it up to a freak accident on my specific motherboard and opted to grab a USB to ethernet dongle instead, which looks stupid but works great.
Waste not, want not.

### Networking

Exposing a server to the public from a dynamic home IP is usually ill-advised unless you know what you're doing.
I mostly know what I'm doing, but I don't want to bear the responsibility of defending my poor little server from the big bad internet, especially in the age of out of control LLM crawlers.

To sidestep all of this, I opted to use [Cloudflare's tunnel product](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/).
It's free, somehow, and runs a daemon that tunnels (valid) requests from the open internet to destinations on my server.
They manage the DNS for me, and setting up new subdomains and routes is effortless while keeping me from having to mess with my own reverse proxy to route everything.

Having a CDN in front of my site helps me sleep peacefully at night knowing a good chunk of malicious actors are being filtered out and any sudden spikes in popularity are handled without taxing my limited hardware.
Everything is set to cache aggressively, and in the event of extended downtime Cloudflare will serve my site from historic backups via [archive.org](https://archive.org).

I've also set up [Tailscale](https://tailscale.com) so I can (safely) access it from anywhere without having to expose SSH to the outside world.

### Software

The site itself is built entirely in Rust with a small web "framework" I've pieced together on top of [axum](https://github.com/tokio-rs/axum).
It loosely follows an MVC-style architecture inspired by Rails, but is very explicit and Rust-y at its core.
Previously to starting this project I'd written a lot of Rust, but purely in `no_std` embedded environments without a heap.
As the breadth of the site expands, I'm excited to do more with the underlying framework and remove some of the boilerplate necessary right now (which will mean some macros and other fun stuff!).

The pages themselves are as lightweight as possible, with the CSS and JS required to render any given view inlined into the page itself and generous caching headers applied to almost every response.
Wherever possible, I lean on the web platform itself, and little snippets of JS are purely additive to the experience whenever possible.

#### Photos

Building this section of the site is what originally piqued my interest in the project; I'd been getting deep into photography and was starting to accumulate a body of work I was really proud of and wanted to share.
Social media websites make a mess of displaying photos in different aspect ratios (Instagram especially!) and apply lossy compression, while dedicated photography sites gate important features behind subscriptions.
I wanted control over how my artwork was presented to the world, and a novel system that let people explore my work.

I manage all of my photos in the Apple Photos app, and the photos destined for the website all live in an album.
Periodically, a [tool I built](https://tangled.org/ericwood.org/photo-album-extractor) on top of the amazing [osxphotos](https://github.com/RhetTbull/osxphotos) library runs and extracts all of the photos from that album into a directory on my computer. Select metadata (including tags automatically applied by Apple's machine learning algorithms) for the photos gets pulled into a SQLite database and thumbnails are created. The resulting directory is then `rsync`'d to the server and the app is restarted.

The site works off of the SQLite database when showing the gallery, and is able to efficiently query for unions of different tags, handle pagination, and anything else I dream up in the future. Rendering a gallery of images with different aspect ratios wasn't possible in pure CSS (well, until the masonry stuff is more widely supported), and required building an algorithmic layout to pack each row, which I will write an entire blog post on in the near future.

This has worked beautifully in practice, as I can go about managing my photo library as I would anyways and select a handful of photos from each roll to share with the world without extra steps.
It's easy for me to link people to individual photos without re-uploading them everywhere, and they get to see the full, unadulterated image.
The tag system has been really fun, and I regularly find myself looking back at old photos on the site using it.

#### Blog/projects
