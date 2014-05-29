use Test::More;

use_ok 'Mojo::Pg::Handle';
my $pg = Mojo::Pg::Handle->new;
can_ok($pg, 'dbh');

done_testing;
