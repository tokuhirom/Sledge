package Sledge::Request::PSGI;
# $Id: CGI.pm,v 1.2 2004/02/23 09:19:13 miyagawa Exp $
#
# Tatsuhiko Miyagawa <miyagawa@edge.co.jp>
# Livin' On The EDGE, Co., Ltd..
#

use strict;
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(env query header_hash status body));

use vars qw($AUTOLOAD);

use Plack::Request;
use Sledge::Request::Table;
use Sledge::Request::PSGI::Upload;

sub new {
    my($class, $env) = @_;
    my $query = Plack::Request->new($env);
    bless { env => $env, query => $query, header_hash => {}, status => 200, body => [] }, $class;
}

sub header_out {
    my($self, $key, $value) = @_;
    $self->header_hash->{$key} = $value if @_ == 3;
    $self->header_hash->{$key};
}

sub headers_out {
    my $self = shift;
    return wantarray ? %{$self->header_hash}
	: Sledge::Request::Table->new($self->header_hash);
}

sub header_in {
    my($self, $key) = @_;
    $key =~ s/-/_/g;
    return $self->{env}->{"HTTP_" . uc($key)};
}

sub content_type {
    my($self, $type) = @_;
    $self->header_out('Content-Type' => $type);
}

sub send_http_header { }

sub finalize {
    my ($self) = @_;

    my %header = %{$self->{header_hash}};
    my @h;
    for my $key (keys %header) {
        if (ref $header{$key} eq 'ARRAY') {
            push @h, $key, $_ for @{$header{$key}};
        }
        else {
            push @h, $key, $header{$key};
        }
    }

    [$self->status, \@h, $self->body];
}

sub method {
    return $_[0]->env->{REQUEST_METHOD} || 'GET';
}

sub print {
    my $self = shift;
    push @{$self->{body}}, @_;
}

sub uri {
    # $REQUEST_URI - Query String
    my $uri = $_[0]->env->{REQUEST_URI};
    $uri =~ s/\?.*$//;
    return $uri;
}

sub args {
    return $_[0]->env->{QUERY_STRING};
}

sub upload {
    my $self = shift;
    Sledge::Request::PSGI::Upload->new($self, @_);
}

sub param {
    my $self = shift;

    # $r->param(foo => \@bar);
    if (@_ == 2 && ref($_[1]) eq 'ARRAY') {
	return $self->query->param($_[0], @{$_[1]});
    }
    $self->query->param(@_);
}

sub DESTROY { }

sub AUTOLOAD {
    my $self = shift;
    (my $meth = $AUTOLOAD) =~ s/.*:://;
    $self->query->$meth(@_);
}

1;
