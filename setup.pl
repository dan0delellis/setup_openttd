#!/usr/bin/perl

use warnings;
use Getopt::Long;
use Data::Dumper;
use Storable qw ( thaw freeze );
use MIME::Base64;
use SetupOpenTTD::Shortcuts qw(do_cmd_silent);
#makes it easier to determine relative paths

die "Must run as root\n" unless ($> == 0);

my $gitroot = `git rev-parse --show-toplevel`; chomp $gitroot;
my $cleanup=1;
my $shuffle_conf = "custom_options.cfg";
#hashrefs for returned data from scripts
my ($user_data,$unpack_data);

cleanup_old() if ($cleanup);
install_module();

$user_data = setup_user();
$unpack_data = download_unpack();
my %conf_data = (
    username    => $user_data->{username},
    user_home   => $user_data->{home_directory},
    exe_path    => $unpack_data->{game_path},
    run_path    => $unpack_data->{extract_path},
    deploy_source => "$gitroot/deploy",
);

my $conf_base64 = encode_base64 freeze(\%conf_data);

generate_system_conf($conf_base64);

finish();


sub install_module {
    #Check to see if it's installed already
    if (eval { require SetupOpenTTD::Shortcuts; 1 }) {
        return
    }

    my $path = "$gitroot/PerlMods";
    my $script = "$path/install.sh";
    my $mod_path = "$path/SetupOpenTTD-Shortcuts/lib/SetupOpenTTD/";
    my $rt = `$script`;
    if ($?) {
        die "Error trying to install perl modules this project relies on. Try installing it as desribed in $mod_path/README and running again"
    }
}

sub cleanup_old {
    my @cmds = (
	"killall -u openttd",
        "userdel -r openttd",
        "rm /etc/systemd/system/openttd*.service",
        "systemctl daemon-reload",
        "rm -rf /etc/default/opentt.d",
        "rm /usr/local/bin/generate_seed.sh"
    );

    foreach my $cmd (@cmds) {
        do_cmd_silent($cmd);
    }
}

sub setup_user {
    my $x=`$gitroot/create_user.pl`;
    if ($?) {
	print Dumper "got exit code $?, $!";
        die "Failed to execute user creation script: $!\n";
    }
    my $y =  thaw (decode_base64 $x ) ;
    #make a symlink for the config in current users's home
    do_cmd_silent("ln -fs $y->{home_directory}/$shuffle_conf ~/.");
    return $y;
}

sub download_unpack {
    my $cmd = "$user_data->{home_directory}/download_unpack.pl";

    my $y = `su $user_data->{username} -c "$cmd"`;
    if ($?) {
        die "Failed to run '$cmd': $!\n";
    }
    $y = thaw (decode_base64 $y);
    return $y;
}

sub generate_system_conf {
    my ($opt_data) = @_;
    my $cmd = "$gitroot/deploy_system_files.pl --base64 '$opt_data'";
    do_cmd_silent($cmd);
}

sub finish {
    print "Setup Complete!\n";
    print "Created User: $user_data->{username}\n";
    print "Password: \'$user_data->{password}\'. You can change it to your liking by running 'passwd $user_data->{username}'\n";
    print "Unpacked to: $user_data->{home_directory}\n";
    print "Server Name: \'$unpack_data->{server_name}\'. It can be changed by editing \'~$user_data->{username}/.config/openttd/private.cfg\' before starting the game\n";
    print "Server Password: \'$unpack_data->{server_password}\'. It can be changed by editing \'~$user_data->{username}/.conf/openttd/secrets.cfg\' before starting the game\n";
    print "Name of Local Client: \'$unpack_data->{client_name}\'. It can be changed by editing \'~$user_data->{username}/.conf/openttd/private.cfg\' before starting the game\n";

    print "\n";
    print "You can customize the server options by editing ~/$shuffle_conf, which is a symlink to $user_data->{home_directory}/$shuffle_conf\n";
    print "Start the server by executing 'sudo systemctl start openttd-dedicated.service'!\n";
    print "Have fun!\n";
}
