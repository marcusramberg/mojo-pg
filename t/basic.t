use Test::More;

use_ok 'Mojo::Pg';
my $pg = Mojo::Pg->new;
can_ok($pg, 'dbh');

use DDP;
my $pg
  = Mojo::Pg->new(dsn => 'dbname=joel,host=localhost', username => 'joel');

$pg->prepare('SELECT * FROM foo');
$pg->execute(
  sub {
    my $res = shift->sth->fetchall_arrayref;
    p $res;
    Mojo::IOLoop->stop;
  }
);

Mojo::IOLoop->recurring(0.5 => sub { say $pg->status });

Mojo::IOLoop->start;


done_testing;
