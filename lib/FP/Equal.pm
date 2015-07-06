#
# Copyright (c) 2014-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License. See the file COPYING.md that came bundled with this
# file.
#

=head1 NAME

FP::Equal - equality

=head1 SYNOPSIS

 use FP::Equal;
 equal [1, [2, 3]], [1, [1+1, 3]]; # -> true
 equal [1, [2, 3]], [1, [1+2, 3]]; # -> false

 my $s1= "stringwithunicode";
 my $s2= "stringwithunicode";
 utf8::decode($s2);
 equal $s1, $s2; # -> false
 equal_utf8 $s1, $s2; # -> true

=head1 DESCRIPTION

Deep structure equality comparison.

NOTE: currently using Data::Dumper and thus slow.

=cut


package FP::Equal;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(equal equal_utf8);
@EXPORT_OK=qw();
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Data::Dumper;

# XX these are expensive, of course. Better solution?

sub equal ($$) {
    my ($a,$b)=@_;
    local $Data::Dumper::Sortkeys=1;
    Dumper($a) eq Dumper($b)
}

sub equal_utf8 ($$) {
    my ($a,$b)=@_;
    local $Data::Dumper::Sortkeys=1;
    # compare ignoring utf8 flags on strings
    local $Data::Dumper::Useperl = 1;
    Dumper($a) eq Dumper($b)
}



1
