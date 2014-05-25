use 5.010001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojo::Pg',
  VERSION_FROM => 'lib/Mojo/Pg.pm',
  ABSTRACT     => 'Real-time web framework',
  AUTHOR       => 'Joel Berger <joel.a.berger@gmail.com>',
  LICENSE      => 'artistic_2',
  META_MERGE   => {
    requires => {
      perl        => '5.010001',
      Mojolicious => '1.0',
      ' DBD::Pg
    ' => ' 0 '
    },
    resources => {
      license => ' http
  : // www
    . opensource
    . org / licenses / artistic-license
    - 2.0 ',
    },
    no_index => {directory => [' t ']}
  },
  test => {TESTS => ' t /*.t t/ * /*.t'}
);
