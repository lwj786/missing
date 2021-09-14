#! /usr/bin/env perl

use strict;

use File::Path;


chomp(my $credential_helper = qx / git config --global credential.helper /);

sub END { qx / git config --global credential.helper "$credential_helper" / };
for (qw / INT TERM /) { $SIG{$_} = \&END };

qx / git config --global credential.helper cache /;


my ($from, $to);
while (<>)
{
    chomp;

    $from = s/#\s*from\s*=\s*//r if /^#\s*from\s*=\s*.*/;
    $to = s/#\s*to\s*=\s*//r if /^#\s*to\s*=\s*.*/;

    if (/^#/ or /^\s*$/ or not (length $from and length $to)) {
        next;
    }

    my $f = "$from/$_.git";
    my $t = "$to/$_.git";

    rmtree "$_.git";
    qx / git clone --bare $f /;
    $? and next;

    if (chdir "$_.git") {
        if (open(my $c, ">>", "config")) {
            print $c "[remote \"to\"]\n\turl = $t\n";
            close($c);

            qx /
                git push --all to;
                git push --tags to;
            /;
        }

        chdir "..";
    }

    rmtree "$_.git";
}
