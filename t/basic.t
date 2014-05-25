use Test::More;

use_ok 'Mojo::Pg';
my $pg = Mojo::Pg->new;
can_ok($pg, 'dbh');

done_testing;
