#!/usr/bin/perl
use Getopt::Long;
use Data::Dumper;
use Storable qw ( thaw  );
use MIME::Base64;
#makes it easier to determine relative paths
my $gitroot = `git rev-parse --show-toplevel`; chomp $gitroot;

#hashrefs for returned data from scripts
my ($user_data,$unpack_data);


cleanup_old();

$user_data = setup_user();
$unpack_data = download_unpack();
generate_system_conf();


finish();

sub cleanup_old {
    `userdel -r openttd 2> /dev/null`;
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



sub finish {
    print "Setup Complete!\n";
    print "Unpacked to: $user_data->{home_directory}\n";
    print "Created User: $user_data->{username}\n";
    print "Password: \'$user_data->{password}\'\n";
}
