requires 'AnyEvent::APNS';
requires 'Cache::LRU';
requires 'Class::Accessor::Lite::Lazy', '0.03';
requires 'Encode';
requires 'JSON::XS';
requires 'Log::Minimal';
requires 'Plack::Loader';
requires 'Plack::Request';
requires 'feature';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'AnyEvent';
    requires 'AnyEvent::Socket';
    requires 'Furl';
    requires 'Test::More';
    requires 'Test::TCP';
};
