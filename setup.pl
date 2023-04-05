#!/usr/bin/perl
use GetOpt::Long;
use Data::Dumper;

my $gitroot = `git rev-parse --show-toplevel`;
chomp $gitroot;
my ($password, $skel_path, $user, $shell, $home_dir, $no_home, $no_shell);

my @useradd_opts = qw/useradd/;

GetOptions (
    "password=s" => \$password,
    "skel-path=s"   => \$skel_path,
    "username=s"   => \$user,
    "homedir=s"   => \$home_dir,
    "no-home!"  => \$no_nome,
    "no-shell!"  => \$no_shell,
) or die("Error in command line arguments\n");

unless($password) {
    my @tmp = `shuf -n4 /usr/share/dict/words`;
    $password = join(" ", @tmp);
    $password =~ s/[^a-zA-Z ]//g;
    $password = lc $password;
}
print Dumper $password;
