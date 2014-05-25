use Test::More;
plan skip_all => "Must set PG_DSN to enable live testing" unless $ENV{PG_DSN};
my $pg = Mojo::Pg->new(dsn => 'dbname=joel;host=localhost;port=5432',);

$pg->prepare('1');
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
