#!/bin/bash
WORKDIR=$(mktemp -d)
GITROOT=$(git rev-parse --show-toplevel)
if [ ! -d $WORKDIR ]; then
	exit 2
fi
(cd $GITROOT/PerlMods; cp -r SetupOpenTTD-Shortcuts $WORKDIR)
(cd $WORKDIR/SetupOpenTTD-Shortcuts; perl Makefile.PL; make ;make test && make install)
rm -rf $WORKDIR
