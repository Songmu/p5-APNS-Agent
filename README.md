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

This module provides consistent connection to APNS and cares reconnection. It utilize
[AnyEvent::APNS](http://search.cpan.org/perldoc?AnyEvent::APNS) internally.

# SEE ALSO

[AnyEvent::APNS](http://search.cpan.org/perldoc?AnyEvent::APNS)

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Songmu <y.songmu@gmail.com>
