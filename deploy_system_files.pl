#!/usr/bin/perl

use Getopt::Long;
use Data::Dumper;
use Storable qw ( thaw freeze );
use MIME::Base64;

die "Must run as root\n" unless ($> == 0);

my $seed_script = "/usr/local/bin/generate_seed.sh";
my $def_seed = "/etc/default/openttd.seed";
my $def_opt = "/etc/default/openttd.options";
my $tmp_systemd = "/etc/systemd/system/openttd-dedicated.service.template";
my $defaults_path = "/etc/default/opentt.d";

my $enc_data;

my ($deploy_root,$USER,$EXECUTABLE_PATH,$GAME_INSTALL);

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
}

die "Unable to determine template file location\n" unless $deploy_root;
die "Unable to determine user to run service as\n" unless $USER;
die "Unable to determine location of game executable\n" unless $EXECUTABLE_PATH;
die "Unable to determine game install directory\n" unless $GAME_INSTALL;

my ($gen_file, $target) = generate_systemd($tmp_systemd,$deploy_root);

#copy files in place
`mkdir $defaults_path`
`mv $gen_file $target`;

`mv $def_seed $defaults_path/.`;
`mv $def_opt $defaults_path/.`;

#systemd reload
`systemctl daemon-reload`;

sub generate_systemd {
    my ($unit, $root) = @_;
    (my $target = $unit) =~ s/.template//;
    my $tmp = `mktemp`; chomp $tmp;
    open (my $FH, ">", $tmp) or die "Unable to open temporary file for writes: $!\n";
    open (my $src, "<", "$root/$unit") or die "Unable to open systemd template file for reads: $!\n";

    while (my $line = <$src>) {
        $line =~ s/<USER>/$USER/;
        $line =~ s/<GAME_INSTALL>/$GAME_INSTALL/;
        $line =~ s/<EXECUTABLE_PATH>/$EXECUTABLE_PATH/;

        print $FH $line;
        print Dumper $line;
    }
    close $FH;
    close $src;
    return ($tmp, $target);
}
