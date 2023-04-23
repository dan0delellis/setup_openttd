#!/usr/bin/perl
use strict;
use warnings;
use lib qw (PerlMods/Cmd);
use DoCmd qw(do_cmd);
use MIME::Base64;
use Data::Dumper;
use Getopt::Long;

my $user = "openttd";

my $defaults;
#The config file should be in ~ for the user executing the script
my $opts_file   = "~/custom_options.cfg";
my $template    = "~$user/.config/openttd/openttd.cfg.default";
my $target_file = "~$user/.config/openttd/openttd.cfg.shuffled";

GetOptions (
    "s|settings_file=s"     =>  \$opts_file,
    "t|template_config=s"   =>  \$template,
    "d|defaults!"           =>  \$defaults,
);

open (my $ro, "<", $template) or die "Unable to open template file. Can't generate the config:$!\n";
open (my $fh, "<", $target_file) or die "Unable to open target file. Can't generate the config:$!\n";

while (my $line=<>) {
    print Dumper $line;
}
