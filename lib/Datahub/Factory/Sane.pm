package Datahub::Factory::Sane;

use strict;
use warnings;

use feature ();
use utf8;
use IO::File ();
use IO::Handle ();
use Try::Tiny::ByClass;

sub import {
    my $pkg = caller;
    strict->import;
    warnings->import;
    feature->import(qw(:5.10));
    utf8->import;
    Try::Tiny::ByClass->export_to_level(1, $pkg);
}

1;

__END__

=pod

=head1 NAME

Datahub::Factory::Sane - Package boilerplate

=head1 SYNOPSIS

    use Datahub::Factory::Sane;

    # Provides all the 5.10 features.
    say("what");
    given($foo) {
        when(1)     { say "1" }
        when([2,3]) { say "2 or 3" }
        when(/abc/) { say "has abc" }
        default     { none of the above }
    }
    sub next_id{
      state $id;
      ++$id;
    }

    # Provides try/catch[/finally] try/catch_case[/finally]
    try {
    } catch {};

=head1 DESCRIPTION

Package boilerplate equivalent to:

    use strict;
    use warnings;
    use feature qw(:5.10);
    use utf8;
    use IO::File ();
    use IO::Handle ();
    use Try::Tiny::ByClass;

=cut
