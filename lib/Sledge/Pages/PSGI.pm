package Sledge::Pages::PSGI;
# $Id: CGI.pm,v 1.1.1.1 2003/02/13 06:59:36 miyagawa Exp $
#
# Tatsuhiko Miyagawa <miyagawa@edge.co.jp>
# Livin' On The EDGE, Co., Ltd..
#

use strict;
use warnings;
use base qw(Sledge::Pages::Base);

use 5.008001;

use Sledge::Request::PSGI;

# my $res = My::Pages->new($env)->dispatch('index');
sub create_request {
    my($self, $env) = @_;
    return Sledge::Request::PSGI->new($env);
}

sub dispatch {
    my($self, $page) = @_;
    my $r = $self->r;
    $self->SUPER::dispatch($page);
    return $r->finalize;
}

1;

