package Mojo::Pg;
use Mojo::Base -base;
use strict;

use DBI;
use DBD::Pg ':async';
use Mojo::IOLoop;
use IO::Handle;

has [qw/dsn username password/] => '';
has options => sub { {} };

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

has 'sth';

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

    my $pg=Mojo::Pg->new(dsn=>'dbname:joel');
    $pg->prepare('SELECT * FROM foo');
    $pg->execute(sub {
      my ($res,$err)=@_;

=head1 DESCRIPTION

=head1 METHODS

=cut
