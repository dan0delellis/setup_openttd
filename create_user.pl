#!/usr/bin/perl
use Getopt::Long;
use Data::Dumper;
use Storable qw ( freeze  );
use MIME::Base64;

#makes it easier to determine relative paths
my $gitroot = `git rev-parse --show-toplevel`; chomp $gitroot;

#source of words
my $dict = "/usr/share/dict/words";

my ($skel_path, $user, $shell) = ("$gitroot/skel", "openttd", "/bin/bash");
my ($home_path, $no_pw,$no_skel,$system,$no_shell,$system_user,$password);

my @useradd_opts = qw/useradd/;

#hashref with username, path for ~, password, or if it's a system user which isn't yet supported
my %x;
my $user_data = \%x;

GetOptions (
    "skel-path=s"   => \$skel_path,
    "username=s"    => \$user,
    "shell=s"       => \$shell,
    "home-path=s"   => \$home_path,
    "system-user!"  => \$system_user,
    "no-shell!"     => \$no_shell,
    "no-password!"  => \$no_pw,
    "no-skeleton!"  => \$no_skel,
) or die("Error in command line arguments\n");

if ($password && $no_pw) {
#not going to try to decide which takes precedence. script dies. the end.
    die "You cannot specify a password and set --no-password.\n";
}

push @useradd_opts, $user;
$user_data->{'username'} = $user;

if ($system) {
#don't have support for this yet
    $no_pw = 1;
    $no_skel = 1;
    $no_shell = 1;
    push @useradd_opts, "--system";
} else {
    push @useradd_opts, "-m";

    if ($home_path) {
    #There's no reason to do this really, but power to the user. If you're doing this, I'm assuming you know what you're doing
        push @useradd_opts, ("-d", $home_path);
        $user_data->{'home_directory'} = $home_path;
    } else {
        $user_data->{'home_direcotry'} = "/home/$user";
    }
}

unless($no_pw) {
    my $openssl_installed = `dpkg-query --show -f'\${Version}' openssl`;
    my $openssl_version = `dpkg --compare-versions $openssl_installed ge 1.1.1`;
    if ($?) {
        die "You must install a version of openssl >= 1.1.1\n" .
        "If you are trying to install this on a distro that doesn't have that as a candidate I don't want to get my fingerprints on that trainwreck\n";
    }
    my $salt = hungry_for_words(1);
    #cursed
    $salt = pop @$salt; chomp $salt;
    unless ($password) {
        $password = hungry_for_words(3);


        $password = join(" ", @$password); chomp $password;

        #get rid of apostrophes
        $password =~ s/[^a-zA-Z ]//g;
        $password = lc $password;
    }
    $user_data->{'password'} = $password;

    my $hash = `openssl passwd -6 -salt $salt  \"$password\"`;
    if ($?) {
        die "Failed to execute 'openssl passwd -6 -salt <secret>  \"<secret>\"': $!\n";
    }
    chomp $hash;
    push @useradd_opts, ("-p", "'$hash'");
}

unless($no_skel) {
#skeleton data isn't critical, but it does make it easier to pre-configure the server before it starts
    push @useradd_opts, ("-k", $skel_path);
}

unless($no_shell) {
#I honestly don't know yet if openttd can run in a noshell env, but it's easier to ignore useless options than it is to retroactively add them
    push @useradd_opts, ("-s", $shell);
}

`@useradd_opts`;
if ($rv) {
    $err = $!;
    my $cmd = join(" ", @userad_opts);
    #"you should remove the hash from the command" Eh it failed.
    die "Failed to Execute '$cmd': $!\n";
} else {
    $dat = encode_base64 freeze($user_data);
    print $dat;
}

sub hungry_for_words {
    my ($count) = @_;
    unless($count) {
        $count=3;
    }
    unless ( -s $dict ) {
        die "You must either provide a password with --password or install the package 'wamerican', or any one of the following packages:\n" .
        "\twamerican-huge wamerican-insane wamerican-large wamerican-small\n" .
        "\twbritish wbritish-huge wbritish-insane wbritish-large wbritish-small\n" .
        "\twcanadian wcanadian-huge wcanadian-insane wcanadian-large wcanadian-small\n" .
        "\twbrazilian wbulgarian wcatalan wdanish wdutch wesperanto wfaroese wfrench wgalician-minimos wgerman-medical witalian wngerman wnorwegian wogerman wpolish wportuguese wspanish wswedish wswiss wukrainian\n";
    }

    #"Why don't you just use '[^a-z]'?" In the pbuilder I'm using to write this, grep includes accented vowels in a-z,
    #potentially generating passwords that are impossible to type with a standard US keyboard.
    my @tmp = `egrep -v "[^qwertyuiopasdfghjklzxcvbnm]" $dict | shuf -n$count`;

    return \@tmp;
}
