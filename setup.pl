#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Storable qw ( thaw freeze );
use MIME::Base64;
#makes it easier to determine relative paths

die "Must run as root\n" unless ($> == 0);

my $gitroot = `git rev-parse --show-toplevel`; chomp $gitroot;
my $cleanup=1;
my $shuffle_conf = "custom_options.cfg";
my $grf_conf = "grf_options.cfg";
#hashrefs for returned data from scripts
my ($user_data,$unpack_data);

apt_install("$gitroot/required");
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
    addon_archive => "$gitroot/deploy/game_assets/addons.tar.gz",
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
	    "ps -u openttd && killall -u openttd",
        "grep -q openttd /etc/passwd && userdel -r openttd",
        "test -e /etc/systemd/system/openttd-dedicated.service && rm /etc/systemd/system/openttd-dedicated.service",
        "test -d /etc/default/opentt.d && rm -rf /etc/default/opentt.d",
        "test -f /usr/local/bin/generate_seed && rm /usr/local/bin/generate_seed.sh",
        "systemctl daemon-reload",
    );

    foreach my $cmd (@cmds) {
        run_cmd_silent($cmd);
    }
}

sub setup_user {
    my $x=`$gitroot/create_user.pl`;
    my $rv = $?;
    if ($rv) {
        die "Failed to execute user creation script: $!\n";
    }
    $x =  thaw (decode_base64 $x ) ;

    #make a symlink for the configs in current users's home
    #custom_options.cfg, grf_options.cfg get linked to ~/
    foreach my $conf ($shuffle_conf, $grf_conf) {
        unless (-e "$ENV{HOME}/$conf") {
            symlink("$x->{home_directory}/$conf", "$ENV{HOME}/$conf");
        }
    }
    return $x;
}

sub download_unpack {
    my $cmd = "$user_data->{home_directory}/download_unpack.pl";

    my $y = `su $user_data->{username} -c "$cmd"`;
    my $rv = $?;
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

sub apt_install {
    my ($apt_list) = @_;
    open (my $ro, "<", $apt_list) or die "Unable to open list of required programs: $apt_list\n";
    my @pkg_list;
    while (my $l=<$ro>) {
        my @line_list = split(/\s/, $l);
        push @pkg_list, @line_list;
    }
    close $ro;
    my $install_list = join(" ", @pkg_list);
    run_cmd_silent("apt install -y $install_list");
}

sub run_cmd_silent {
    my ($c) = @_;
    if ($c =~ m/(.*)&&(.*)/) {
        $c = "if ($1); then $2; fi";
    }


    `$c 2> /dev/null`;
    my $rv = $?;
    if ($rv) {
        die "failed `$c`. try running manually to see what's up\n";
    }
}
