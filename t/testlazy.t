#!/usr/bin/env perl

# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

our $len= 1000;
require "./meta/test.pl";

use Test::More;

use POSIX 'SIGPIPE';
our $sigpipe_is_fine= sub {
    my ($buf, $default_on_error)= @_;
    $? == SIGPIPE ? $buf : &$default_on_error();
};

is readin ("functional_XML/testlazy|", $sigpipe_is_fine), readin ("< t/testlazy.expected");

done_testing;
