#!/bin/bash

#This script is a pre-exec script to generate data for an EnvironmentFile that is read by a systemd service
#I'm sure systemd has functionality to generate random numbers, but configuring systemd is a pain if you're unfamiliar.
#Making it read the seed to use from a file, instead of directly in the unit file, makes it easier to configure the options
#Sure, you could let the game pick a random seed, but this allows you to see the seed easily. If the seed is awesome, you can hardcode it


#systemd reads this file to get the seed to use for world generation
#the world seed can any integer in the range [0,2^32 - 1]
SEED_ENV_FILE="/etc/default/openttd.seed"

echo "#This was generated with $0" > $SEED_ENV_FILE 

#od is an octal dumper. This command reads 4 bytes (32 bits) from /dev/urandom and outputs them as a Double
#there are easier ways to do this, like perl -e 'print int(rand((2**32)-1))', but this has MY NAME IN THE CLI
SEED=$(/usr/bin/od --read-bytes=4 /dev/urandom -DAn)

#If you want a constant SEED, set it below in place of $SEED. 
#Or just comment out this line and put the seed in the other ENV file
echo "CLI_SEED=\"dashG $SEED\"" >> $SEED_ENV_FILE
