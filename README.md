# setup_openttd
scripts to automatically set up an openttd server

I am not in any way associated with the people who develop openttd. This is not intended to be a fork of their work, or included with it, or anything along those lines. It's just a collection of scripts I wrote to push what I knew about perl a bit further.

# About
At this point it will work exclusively in debian-like distributions that use systemd.
Want to use it in Windows or Mac? Good news! kvm, proxmox, virtualbox, et. al. are all free ways to run a virtual machine with little to no overhead in practically any OS.

My intention is to make virtually every aspect of the install configurable from the command line, but I wanted to get something shipped because I've spent like 3 weeks on a program that effectively downloads and unpacks a couple zip archives.

For now, the setup script creates a user `openttd` (with a random 3-word password), downloads the latest versions of openttd and a graphics pack, and sets up a server with a name like 'The (Random) (Random) OpenTTD Server', another 3-word random password, and names the client '(Random) Admin'.

It binds to 0.0.0.0:3979, so be careful if you are running this on a server that is exposed to the internet.

# Dependencies
As mentioned above, it needs to be some kind of debian-like distribution. Installing the packages listed in the `required` file might make things go smoother, but I am pretty sure those are standard in any Debian OS you can download.

# Setup
You should never ever run scripts you've downloaded off the internet as root, but that's exactly what you have do here.

That's the disclaimer. It's a terrible idea for anyone to use this.

If one were to run `sudo perl setup.pl`, the script would hopefully everything will download, unpack, and deploy as expected. I did 99% of the development in a debian `sid` pbuilder environment, so it mostly relies on standard perl modules, kernel functions, and standard-ish bash programs.

Once setup is complete, one would be greeted with a message that looks like this:
```
Setup Complete!
Created User: openttd
Password: 'snugs desiccated phantasied'. You can change it to your liking by running 'passwd openttd'
Unpacked to: /home/openttd
Server Name: 'The Disillusioning Ads OpenTTD Server'. It can be changed by editing '~openttd/.config/openttd/private.cfg' before starting the game
Server Password: 'brewed cavemen divvying'. It can be changed by editing '~openttd/.conf/openttd/secrets.cfg' before starting the game
Name of Local Client: 'Admin Reunified'. It can be changed by editing '~openttd/.conf/openttd/private.cfg' before starting the game

Start the server by executing 'sudo systemctl start openttd-dedicated.service'!
Have fun!
```
But you will never see this screen, because it's a bad idea to use this script.

I'd suggest running `/usr/local/bin/generate_seed.sh` before starting the server, because I'm just now remembering that I never added a thing to regenerate the seed on setup. Right now it defaults to max(uint32).

## Configuration
It's hypothetically posisble to run the individual scripts with various CLI arguments to pre-configure the install, but it's not something I would recommend.

You have multiple options for server settings.

Command line options that the server runs as can be edited in `/etc/default/opentt.d/`. This way you don't have to mess with systemd to change server settings.
Config files the game relies on live under `~openttd/.config/openttd/`.

The game does have an admin interface that I know nothing about. Right now I'd only suggest inviting people you trust to servers set up with this unless you're familiar with the interface

## Issues
I am EXTREMELY unfamiliar with OpenTTD. I wrote this because I got annoyed at the fact that I had to manually extract archives to exactly the right locations. If you're a sysadmin, you'd understand.

Right now, only the individual subscripts are cofigurable. I'd like to make it so that setup.pl can take args and pass them to subscripts so that any aspect can be configured from the command line. But this started as a script to literally just 'download and unpack these archives' and then ballooned into a master's thesis in bad perl practices.

## To Do
* Restart the game on some schedule. Every Sunday night will likely be the default
* Shuffle game settings on game start
* Wipe savegames on game shuffle
* Consolidate common commands into modules. I have like 50 different instances of do_cmd()
* Make it detect the git root from outside the git repo
