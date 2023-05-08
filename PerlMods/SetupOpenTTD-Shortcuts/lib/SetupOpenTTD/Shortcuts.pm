#!/usr/bin/perl

package SetupOpenTTD;
package SetupOpenTTD::Shortcuts;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(do_cmd $gitroot do_cmd_silent do_cmd_stdout do_cmd_topline hungry_for_words contains);

sub contains {
    my ($arr, $str) = @_;
    chomp $str;
    foreach my $e (@$arr) {
        chomp $e;
        if ($str =~ m/^$e$/) {
            return 1;
        }
    }
    return 0;
}

sub do_cmd {
    my ($cmd) = @_;
    my @rt = `$cmd 2>&1`;
    my $rv = $?;

    return ($rv, \@rt);
}

sub do_cmd_stdout {
    my ($cmd) = @_;
    my ($rv,$rt) = do_cmd($cmd);
    $rt = join("",@$rt); chomp $rt;
    return $rt;
}

sub do_cmd_topline {
    my ($cmd) = @_;
    my ($rv,$rt) = do_cmd($cmd);
    $rt = shift(@$rt);
    chomp $rt;
    return $rt;
}

sub do_cmd_silent {
    my ($cmd) = @_;
    my ($rv) = do_cmd("$cmd >/dev/null 2>&1");
    return $rv;
}

our $gitroot;
my $x;
($x,$gitroot) = do_cmd("git rev-parse --show-toplevel");
$gitroot = pop @$gitroot; chomp $gitroot;

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
