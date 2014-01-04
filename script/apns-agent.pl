#!/usr/bin/perl
use strict;
use warnings;
use Plack::Runner;
use APNS::Agent;

my ($opt, $argv) = APNS::Agent->parse_options(@ARGV);
my $agent  = APNS::Agent->new($opt);
my $runner = Plack::Runner->new;
$runner->parse_options('--port=4905', @$argv);
$runner->run($agent->to_app);

__END__

=head1 SYNOPSIS

    % apns-agent.pl --certificate=/path/to/certificate --private-key=/path/to/private
    Options:
        --certificate|s             path to certificate (Required)
        --private-key|s             path to private key (Required)
        --disconnect-interval=i     disconnect interval (Default: 60)
        --sandbox                   sandbox or not      (Default: disable)
        --debug-port                debug port number   (Optional)

=head1 DESCRIPTION

APNS::Agent launcher

=head1 AUTHORS

Masayuki Matsuki
