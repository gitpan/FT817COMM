use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Ham::Device::FT817COMM',
    AUTHOR           => q{Jordan Rubin <jrubin@cpan.org>},
    VERSION_FROM     => 'lib/Ham/Device/FT817COMM.pm',
    ABSTRACT_FROM    => 'lib/Ham/Device/FT817COMM.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Ham-Device-FT817COMM-*' },
);
