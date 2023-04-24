#!/usr/bin/perl

use strict;
use warnings;
use SetupOpenTTD::Shortcuts qw(do_cmd do_cmd_topline);
use Getopt::Long;
use Data::Dumper;
use Storable qw ( thaw freeze );
use MIME::Base64;

die "Must run as root\n" unless ($> == 0);

my $bin_root        = "usr/local/bin/";
my $seed_script     = "$bin_root/generate_seed.sh";
my $options_script  = "$bin_root/shuffle_settings.pl";
my $def_seed        = "etc/default/opentt.d/openttd.seed";
my $def_opt         = "etc/default/opentt.d/openttd.options";
my $def_cli         = "etc/default/opentt.d/openttd.cli";
my $tmp_systemd     = "etc/systemd/system/openttd-dedicated.service.template";
my $defaults_path   = "/etc/default/opentt.d/";
my $dict            = "/usr/share/dict/words";

my $enc_data;

my ($deploy_root,$USER,$EXECUTABLE_PATH,$GAME_INSTALL,$USER_HOME);
my ($SERVER_PASSWORD, $CLIENT_NAME, $SERVER_NAME);
GetOptions (
    "deploy-root=s"     => \$deploy_root,
    "username=s"        => \$USER,
    "executable-path=s" => \$EXECUTABLE_PATH,
    "game-install=s"    => \$GAME_INSTALL,
    "base64=s"          => \$enc_data,
) or die("Error in command line arguments\n");

my $conf;

#If called from setup.pl, $conf will be a base64 data block that decodes/thaws to a hash
if ($enc_data) {
    $conf = thaw (decode_base64 ($enc_data));
    $deploy_root = $conf->{deploy_source};
    $USER = $conf->{username};
    $GAME_INSTALL  = $conf->{run_path};
    $EXECUTABLE_PATH = $conf->{exe_path};
    $USER_HOME = $conf->{user_home};
}

die "Unable to determine template file location\n" unless $deploy_root;
die "Unable to determine user to run service as\n" unless $USER;
die "Unable to determine location of game executable\n" unless $EXECUTABLE_PATH;
die "Unable to determine game install directory\n" unless $GAME_INSTALL;

my @cmds;

my ($gen_file, $target) = generate_systemd($tmp_systemd,$deploy_root);
push @cmds, "mv $gen_file /$target";

#copy files in place
push @cmds, "mkdir $defaults_path";

#defaults files

#Write the location of the shuffled config file to a defaults file
set_cli_opts("$deploy_root", "$def_cli");

push @cmds, "cp $deploy_root/$def_seed /$def_seed";
push @cmds, "cp $deploy_root/$def_opt /$def_opt";
push @cmds, "cp $deploy_root/$def_cli /$def_cli";

#seed generator pre-exec script
push @cmds, "cp $deploy_root/$seed_script /$seed_script";
push @cmds, "cp $deploy_root/$options_script /$options_script";
push @cmds, "/$seed_script";

#systemd reload
push @cmds, "systemctl daemon-reload";

foreach my $cmd (@cmds) {
    my ($rv,$rt) = do_cmd($cmd);
    if ($rv) {
        print Dumper $rt;
    }
}

sub set_cli_opts {
    my ($src, $fn) = @_;
    my $tmp = do_cmd_topline("mktemp");
    open (my $ro, "<", "$src/$fn") or die "Unable to open \"$src/$fn to make defaults file:$!\n";
    open (my $FH, ">", "$tmp") or die "Unable to open defaults file $fn: $!\n";
    while (my $line = <$ro>) {
        $line =~ s/<USER_HOME>/$USER_HOME/;
        print $FH $line;
    }
    close $ro;
    close $FH;
    return $tmp;
}

sub generate_systemd {
    my ($unit, $root) = @_;
    (my $target = $unit) =~ s/.template//;
    my $tmp = do_cmd_topline("mktemp");
    open (my $FH, ">", $tmp) or die "Unable to open temporary file for writes: $!\n";
    open (my $src, "<", "$root/$unit") or die "Unable to open systemd template file for reads: $!\n";

    while (my $line = <$src>) {
        $line =~ s/<USER>/$USER/;
        $line =~ s/<GAME_INSTALL>/$GAME_INSTALL/;
        $line =~ s/<EXECUTABLE_PATH>/$EXECUTABLE_PATH/;

        print $FH $line;
    }
    close $FH;
    chmod 0644, $tmp;
    close $src;
    return ($tmp, $target);
}
