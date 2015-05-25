#
# Copyright 2014-2015 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::FP::Div

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FP::Div;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(inc dec
	      identity
	      compose compose_scalar maybe_compose
	      flip flip2_3 rot3right rot3left);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';
use Chj::TEST;

# XX should `indentity` pass multiple values, and this be called
# `identity_scalar`? :

sub identity ($) {
    $_[0]
}

sub inc ($) {
    $_[0] + 1
}

sub dec ($) {
    $_[0] - 1
}

sub compose {
    my (@fn)= reverse @_;
    sub {
	my (@v)= @_;
	for my $fn (@fn) {
	    @v= &$fn(@v);
	}
	wantarray ? @v : $v[-1]
    }
}

# same as compose, but request scalar context between the calls:

sub compose_scalar {
    my (@fn)= reverse @_;
    my $f0= pop @fn;
    my $fx= shift @fn;
    sub {
	my $v= &$fx;
	for my $fn (@fn) {
	    $v= &$fn($v);
	}
	@_=($v); goto $f0
    }
}

TEST { compose (sub { $_[0]+1 }, sub { $_[0]+$_[1] })->(2,3) }
  6;
TEST { compose_scalar  (sub { $_[0]+1 }, sub { $_[0]+$_[1] })->(2,3) }
  6;

TEST { compose (sub { $_[0] / ($_[1]//5) },
		sub { @_ },
		sub { $_[1], $_[0] })
	 ->(2,3) }
  1.5;
TEST { compose_scalar (sub { $_[0] / ($_[1]//5) },
		       sub { @_ },
		       sub { $_[1], $_[0] })
	 ->(2,3) }
  1/5;


# a compose that short-cuts when there is no defined intermediate
# result:

sub maybe_compose {
    my (@fn)= reverse @_;
    sub {
	my (@v)= @_;
	for (@fn) {
	    # return undef, not (), for 'maybe_'; the latter would ask
	    # for convention 'perhaps_', ok?
	    return undef unless @v>1 or defined $v[0];
	    @v= &$_(@v);
	}
	wantarray ? @v : $v[-1]
    }
}

TEST { maybe_compose (sub { die "foo @_" }, sub { undef }, sub { @_ })->(2,3) }
  undef;
TEST { maybe_compose (sub { die "foo @_" }, sub { undef })->(2,3) }
  undef;
TEST { maybe_compose (sub { [@_] }, sub { @_ })->(2,3) }
  [2,3];



use Carp;

sub flip ($) {
    my ($f)=@_;
    sub {
	@_==2 or croak "expecting 2 arguments";
	@_=($_[1], $_[0]); goto $f
    }
}

TEST { flip (sub { $_[0] / $_[1] })->(2,3) }
  3/2;

# same as flip but pass a 3rd argument unchanged (flip 2 in 3)
sub flip2_3 ($) {
    my ($f)=@_;
    sub {
	@_==3 or croak "expecting 3 arguments";
	@_=($_[1], $_[0], $_[2]); goto $f
    }
}

sub rot3right ($) {
    my ($f)=@_;
    sub {
	@_==3 or croak "expecting 3 arguments";
	@_=($_[2], $_[0], $_[1]); goto $f
    }
}

sub rot3left ($) {
    my ($f)=@_;
    sub {
	@_==3 or croak "expecting 3 arguments";
	@_=($_[1], $_[2], $_[0]); goto $f
    }
}


1
