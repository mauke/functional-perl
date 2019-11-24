#!/usr/bin/env perl

# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
# This is free software. See the file COPYING.md that came bundled
# with this file.

use strict; use warnings; use warnings FATAL => 'uninitialized';

our $len= 672;

use Test::More;
use lib "./lib";
use Chj::Backtrace;


# adapted COPY from the SYNOPSIS:

 use FP::Predicates qw(is_array maybe);

 use FP::Struct Foo=>
         ["name",
          [maybe (\&is_array), "animals"]]
       # => "Baz", "Buzz" # optional superclasses
            ;

is new Foo ("Tim")->name, "Tim";
is do { eval { new Foo ("Tim", 0) } || do { my $e= $@; $e=~ s/ at .*//s; $e } },
  "unacceptable value for field 'animals': 0";
is new Foo (undef, ["Struppi"])->animals->[0], "Struppi";
is new_ Foo (animals=> ["Struppi"])->animals->[0], "Struppi";


 {
   package Hum;
   sub hum {
      my $s=shift;
      $s->name." hums ".$s->a." over ".$s->b
   }
 }
 {
   package Hah;
   use FP::Struct ["aa"];
   _END_
 }

 {
   package Bar;
   use Chj::TEST; # the TEST sub will be removed from the package upon
                  # _END_ (namespace cleaning)
   use FP::Struct ["a","b"]=> "Foo", "Hum", "Hah";
   sub div {
      my $s=shift;
      $$s{a} / $$s{b}
   }
   TEST { Bar->new_(a=> 1, b=> 2)->div } 1/2;
   _END_ # generate accessors for methods of given name which don't
         # exist yet *in either Bar or any super class*. (Does that
         # make sense?)
 }

 my $bar= new Bar ("Franz", ["Barney"], "some aa", 1,2);
 # same thing, but with sub instead of method call interface:
 my $baz= Bar::c::Bar ("Franz", ["Barney"], "some aa", 1,2);

is $bar-> div, 1/2;
is $baz-> div, 1/2;

is new_ Bar (a=>1,b=>2)-> div, 1/2;
is Bar::c::Bar_ (a=>1, b=>2)->div, 1/2;
is new__ Bar ({a=>1,b=>2})-> div, 1/2;
is unsafe_new__ Bar ({a=>1,b=>2})-> div, 1/2;

is $bar->b_set(3)->div, 1/3;

 use FP::Div 'inc';

is $bar->b_update(\&inc)->div, 1/3;

is $bar->hum, "Franz hums 1 over 2";

is Chj::TEST::run_tests("Bar")->fail, 0;

is (Bar->can("TEST"), undef);


done_testing;
