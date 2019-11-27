#
# Copyright (c) 2013-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

PXML::Tags

=head1 SYNOPSIS

    use PXML::Tags qw(records
        protocol-version
        record);
    my $xml= RECORDS(PROTOCOL_VERSION("1.0"),
                     RECORD("Hi"), RECORD("there!"));
    is ref($xml), "PXML::Element";
    is $xml->string, '<records><protocol-version>1.0</protocol-version><record>Hi</record><record>there!</record></records>';

=head1 DESCRIPTION

Creates tag wrappers that return PXML elements. The names of the
wrappers are all uppercase, and "-" is replaced with "_".

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package PXML::Tags;

use strict; use warnings; use warnings FATAL => 'uninitialized';

use PXML::Element;

sub import {
    my $caller=caller;
    for my $name (@_) {
        my $fname= uc $name;
        $fname=~ s/-/_/sg;
        my $fqname= "${caller}::$fname";
        no strict 'refs';
        *$fqname= sub {
            my $atts= ref($_[0]) eq "HASH" ? shift : undef;
            PXML::Element->new($name, $atts, [@_]);
        };
    }
    1
}

1
