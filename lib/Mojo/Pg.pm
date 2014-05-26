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

sub do {
  my ($self, $statement) = (shift, shift);
  my $cb = pop;
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
  my $dbh = $self->dbh;
  my $socket = IO::Handle->new_from_fd($dbh->{pg_socket}, 'r');
  Mojo::IOLoop->singleton->reactor->io(
    $socket => sub {
      my ($reactor, $writable) = @_;
      return unless $dbh->pg_ready;
      $reactor->remove($socket);
      $self->$cb($dbh->pg_result);
    }
  );
}

sub cancel { shift->dbh->pg_cancel }

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

=head1 AUTHORS

Joel A. Berger C<jberger@cpan.org>
Marcus Ramberg C<mramberg@cpan.org>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014,  Joel A. Berger

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut


=cut
