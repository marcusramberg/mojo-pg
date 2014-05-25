package Mojo::Pg;
use Mojo::Base -base;

our $VERSION = '0.01';

use DBI;
use DBD::Pg ':async';
use Mojo::Pg::Pool;

has [qw/dsn username password/] => '';
has options => sub { {} };

has 'pool' => sub { Mojo::Pg::Pool->new }; 

sub build_handle {
  my $self = shift;
  return DBI->connect(
    'dbi:Pg:' . $self->dsn, $self->username,
    $self->password,        $self->options
  );
};

=head1 NAME

Mojo::Pg - ASync PostgreSQL using the Mojo IOLoop

=head1 SYNOPSIS

    my $pg=Mojo::Pg->new(dsn=>'dbname=joel');
    $pg->prepare('SELECT * FROM foo');
    $pg->execute(sub {
      my ($res,$err)=@_;
    });

=head1 DESCRIPTION

Wrap DBD::Pg to run async queries inside the Mojo::IOLoop.

=head1 ATTRIBUTES

=head2 dsn

The dsn, excluding the 'dbd:Pg:' part 
   dsn => 'dbname=wat'

=head2 username

Your database username

=head2 password

Your database password

=head2 options

Options to DBI

=head2 dbh

The DBI database handle

=head1 METHODS

=head2 cancel

  $pg->cancel;

Cancel the current async query

=head2 status

  my $status = $pg->status;

Return the status of the current async query. See L<DBD::Pg/pg_async_status>.

=head2 do

  $pg->do($statement, \%attr, @params, sub { my ($pg, $res) = @_; ... });

Execute a statement directly. Takes optional hash of attributes, and binding paramenters.
Calls the callback with this object and the same result as C<do> would have returned
(number of lines).

=head2 prepare

  $pg->prepare($query, \%attr);

Prepare an SQL statement

=head2 execute

  $pg->execute(@params, sub { my ($pg, $res) = @_; ... });

Execute the above prepared SQL statment, Calls the callback with this object
and the same result as C<execute> would have returned (number of lines).

=cut
