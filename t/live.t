use Mojo::Base -strict;

use Test::More;
use Mojo::Pg;

plan skip_all => "Must set PG_DSN to enable live testing"
  unless $ENV{MOJO_PG_DSN};

subtest '"do" roundtrip' => sub {
  my $pg = Mojo::Pg->new(dsn => $ENV{MOJO_PG_DSN});

  $pg->prepare('SELECT 2');

  my $lines;
  $pg->do('SELECT 5',
    sub {
      shift;
      $lines = shift;
      Mojo::IOLoop->stop;
    }
  );
  Mojo::IOLoop->start;
  ok $lines, 'we did something';
};

subtest '"prepare" => roundtrip' => sub {
  my $pg = Mojo::Pg->new(dsn => $ENV{MOJO_PG_DSN});

  $pg->prepare('SELECT 2');

  my ($res, $lines);
  $pg->execute(
    sub {
      my $self = shift;
      $lines = shift;
      $res = $self->sth->fetchall_arrayref;
      Mojo::IOLoop->stop;
    }
  );
  Mojo::IOLoop->start;

  ok $lines, 'we did something';
  is_deeply $res, [[2]];
};

subtest 'Syntax error' => sub {
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
