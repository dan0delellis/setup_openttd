#!/usr/bin/perl
package Passwd;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(hungry_for_words);

my $dict = "/usr/share/dict/words";

sub hungry_for_words {
    my ($count) = @_;
    unless($count) {
        $count=3;
    }
    unless ( -s $dict ) {
        die "You must install the package 'wamerican', or any one of the following packages:\n" .
        "\twamerican-huge wamerican-insane wamerican-large wamerican-small\n" .
        "\twbritish wbritish-huge wbritish-insane wbritish-large wbritish-small\n" .
        "\twcanadian wcanadian-huge wcanadian-insane wcanadian-large wcanadian-small\n";
    }

    #"Why don't you just use '[^a-z]'?" In the pbuilder I'm using to write this, grep includes accented vowels in a-z,
    #potentially generating passwords that are impossible to type with a standard US keyboard.
    my @tmp = `egrep -v "[^qwertyuiopasdfghjklzxcvbnm]" $dict | shuf -n$count`;

    $words = join (" ", @tmp);
    $words =~ s/[\s]+/ /g;
    $words =~ s/(^\s+|\s+$)//g;
    chomp $words;
    $words = lc $words;

    return $words;
}
1;
