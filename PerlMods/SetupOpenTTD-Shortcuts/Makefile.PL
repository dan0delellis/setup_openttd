use 5.022001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SetupOpenTTD::Shortcuts',
    VERSION_FROM      => 'lib/SetupOpenTTD/Shortcuts.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/SetupOpenTTD/Shortcuts.pm', # retrieve abstract from module
    AUTHOR            => 'dan <dan@>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
);
