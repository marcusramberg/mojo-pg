use Mojo::Base -strict;

use Test::More;
use Mojo::Pg;

plan skip_all => "Must set PG_DSN to enable live testing"
  unless $ENV{MOJO_PG_DSN};

{    #  Test basic roundtrip
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
};
{    #  Test syntax error
  my $pg = Mojo::Pg->new(dsn => $ENV{MOJO_PG_DSN});

  $pg->prepare('SELCT 1', {RaiseError => 1});

  my $err;
  $pg->execute(
    sub {
      $err = shift->dbh->err;
      Mojo::IOLoop->stop;
    }
  );
  Mojo::IOLoop->start;
  ok $err, 'we have an error';

};

done_testing;
