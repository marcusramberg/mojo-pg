use Mojo::Base -strict;

use Test::More;
use Mojo::Pg;

plan skip_all => "Must set PG_DSN to enable live testing" unless $ENV{MOJO_PG_DSN};
my $pg = Mojo::Pg->new(dsn => $ENV{MOJO_PG_DSN});

$pg->prepare('SELECT 2');

my $res;
$pg->execute(
  sub {
    $res = shift->sth->fetchall_arrayref;
    Mojo::IOLoop->stop;
  }
);
Mojo::IOLoop->start;

is_deeply $res, [[2]];

done_testing;

