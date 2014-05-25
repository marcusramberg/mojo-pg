package Mojo::Pg;
use Mojo::Base -base;

our $VERSION = '0.01';

use DBI;
use DBD::Pg ':async';
use Mojo::IOLoop;
use IO::Handle;

has [qw/dsn username password/] => '';
has options => sub { {} };
has 'sth';

has dbh => sub {
  my $self = shift;
  return DBI->connect(
    'dbi:Pg:' . $self->dsn, $self->username,
    $self->password,        $self->options
  );
};

has socket => sub {
  IO::Handle->new_from_fd(shift->dbh->{pg_socket}, 'r');
};

sub prepare {
  my ($self, $query) = @_;
  $self->sth($self->dbh->prepare($query, {pg_async => PG_ASYNC}))->sth;
}

sub execute {
  my $self = shift;
  my $cb   = pop;
  $self->sth->execute(@_);

  my $dbh    = $self->dbh;
  my $socket = $self->socket;

  Mojo::IOLoop->singleton->reactor->io(
    $socket => sub {
      my ($reactor, $writable) = @_;
      return unless $dbh->pg_ready;
      Mojo::IOLoop->singleton->reactor->remove($socket);
      $dbh->pg_result;
      $self->$cb;
    }
  );
}

sub status { shift->dbh->{pg_async_status} }

1;

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

=head2 status

Return the status of the current async query

=head2 prepare $query

Prepare an SQL statement

=head2 execute $cb

Execute the above prepared SQL statment, Calls $cb with this object. 

=cut
