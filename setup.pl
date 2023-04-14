#!/usr/bin/perl
use Getopt::Long;
use Data::Dumper;
use Storable qw ( thaw freeze );
use MIME::Base64;
#makes it easier to determine relative paths

die "Must run as root\n" unless ($> == 0);

my $gitroot = `git rev-parse --show-toplevel`; chomp $gitroot;

#hashrefs for returned data from scripts
my ($user_data,$unpack_data);


cleanup_old();

$user_data = setup_user();
$unpack_data = download_unpack();

my %conf_data = (
    username    => $user_data->{username},
    exe_path    => $unpack_data->{game_path},
    run_path    => $unpack_data->{extract_path},
    deploy_source => "$gitroot/deploy",
);

my $conf_base64 = encode_base64 freeze(\%conf_data);

generate_system_conf($conf_base64);


finish();

sub cleanup_old {
    my @cmds = (
        "userdel -r openttd",
        "rm /etc/systemd/system/openttd*.service",
        "systemctl daemon-reload",
        "rm -rf /etc/default/opentt.d",
        "rm /usr/local/bin/generate_seed.sh"
    );

    foreach my $cmd (@cmds) {
        run_cmd_silent($cmd);
    }
}

sub setup_user {
    my $x=`$gitroot/create_user.pl`;
    if ($rv) {
        die "Failed to execute user creation script: $!\n";
    }
    $x =  thaw (decode_base64 $x ) ;
    return $x;
}

sub download_unpack {
    my $cmd = "$user_data->{home_directory}/download_unpack.pl";

    my $y = `su $user_data->{username} -c "$cmd"`;
    if ($rv) {
        die "Failed to run '$cmd': $!\n";
    }
    $y = thaw (decode_base64 $y);
    return $y;
}

sub generate_system_conf {
    my ($opt_data) = @_;
    my $cmd = "$gitroot/deploy_system_files.pl --base64 '$opt_data'";
    `$cmd`;
}

sub finish {
    print "Setup Complete!\n";
    print "Unpacked to: $user_data->{home_directory}\n";
    print "Created User: $user_data->{username}\n";
    print "Password: \'$user_data->{password}\'\n";
}

sub run_cmd_silent {
    my ($c) = @_;
    `$c 2> /dev/null`;
}
