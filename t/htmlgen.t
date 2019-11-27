#!/usr/bin/env perl

# Copyright (c) 2015-2019 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Test::Requires
  +{
    'Function::Parameters'=> 0,
    #'Sub::Call::Tail'=> 0,
    'Text::Markdown'=> 0,
    'HTML::TreeBuilder'=> 0,
   };


use lib "./meta";
use FunctionalPerl::TailExpand;
use Chj::xperlfunc ":all";

require "./meta/find-perl.pl";

$ENV{RUN_TESTS}=1; xexec_safe $^X, "website/gen";