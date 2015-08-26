#
# Copyright (c) 2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Text::CSV - functional interface to Text::CSV

=head1 SYNOPSIS

 use FP::Text::CSV qw(csv_line_xparser csv_fh_to_rows csv_file_to_rows);
 use Method::Signatures; # func

 my $csvparams= +{sep_char=> ";", eol=> "\n"};
 # $csvparams and any of its entries are optional,
 #  defaults are taken from $FP::Text::CSV::defaults

 # -- Input: ---
 my $p= csv_line_xparser $csvparams;
 my @vals= &$p("1;2;3;4\n");

 my $stream= csv_fh_to_rows($somefilehandle, $csvparams);
 # or
 my $stream= csv_file_to_rows($somepath, $csvparams);

 # then
 use FP::Stream ":all";
 my $stream2= stream_map func ($row) {
     #...
 }, $stream;
 # etc.

 # -- Output: ---
 my $rows=
   cons [ "i", "i^2" ],
     stream_map func ($i) {
	 [ $i, $i*$i ]
     }, stream_iota;
 rows_to_csv_fh ($rows, $somefilehandle);
 # or
 rows_to_csv_file ($rows, "path");


=head1 DESCRIPTION

Handle CSV input and output in the form of functional streams (lazily
computed linked lists).

=cut


package FP::Text::CSV;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(
		 new_csv_instance
		 csv_line_xparser
		 csv_fh_to_rows
		 csv_file_to_rows
		 csv_printer
		 rows_to_csv_fh
		 rows_to_csv_file
	    );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use FP::List ":all";
use FP::Lazy ":all";
use FP::Stream 'Weakened', 'weaken';
use Text::CSV;
use FP::HashSet 'hashset_union';
use Chj::xopen 'xopen_read';

our $defaults=
  +{
    binary => 1,
    sep_char=> "\t",
    eol=> "\r\n",
   };

sub params ($) {
    my ($maybe_params)=@_;
    defined $maybe_params ? hashset_union($maybe_params, $defaults)
      : $defaults
}

sub new_csv_instance (;$) {
    my ($maybe_params)=@_;
    Text::CSV->new(params $maybe_params)
}

sub csv_line_xparser (;$) {
    my ($maybe_params)=@_;
    my $csv= new_csv_instance $maybe_params;
    sub ($) {
	my ($line)=@_;
	$csv->parse($line)
	  or die "CSV parsing failure"; # XX how to get error message from Text::CSV?
	$csv->fields
    }
}


sub csv_fh_to_rows ($;$) {
    my ($in, $maybe_params)=@_;
    my $csv= new_csv_instance ($maybe_params);
    my $next; $next= sub {
	my $next=$next;
	lazy {
	    if (my $row= $csv->getline ($in)) {
		# XX error checks?
		cons $row, &$next;
	    } else {
		$in->xclose;
		null
	    }
	}
    };
    &{Weakened $next}
}

sub csv_file_to_rows ($;$) {
    my ($path, $maybe_params)=@_;
    my $in= xopen_read $path;
    binmode($in, ":encoding(utf-8)") or die "binmode";
    csv_fh_to_rows $in, $maybe_params
}


# -- Output: ---

sub csv_printer ($;$) {
    my ($fh, $maybe_params)=@_;
    my $csv= new_csv_instance ($maybe_params);
    sub {
	my ($row)=@_;
	$csv->print($fh, $row)
	  or die "could not write CSV row: ".$csv->error_diag;
	# XX ok?
    }
}

use FP::Stream "stream_for_each";

sub rows_to_csv_fh ($$;$) {
    my ($s, $fh, $maybe_params)=@_;
    weaken $_[0];
    stream_for_each csv_printer($fh, $maybe_params), $s
}

use Chj::xtmpfile;

sub rows_to_csv_file ($$;$) {
    my ($s, $path, $maybe_params)=@_;
    weaken $_[0];
    my $out= xtmpfile $path;
    rows_to_csv_fh ($s, $out, $maybe_params);
    $out->xclose;
    $out->xputback (0666 & ~umask);
}


1
