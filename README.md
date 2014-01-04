# NAME

APNS::Agent - agent server for APNS

# SYNOPSIS

    use APNS::Agent;
    my $agent = APNS::Agent->new(
        certificate => '/path/to/certificate',
        private_key => '/path/to/private_key',
    );
    $agent->run;

# DESCRIPTION

APNS::Agent is agent server for APNS. It is also backend class of [apns-agent.pl](http://search.cpan.org/perldoc?apns-agent.pl).

This module provides consistent connection to APNS and cares reconnection. It utilizes
[AnyEvent::APNS](http://search.cpan.org/perldoc?AnyEvent::APNS) internally.

# API PARAMETERS

APNS::Agent launches HTTP Server process which accepts only POST method and
application/x-www-form-urlencoded format parameters.

Acceptable parameters as follows:

- `token`

    device token (HEX format)

- `payload`

    JSON string for push notification. If you only want to send message, alternatively can use
    `alert` parameter.

    Both of `payload` and `alert` are specified, the `payload` paramter has priority.

- `alert`

    Optional. push notification message.

# SEE ALSO

[AnyEvent::APNS](http://search.cpan.org/perldoc?AnyEvent::APNS)

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
