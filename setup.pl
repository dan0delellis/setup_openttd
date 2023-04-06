#!/usr/bin/perl
use Getopt::Long;
use Data::Dumper;

my $gitroot = `git rev-parse --show-toplevel`; chomp $gitroot;
my $dict = "/usr/share/dict/words";

my ($skel_path, $user, $shell) = ("$gitroot/skel", "openttd", "/bin/bash");
my ($password, $no_pw,$no_skel,$system,$no_shell,$system_user);

my @useradd_opts = qw/useradd/;

my $user_opts;

GetOptions (
    "password=s" => \$password,
    "skel-path=s"   => \$skel_path,
    "username=s"   => \$user,
    "shell=s"      => \$shell,
    "system-user!" => \$system_user,
    "no-shell!"    => \$no_shell,
    "no-password!" => \$no_pw,
    "no-skeleton!" => \$no_skel,
) or die("Error in command line arguments\n");

push @useradd_opts, $user;

if ($system) {
    $no_pw = 1;
    $no_skel = 1;
    $no_shell = 1;
    push @useradd_opts, "--system";
}

unless($password || $no_pw) {
    my $openssl_installed = `dpkg-query --show -f'\${Version}' openssl`;
    my $openssl_version = `dpkg --compare-versions $openssl_installed ge 1.1.1`;
    if ($?) {
        die "You must install a version of openssl >= 1.1.1\n" .
        "If you are trying to install this on a distro that doesn't have that as a candidate I don't want to get my fingerprints on that trainwreck\n";
    }
    unless ( -s $dict ) {
        die "You must either provide a password with --password or install the package 'wamerican', or any one of the following packages:\n" .
        "\twamerican-huge wamerican-insane wamerican-large wamerican-small\n" .
        "\twbritish wbritish-huge wbritish-insane wbritish-large wbritish-small\n" .
        "\twcanadian wcanadian-huge wcanadian-insane wcanadian-large wcanadian-small\n" .
        "\twbrazilian wbulgarian wcatalan wdanish wdutch wesperanto wfaroese wfrench wgalician-minimos wgerman-medical witalian wngerman wnorwegian wogerman wpolish wportuguese wspanish wswedish wswiss wukrainian\n";
    }
    my @tmp = `egrep -v "[^qwertyuiopasdfghjklzxcvbnm]" $dict | shuf -n4`;
    my $salt = pop @tmp;
    chomp $salt;
    $password = join(" ", @tmp);
    $password =~ s/[^a-zA-Z ]//g;
    $password = lc $password;
    chomp $password;
    my $hash = `openssl passwd -6 -salt $salt  \"$password\"`;
    if ($?) {
        die "Failed to execute 'openssl passwd -6 -salt <secret>  \"<secret>\"': $!\n";
    }
    chomp $hash;
    push @useradd_opts, ("-p", "'$hash'");
}

unless($no_skel) {
    push @useradd_opts, ("-k", $skel_path);
}

unless($no_shell) {
    push @useradd_opts, ("-s", $shell);
}

`@useradd_opts`;
