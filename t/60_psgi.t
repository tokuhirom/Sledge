use strict;
use warnings;
use Plack::Test;
use Test::More tests => 1;

{
    package My::Config;
    use parent qw/Sledge::Config/;
    use vars qw($AUTOLOAD);

    our $Config = {
        COOKIE_NAME   => "sledge_sid",
        TMPL_PATH     => 't/template/',
        TMPL_ENCODING => 'utf-8'
    };

    sub new {
        my ( $class, $proto ) = @_;
        bless { pkg => ref $proto || $proto }, $class;
    }

    sub DESTROY { }

    sub AUTOLOAD {
        my $self = shift;
        my $pkg  = $self->{pkg};
        ( my $method = $AUTOLOAD ) =~ s/.*://;
        my $val = $Config->{ uc($method) };
        return ( ref($val) eq 'ARRAY' && wantarray ) ? @$val : $val;
    }
}

{
    package My::Page;
    use parent qw/Sledge::Pages::PSGI/;
    use Sledge::Authorizer::Null;
    use Sledge::SessionManager::Null;
    use Sledge::Charset::UTF8;
    use Sledge::Template::TT;
    sub create_authorizer { Sledge::Authorizer::Null->new }
    sub create_manager { Sledge::SessionManager::Null->new }
    sub create_charset { Sledge::Charset::UTF8->new }
    sub create_config { My::Config->new }

    sub dispatch_unicode { }
}

test_psgi app => sub {
    my $env = shift;
    My::Page->new($env)->dispatch('unicode');
  },
  client => sub {
    my $cb  = shift;
    my $req = HTTP::Request->new( GET => "http://localhost/" );
    my $res = $cb->($req);
    like $res->content, qr/てすと/;
  };

