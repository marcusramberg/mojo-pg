package Mojo::Pg::Handle;

use Mojo::Base -base;
use Mojo::IOLoop;
use IO::Handle;
use DBD::Pg ':async';

has [qw/dbh pool sth/];

sub do {
  my ($self, $statement) = (shift, shift);
  my $cb   = pop;
  my $attr = shift || {};
  $attr->{pg_async} = PG_ASYNC;
  $self->dbh->do($statement, $attr, @_);
  $self->_watch($cb);
}

sub prepare {
  my ($self, $query, $attr) = @_;
  $attr ||= {};
  $attr->{pg_async} = PG_ASYNC;
  $self->sth($self->dbh->prepare($query, $attr))->sth;
}

sub execute {
  my $self = shift;
  my $cb   = pop;
  $self->sth->execute(@_);
  $self->_watch($cb);
}

sub _watch {
  my ($self, $cb) = @_;
  my $dbh    = $self->dbh;
  my $socket = IO::Handle->new_from_fd($dbh->{pg_socket}, 'r');
  Mojo::IOLoop->singleton->reactor->io(
    $socket => sub {
      my ($reactor, $writable) = @_;
      return unless $dbh->pg_ready;
      $reactor->remove($socket);
      $self->$cb($dbh->pg_result, $self->sth);
    }
  );
}

sub cancel { shift->dbh->pg_cancel }

sub status { shift->dbh->{pg_async_status} }

sub DESTROY {
  my $self = shift;
  my $pool = $self->pool;
  return unless $pool;
  $pool->add_handle(delete $self->{dbh});
}

1;


=head1 NAME

Mojo::Pg::Handle - Handles used by Mojo::Pg

=head1 SYNOPSIS

    my $pg=Mojo::Pg::Handle->new(dbh => $dbh);
    $pg->prepare('SELECT * FROM foo');
    $pg->execute(sub {
      my ($res,$err)=@_;
    });

=head1 DESCRIPTION

Wrap DBD::Pg to run async queries inside the Mojo::IOLoop.

=head1 ATTRIBUTES

=head2 dbh

The DBI database handle

=head2 pool

A reference to the connection pool. Usually weakened.

=head2 sth

The current statement handle. Will be replaced by running prepare.

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
