---
title: How I deploy my services
published_at: 3/15/26 8:37
tags: linux, web
---

Early on in my journey to self-host this website I had to figure out how to deploy it.
The desired workflow was similar to what I'd use with Heroku, where deployment is done by a `git push` to the remote.

Most tooling targeted at this use-case is overkill for [this application](/projects/website), which runs as a single executable and only consumes static data from files and a SQLite database.
There's lots of container-centric options that make more sense for servers with many dependencies.
Plenty of CI/CD solutions with reverse proxies and no-downtime deploys.
The amount of YAML you can throw at this problem is unprecedented.

Maybe I'll need some of that stuff one day.
Until then, I wanted to make use of the tooling already available in Linux.

What I've settled on here is a minimum viable solution for running fairly self-contained services in a Linux environment.
It's nothing groundbreaking, but requires some tinkering that may be non-obvious unless you're already a hardened Linux veteran.

## Overview

At a high level, we're going to:

- Create a bare git repo with a hook to check out and build the app when pushed to
- Create a systemd service for our app
- Configure some permissions stuff

For the sake of simplicity, some of the file paths, users, and permissions will be left as an exercise to the reader.
These aren't difficult to figure out and will probably be something you have an opinion about anyways!

## Creating the git repo

In order for our server to become a remote we can push to, we need to create a new bare git repo on the server:

```sh
git init --bare website.git
```

Bare git repos store only the underlying git data structures and are just the `.git/` directory portion of a normal git repo.

With proper SSH access we can now add our server as a remote:

```sh
# make sure everything after the : is the path to your bare git repo!
git remote add prod username@hostname:website.git
git push prod main
```

## Running the app

The code now technically exists on our remote, but we need to actually check out a copy to get access to the underlying files:

```sh
git --work-tree=website --git-dir=website.git checkout -f
```

We can now `cd` into the `website/` directory and install any dependencies needed to run the app.
I'd recommend trying it once manually to make sure everything properly.

With the power of [systemd](https://systemd.io), we can set up our app as a "service" that runs in the background and is started automatically when the computer reboots.

To do this, we need to create a config file defining the service in `/etc/systemd/system/website.service`:

```
[Unit]
Description=Website!
After=network.target

[Service]
User=www-data
Type=simple
Restart=always
WorkingDirectory=/wherever/you/put/your/stuff


# Configure any environment variables needed to run here!
Environment="FOO=bar"

ExecStart=path/to/binary/you/want/to/run

[Install]
WantedBy=multi-user.target
```

Breaking this down, we're telling systemd the following:

- Run the command given in `ExecStart`
  - After the network interface is online
  - As a specific user (use an account with limited permissions)
  - In the directory defined in `WorkingDirectory`
- Whenever the computer boots, start this service

If all goes well we can manually start it and enable the service:

```sh
sudo systemctl start website
sudo systemctl enable website
```

### Restarting without sudo

The service exists and runs, but we need to be able to restart the app when new changes are pushed up without running `systemctl` commands as root.

This is exactly the kind of task [Polkit](https://en.wikipedia.org/wiki/Polkit) is designed for, and through it we can allow our personal user to restart the website service without elevated permissions:

Add the following to `/usr/share/polkit-1/rules.d/10-website.rules`:

```js

polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
                action.lookup("unit") == "website.service" &&
                subject.user == "your_user_goes_here") {
                return polkit.Result.YES;
        }
});
```

Now we can restart the Polkit service so the new changes are picked up:

```sh
sudo systemctl restart polkit
```

## Responding to git push

With all of the initial configuration out of the way, we can get to the meat of how this works: the `post-receive` git hook.
This script is run whenever new changes are received by our bare git repo, and it gives us a convenient place to kick off any compilation/preparation tasks then restart our service.

Create the git hook inside the bare git repo: `website.git/hooks/post-receive` and add some bash:

```bash
#!/bin/bash

set -e

git --work-tree=/home/your_user_goes_here/website --git-dir=/home/your_user_goes_here/website.git checkout -f
cd /home/your_user_goes_here/website/service

# Add any commands needed to build and run your app here

/usr/bin/systemctl restart website
```

Make sure to `chmod +x` the git hook!

From your local machine, try doing a git push to this remote again; you should see shell output from whatever build processes you added, and the service will restart with your changes.

## Caveats

This is not a no-downtime approach to deployments, nor is it a great way to manage applications with many intertwined dependencies.
Those things could be achievable with more convoluted systemd incantations and some sort of A/B deploy script, but at that point it might make sense to reach for one of the many containerized solutions.

For our simple (mostly static) website a few seconds of downtime is tolerable to the point of being unnoticed.
Using a CDN with decently long cache times gives me a lot of room to take things down for several minutes at a time if needed.
