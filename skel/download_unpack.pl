#!/usr/bin/perl
use strict;
use warnings;
#use lib qw (PerlMods);
use SetupOpenTTD::Shortcuts qw(hungry_for_words do_cmd_topline do_cmd_silent do_cmd do_cmd);
use Storable qw ( freeze );
use MIME::Base64;
use Data::Dumper;
use Getopt::Long;

my $base_url = "https://www.openttd.org/downloads/";
my $latest_url = $base_url . "openttd-releases/latest";

#hashref to put stuff we care about. At this point, it will be the archive urls, the extracted path of the game, and the path of the executable
my $return_data;
my $debug;
my $home =          $ENV{HOME};
my $archive_regex = "openttd-[0-9\.]+-linux-generic";
my $gfx_regex =     "opengfx-[0-9\.]+-all.[a-zA-Z]+";
my $bin_curl =      "/usr/bin/curl -s -f ";
my $bin_wget =      "/usr/bin/wget -q ";
my $install_dir =   "$home/.";
my $config_root =   "$home/.config/openttd";
my $conf_game =     "$config_root/openttd.cfg";
my $conf_secret =   "$config_root/secrets.cfg";
my $conf_private =  "$config_root/private.cfg";
my $template_suf =  "orig";

my ($archive_url, $latest_gfx, $gfx_url, $game_path, $gfx_path);
my ($archive_fname, $gfx_fname);

my ($SERVER_NAME, $SERVER_PASSWORD, $CLIENT_NAME);

#Local archives so I don't abuse server resources
#$archive_url="http://10.1.0.4/openttd-13.1-linux-generic-amd64.tar.xz";
#$gfx_url="http://10.1.0.4/opengfx-7.1-all.zip";

#GetOptions() goes here;

unless (defined $SERVER_PASSWORD) {
    $SERVER_PASSWORD = hungry_for_words(3,25);
}
unless (defined $SERVER_NAME) {
    $SERVER_NAME = "The " . hungry_for_words(2) . " OpenTTD Server";
    $SERVER_NAME =~ s/(\w+\S+\w*)/\u$1/g;
}
unless (defined $CLIENT_NAME) {
    $CLIENT_NAME = "admin " . hungry_for_words(1);
    $CLIENT_NAME =~ s/(\w+\S+\w*)/\u$1/g;
}

$return_data->{server_name} = $SERVER_NAME;
$return_data->{server_password} = $SERVER_PASSWORD;
$return_data->{client_name} = $CLIENT_NAME;

my $target_dir = do_cmd_topline("realpath $install_dir");

my $workdir = do_cmd_topline("mktemp -d");

unless($archive_url && $gfx_url) {
    my $cmd = "$bin_curl $latest_url";
    my ($rv,$res) = do_cmd($cmd);

    foreach my $line (@$res) {
        chomp $line;
        #Find url for archive, and the graphics url while we're at it
        next unless ($line =~ m/opengfx/ || $line =~ m/filename/ && $line =~ m/linux/);
        #string manipulation for fun and profit
        $line = extract_url($line);

        if ($line =~ m/opengfx/) {
            #hey cool we found where the graphics can be downloaed
            $line =~ s/\.\.\//$base_url/;

            #for some stupid reason the .html is not a valid url
            $line =~ s/\.[a-z]+$//;
            $latest_gfx = $line;
            $gfx_url = get_archive($latest_gfx,$gfx_regex)
        }
        if ($line =~ m/$archive_regex/) {
            $archive_url = $line;
            next
        }
    }
}
die "Unable to find downloadable URLs for game and/or graphics pack\n" unless($archive_url && $gfx_url);

$archive_fname = get_fname($archive_url);
$gfx_fname = get_fname($gfx_url);

$return_data->{game_url} = $archive_url;
$return_data->{game_archive} = $archive_fname;
$return_data->{gfx_url} = $gfx_url;
$return_data->{gfx_archive} = $gfx_fname;

pull_file($archive_url,$archive_fname);
pull_file($gfx_url, $gfx_fname);

unless ( -e "$workdir/$archive_fname" || -e $archive_fname) {
    die "Failed to download openttd archive. download manually here and run script again\n";
}

unless ( -e "$workdir/$gfx_fname" || -e $gfx_fname ) {
    die "Failed to download opengfx archive. download manually here and run script again\n";
}

