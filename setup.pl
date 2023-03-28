#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

my $debug = 1;
my $base_url = "https://www.openttd.org/downloads/";
my $latest_url = $base_url . "openttd-releases/latest";

my $game_path;
my $gfx_path;

my $archive_regex = "openttd-[0-9\.]+-linux-generic";
my $gfx_regex = "opengfx-[0-9\.]+-all.[a-zA-Z]+";
my $bin_curl = "/usr/bin/curl -s -f ";

my ($archive_url, $latest_gfx, $gfx_url);

my $cmd = "$bin_curl $latest_url";
my @res = do_cmd($cmd);
my $rv = $?;
if ($rv) {
    die "failed to execute `$cmd`\n";
}

foreach my $line (@res) {
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

my $archive_fname = get_fname($archive_url);
my $gfx_fname = get_fname($gfx_url);

pull_file($archive_url,$archive_fname);
pull_file($gfx_url, $gfx_fname);

unless (-e $archive_fname) {
    die "Failed to download openttd archive. download manually here and run script again\n";
}

unless (-e $gfx_fname) {
    die "Failed to download opengfx archive. download manually here and run script again\n";
}

foreach my $file($archive_fname,$gfx_fname) {
    unpack_file($file);
}

#source diretory for graphics packs, since it's way easiwer to just do this than to try and compile it with headless support
(my $gfx_data = $gfx_fname) =~ s/-all.*$//g;

#master directory for game data. will house the executable and be the target for symlinks
($game_path = $archive_fname) =~ s/^(.+-amd64).*$/~\/$1\//;

#target directory for graphics data
$gfx_path = $game_path . "baseset/";

print "Linking graphics data into game path...\n";
`ln -s $gfx_data\* $gfx_path\.`;


sub unpack_file {
    my ($f) = @_;

    print "Unpacking file $f....\n"    ;
    if ($f =~ m/\.tar(\.[a-z]+)?$/) {
        `tar xf $f`;
        return
    }
    if ($f =~ m/\.zip$/) {
        my $not_tarred = `unzip -l $f | egrep -q '\.tar\$'`;
        if (!$not_tarred) {
            print "oh boy it's a hidden tarball\n";
            `unzip -p $f | tar x `;
        } else {
            `unzip $f`;
        }
        return
    }
    if ($f =~ m/\.xz/) {
        `unxz $f`;
        return
    }

}

sub pull_file {
    my ($url,$fname) = @_;
    print "downloading $url to $fname\n";
    unless (-s $fname ) {
        `wget $url -O $fname`;
    } else {
        print "File already exists. skipping. delete ./$fname if invalid\n";
    }
}

sub get_fname {
    my ($url) = @_;
    my @parts = split(/\//,$url);
    my $fname = pop @parts;
    chomp $fname;
    return $fname;
}

sub yell {
    my ($msg) = @_;
    print Dumper $msg if $debug;
}

sub do_cmd {
    my ($cmd) = @_;
    my @res = `$cmd`;
    my $rv = $?;
    if ($rv) {
            die "failed to execute `$cmd`\n";
    }
    return @res;
}

sub extract_url {
    my ($line) = @_;
    $line =~ s/.+<a href="(.+)".+/$1/;
    return $line;
}

sub get_archive {
    my ($url,$regex) = @_;
    my @data = `$bin_curl $url`;
    foreach my $line (@data) {
        if ($line =~ m/https:\/\/.+$regex/) {
            $line = extract_url ($line);
            return $line;
        }
    }
}
