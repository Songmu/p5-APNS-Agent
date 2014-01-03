use strict;
use warnings;
use utf8;
use Test::More;
use Test::TCP;
use Plack::Test;
use HTTP::Request::Common;

use AnyEvent;
use AnyEvent::Socket;
use Furl;

use JSON::XS;
use APNS::Agent;

my $cv = AnyEvent->condvar;

my $apns_port = empty_port;
tcp_server undef, $apns_port, sub {
    my ($fh) = @_
        or die $!;

    my $handle; $handle = AnyEvent::Handle->new(
        fh       => $fh,
        on_eof   => sub {
        },
        on_error => sub {
            die $!;
            undef $handle;
        },
        on_read => sub {
            $_[0]->unshift_read( chunk => 1, sub {} );
        },
    );

    $handle->push_read( chunk => 1, sub {
        is($_[1], pack('C', 1), 'command ok');
    });

    $handle->push_read( chunk => 4, sub {
        is($_[1], pack('N', 1), 'identifier ok');
    });

    $handle->push_read( chunk => 4, sub {
        my $expiry = unpack('N', $_[1]);
        is( $expiry, time() + 3600 * 24, 'expiry ok');
    });

    $handle->push_read( chunk => 2, sub {
        is($_[1], pack('n', 32), 'token size ok');
    });

    $handle->push_read( chunk => 32, sub {
        is($_[1], 'd'x32, 'token ok');
    });

    $handle->push_read( chunk => 2, sub {
        my $payload_length = unpack('n', $_[1]);

        $handle->push_read( chunk => $payload_length, sub {
            my $payload = $_[1];
            my $p = decode_json($payload);

            is(length $payload, $payload_length, 'payload length ok');
            is $p->{aps}->{alert}, 'ほげ', 'value of alert';
        });

        my $t; $t = AnyEvent->timer(
            after => 0.5,
            cb    => sub {
                undef $t;
                $cv->send;
            },
        );
    });
};

local $Log::Minimal::LOG_LEVEL = "NONE";
test_psgi
    app => APNS::Agent->new({
          sandbox     => 1,
          certificate => 'dummy',
          private_key => 'dummy',
          debug_port  => $apns_port,
    })->to_app,
    client => sub {
        my $cb  = shift;

        my $res = $cb->(POST 'http://localhost', [
            token => unpack("H*", 'd'x32),
            alert => 'ほげ',
        ]);
        $cv->recv;
        like $res->content, qr/Accepted/;
    };

done_testing;
