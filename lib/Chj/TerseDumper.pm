#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::TerseDumper

=head1 SYNOPSIS

 use Chj::TerseDumper;
 print TerseDumper($foo);

=head1 DESCRIPTION

Runs Data::Dumper's Dumper with $Data::Dumper::Terse set to 1.

=cut


package Chj::TerseDumper;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(TerseDumper);
@EXPORT_OK=qw(SortedTerseDumper terseDumper);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Data::Dumper;

sub TerseDumper {
    local $Data::Dumper::Terse= 1;
    Dumper(@_)
}

sub SortedTerseDumper {
    local $Data::Dumper::Sortkeys= 1;
    TerseDumper (@_)
}

sub terseDumper {
    my $str= SortedTerseDumper (@_);
    chomp $str;
    $str
}


1
