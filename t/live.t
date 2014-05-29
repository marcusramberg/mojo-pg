use Mojo::Base -strict;

use Test::More;
use Mojo::Pg;

plan skip_all => "Must set PG_DSN to enable live testing"
  unless $ENV{MOJO_PG_DSN};

subtest '"do" roundtrip' => sub {
  my $pg = Mojo::Pg->new(dsn => $ENV{MOJO_PG_DSN});

  my $lines;
  Mojo::IOLoop->delay(
    sub {
      $pg->get_handle(shift->begin);
    },
    sub {
      my ($delay, $handle) = @_;
      $handle->do('SELECT 5', $delay->begin);
    },
    sub {
      my $delay = shift;
      $lines = shift;
      Mojo::IOLoop->stop;
    }
  );
  Mojo::IOLoop->start;
  ok $lines, 'we did something';
};

subtest '"prepare" => roundtrip' => sub {
  my $pg = Mojo::Pg->new(dsn => $ENV{MOJO_PG_DSN});

  my ($res, $lines);
  Mojo::IOLoop->delay(
    sub {
      $pg->get_handle(shift->begin);
    },
    sub {
      my ($delay, $handle) = @_;
      $handle->prepare('SELECT 2');
      $handle->execute($delay->begin(0));
    },
    sub {
      my ($delay, $handle) = (shift, shift);
      $lines = shift;
      $res = $handle->sth->fetchall_arrayref;
      Mojo::IOLoop->stop;
    }
  );
  Mojo::IOLoop->start;

  ok $lines, 'we did something';
  is_deeply $res, [[2]];
};

subtest 'Syntax error' => sub {
  my $pg = Mojo::Pg->new(dsn => $ENV{MOJO_PG_DSN});

  my $err;
  Mojo::IOLoop->delay(
    sub {
      $pg->get_handle(shift->begin);
    },
    sub {
      my ($delay, $handle) = @_;
      $handle->prepare('SELCT 1', {RaiseError => 1});
      $handle->execute($delay->begin(0));
    },
    sub {
      my $delay = shift;
      $err = shift->dbh->err;
      Mojo::IOLoop->stop;
    }
  );
  Mojo::IOLoop->start;
  ok $err, 'we have an error';
};

done_testing;