foreach my $file($archive_fname,$gfx_fname) {
    unpack_file($file);
}
#source diretory for graphics packs, since it's way easiwer to just do this than to try and compile it with headless support
(my $gfx_data = "$workdir/$gfx_fname") =~ s/-all.*$//g;

#master directory for game data. will house the executable and be the target for symlinks
(my $game_dir = $archive_fname) =~ s/^(.+-amd64).*$/\/$1\//;
$game_path = "$workdir/$game_dir";

#target directory for graphics data
$gfx_path = "$game_path/baseset/";

print "Copying graphics data into game path...\n" if $debug;
do_cmd_silent("ln $gfx_data/* $gfx_path/.");

print "Moving game data to target location\n" if $debug;
do_cmd_silent("mv $game_path $target_dir");

$return_data->{extract_path} = $target_dir . $game_dir;
$return_data->{game_path} = do_cmd_topline("find $return_data->{extract_path} -type f -executable");

first_run($return_data->{game_path});

make_config($conf_game);
make_config($conf_secret);
make_config($conf_private);

print "Cleaning up\n" if $debug;
do_cmd_silent("rm -rf $workdir");
print "All Done!\n" if $debug;
my $dat = encode_base64 freeze($return_data);
print $dat;

sub unpack_file {
    my ($f) = @_;
    $f = "$workdir/$f";


    print "Unpacking file $f....\n" if $debug ;
    if ($f =~ m/\.tar(\.[a-z]+)?$/) {
        do_cmd_silent("tar xf $f -C $workdir");
        return
    }
    if ($f =~ m/\.zip$/) {
        my ($not_tarred, $out) = do_cmd("unzip -l $f | egrep -q '\.tar\$'");
        if (!$not_tarred) {
            print "oh boy it's a hidden tarball\n" if $debug;
            do_cmd_silent("unzip -p $f | tar x -C $workdir");
            die "$!" if $?;
        } else {
            do_cmd_silent("unzip $f -d $workdir");
        }
        return
    }
    if ($f =~ m/\.xz$/) {
        (my $x = $f) =~ s/\.xz$//;
        do_cmd_silent("unxz $f -c $workdir/$x");
        return
    }
}

sub pull_file {
    my ($url,$fname) = @_;
    print "downloading $url to $fname\n" if $debug;
    unless (-s $fname ) {
        do_cmd_silent("$bin_wget $url -P $workdir");
        die "$! exit code $?" if $?;
    } else {
        print "File already exists. skipping. delete ./$fname if invalid\n" if $debug;
    }
}

sub get_fname {
    my ($url) = @_;
    chomp $url;
    my @parts = split(/\//,$url);
    my $fname = pop @parts;
    chomp $fname;
    return $fname;
}

sub extract_url {
    my ($line) = @_;
    $line =~ s/.+<a href="(.+)".+/$1/;
    chomp $line;
    return $line;
}

sub get_archive {
    my ($url,$regex) = @_;
    my ($rv,$data) = do_cmd("$bin_curl $url");
    foreach my $line (@$data) {
        if ($line =~ m/https:\/\/.+$regex/) {
            $line = extract_url ($line);
            chomp $line;
            return $line;
        }
    }
}

sub make_config {
    my ($conf) = @_;

    my $template = "$conf.$template_suf";
    my ($rv,$out) = do_cmd("mv $conf $template");

    unless (-f $template) {
        die "$template is not an extant file\n";
    }

    if ($conf =~ m/openttd\.cfg$/) {
        return
    }

    open (my $src, "<", $template) or die "Unable to open template file $template: $!. Won't be able to generate config $conf.\n";
    open (my $FH, ">", $conf) or die "Unable to create config file $conf: $!\n";

    while (my $line = <$src>) {
        $line =~ s/^(server_password)\s+(=.*)$/$1 = $SERVER_PASSWORD/;
        $line =~ s/^(server_name)\s+(=.*)$/$1 = $SERVER_NAME/;
        $line =~ s/^(client_name)\s+(=.*)$/$1 = $CLIENT_NAME/;

        print $FH $line
    }
    close ($src);
    close($FH);
    chmod 0644, $conf;
}

#First run allows the first the default config files to get generated, that way they don't need to be included in the repo
sub first_run {
    print "Executing first run to generate configs. Should have an exit code of 124\n" if $debug;
    my ($binary) = @_;
    unless (-x $binary) {
        return;
    }
    my $rv = do_cmd_silent("timeout 2 $binary -D");
}
