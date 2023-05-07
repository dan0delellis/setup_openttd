#!/bin/bash
h2xs -AX -n SetupOpenTTD::Shortcuts -b 5.22.1 -O && cp SetupOpenTTD/Shortcuts.pm SetupOpenTTD-Shortcuts/lib/SetupOpenTTD/. && sudo ./install.sh
