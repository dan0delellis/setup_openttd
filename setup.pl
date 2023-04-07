#!/usr/bin/perl
use Getopt::Long;
use Data::Dumper;
use Storable qw ( thaw  );
use MIME::Base64;

`userdel -r openttd`;

#makes it easier to determine relative paths
my $gitroot = `git rev-parse --show-toplevel`; chomp $gitroot;

my $x=`$gitroot/create_user.pl`;
if ($rv) {
    die "Failed to execute user creation script: $!\n";
}
my $user_data =  thaw (decode_base64 $x ) ;
my $cmd = "$user_data->{home_directory}/download_unpack.pl";

my @y = `su $user_data->{username} -c "$cmd"`;
if ($rv) {
    die "Failed to run '$cmd': $!\n";
}

print "Setup Complete!\n";
print "Unpacked to: $user_data->{home_directory}\n";
print "UserName: $user_data->{username}\n";
print "Password: \'$user_data->{password}\'\n";

