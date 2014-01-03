package APNS::Agent;
use feature ':5.10';
use strict;
use warnings;

our $VERSION = "0.01";

use AnyEvent::APNS;
use Cache::LRU;
use Encode qw/decode_utf8/;
use JSON::XS;
use Log::Minimal;
use Plack::Request;

use Class::Accessor::Lite::Lazy 0.03 (
    new => 1,
    ro => [qw/
        certificate
        private_key
        sandbox
        debug_port
    /],
    ro_lazy => {
        on_error_response   => sub { sub { warnf "identifier:$_[0]\tstate:$_[1]\ttoken:$_[2]" } },
        disconnect_interval => sub { 60 },
        _sent_token         => sub { Cache::LRU->new(size => 10000) },
        _queue              => sub { [] },
        __apns              => '_build_apns',
    },
    rw => [qw/_last_sent_at _disconnect_timer/],
);

sub to_app {
    my $self = shift;

    sub {
        my $env = shift;
        my $req = Plack::Request->new($env);

        return [404, [], ['NOT FOUND']] unless $req->path_info =~ m!\A/?\z!ms;

        if ($req->method eq 'POST') {
            my $token = $req->param('token') or return [400, [], ['Bad Request']];

            my $payload;
            if (my $payload_json = $req->param('payload') ) {
                state $json_driver = JSON::XS->new->utf8;
                local $@;
                my $payload = eval { $json_driver->decode($payload_json) };
                return [400, [], ['BAD REQUEST']] if $@;
            }
            elsif (my $alert = $req->param('alert')) {
                $payload = +{
                    alert => decode_utf8($alert),
                };
            }
            return [400, [], ['BAD REQUEST']] unless $payload;

            if ($self->__apns->connected) {
                $self->_send($token, $payload);
                infof "[server] payload accepted. token: %s", $token;
            }
            else {
                infof "[apns] push queue";
                push @{$self->_queue}, [$token, $payload];
                $self->_connect_to_apns;
            }
            return [200, [], ['Accepted']];
        }

        return [405, [], ['Method Not Allowed']];
    };
}

sub _build_apns {
    my $self = shift;

    AnyEvent::APNS->new(
        certificate => $self->certificate,
        private_key => $self->private_key,
        sandbox     => $self->sandbox,
        on_error    => sub {
            my ($handle, $fatal, $message) = @_;

            my $t; $t = AnyEvent->timer(
                after    => 0,
                interval => 10,
                cb       => sub {
                    undef $t;
                    infof "[apns] reconnect";
                    $self->_connect_to_apns;
                },
            );

            infof "[apns] error fatal: $fatal message: $message";
        },
        on_connect  => sub {
            infof "[apns] on_connect";
            $self->_disconnect_timer($self->_build_disconnect_timer);

            if (@{$self->_queue}) {
                while (my $q = shift @{$self->_queue}) {
                    $self->_send(@$q);
                    infof "[apns] sent from queue. token: ".$q->[0];
                }
            }
        },
        on_error_response => sub {
            my ($identifier, $state) = @_;
            my $token = $self->_sent_token->get($identifier) || '';
            $self->on_error_response->(@_, $token);
        },
        ($self->debug_port ? (debug_port => $self->debug_port) : ()),
    );
}

sub _apns {
    my $self = shift;

    my $apns = $self->__apns;
    $apns->connect unless $apns->connected;
    $apns;
}
sub _connect_to_apns { goto \&_apns }

sub _build_disconnect_timer {
    my $self = shift;

    if (my $interval = $self->disconnect_interval) {
        AnyEvent->timer(
            after    => $interval,
            interval => $interval,
            cb       => sub {
                if ($self->{__apns} && (time - ($self->_last_sent_at || 0) > $interval)) {
                    delete $self->{__apns};
                    delete $self->{_disconnect_timer};
                    infof "[apns] close apns";
                }
            },
        );
    }
    else { undef }
}

sub _send {
    my ($self, $token, $payload) = @_;

    my $identifier = $self->_apns->send(pack("H*", $token) => {
        aps => $payload,
    });
    $self->_sent_token->set($identifier, $token);
    $self->_last_sent_at(time);
    $identifier;
}

sub run {
    my $self = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    if (!$args{listen} && !$args{port}) {
        $args{port} = 4905;
    }
    require Plack::Loader;
    Plack::Loader->load(Twiggy => %args)->run($self->to_app);
}

1;
__END__

=encoding utf-8

=head1 NAME

APNS::Agent - It's new $module

=head1 SYNOPSIS

    use APNS::Agent;

=head1 DESCRIPTION

APNS::Agent is ...

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

