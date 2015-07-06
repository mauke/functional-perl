#
# Copyright (c) 2004 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License. See the file COPYING.md that came bundled with this
# file.
#

=head1 NAME

Chj::chompspace

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::chompspace;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(chompspace);
#@EXPORT_OK=qw();
use strict;

sub chompspace($) {
    my ($str)=@_;
    $str=~ s/^\s+//s;
    $str=~ s/\s+\z//s;
    $str
}

*Chj::chompspace= \&chompspace;

1;
