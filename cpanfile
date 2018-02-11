requires 'perl',                       5.006;
requires 'Class::Accessor',            0.18;
requires 'Class::Factory',             1.00;
requires 'Class::Observable',          1.04;
requires 'DateTime',                   0.15;
requires 'DateTime::Format::Strptime', 1.00;
requires 'Exception::Class',           1.10;
requires 'Log::Dispatch',              2.00;
requires 'Log::Log4perl',              0.34;
requires 'Safe';
requires 'XML::Simple',                2.00;
requires 'DBI';
requires 'Data::Dumper';
requires 'Carp';
requires 'File::Slurp';
requires 'Data::UUID';
requires 'DBIx::Class';

feature 'SPOPS', 'SPOPS support' => sub {
    recommends 'SPOPS';
};

on 'test' => sub {
    requires 'DBD::Mock',           0.10;
    requires 'List::MoreUtils';
    requires 'Pod::Coverage::TrustPod';   # from Dist::Zilla
    requires 'Test::Exception';
    requires 'Test::More',          0.88;
    requires 'Test::Kwalitee',      1.21; # from Dist::Zilla
    requires 'Test::Pod',           1.41; # from Dist::Zilla
    requires 'Test::Pod::Coverage', 1.08; # from Dist::Zilla
};