use Mojo::Base -strict;

use Test::More;
use Mojo::Pg;

plan skip_all => "Must set PG_DSN to enable live testing"
  unless $ENV{MOJO_PG_DSN};

subtest '"do" roundtrip' => sub {
  my $pg = Mojo::Pg->new(dsn => $ENV{MOJO_PG_DSN});
  $pg->add_handle;
  is @{ $pg->handles }, 1, 'have one available handle';

  my ($lines, $available);
  Mojo::IOLoop->delay(
    sub {
      $pg->get_handle(shift->begin);
    },
    sub {
      my ($delay, $handle) = @_;
      $available = @{ $pg->handles };
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
  is $available, 0, 'handle unavailable when in use';
  is @{ $pg->handles }, 1, 'have one available handle when done';
};

subtest '"prepare" roundtrip' => sub {
  my $pg = Mojo::Pg->new(dsn => $ENV{MOJO_PG_DSN});
  $pg->add_handle;

  my ($res, $lines, $err);
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
      $err = $handle->dbh->err;
      Mojo::IOLoop->stop;
    }
  );
  Mojo::IOLoop->start;

  ok $lines, 'we did something';
  is_deeply $res, [[2]];
  ok !$err, 'no error';
};

subtest 'Syntax error' => sub {
  my $pg = Mojo::Pg->new(
    dsn     => $ENV{MOJO_PG_DSN}, 
    options => {RaiseError => 0, PrintError=>0},
  );
  $pg->add_handle;

  my $err;
  Mojo::IOLoop->delay(
    sub {
      $pg->get_handle(shift->begin);
    },
    sub {
      my ($delay, $handle) = @_;
      $handle->prepare('SELCT 1');
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

