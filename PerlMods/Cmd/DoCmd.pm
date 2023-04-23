#!/usr/bin/perl
package DoCmd;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(do_cmd $gitroot);

sub do_cmd {
    my ($cmd) = @_;
    my @rt = `$cmd 2>&1`;
    my $rv = $?;

    return ($rv, \@rt);
}

our $gitroot;
my $x;
($x,$gitroot) = do_cmd("git rev-parse --show-toplevel");
$gitroot = pop @$gitroot; chomp $gitroot;

1;
