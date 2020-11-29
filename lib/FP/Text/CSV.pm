#
# Copyright (c) 2015-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FP::Text::CSV - functional interface to Text::CSV

=head1 SYNOPSIS

    use FP::Text::CSV qw(csv_line_xparser
                         csv_fh_to_rows
                         csv_file_to_rows
                         rows_to_csv_fh
                         rows_to_csv_file);

    my $csvparams = +{sep_char => ";", eol => "\n"};
    # $csvparams and any of its entries are optional,
    #  defaults are taken from $FP::Text::CSV::defaults

    use Chj::xopen qw(xopen_read xopen_write);
    use FP::List; use FP::Stream; use FP::Equal 'is_equal';
    mkdir ".tmp";

    # -- Output: ---
    my $rows =
      cons [ "i", "i^2" ],
        stream_iota->map(sub {
            my ($i) = @_;
            [ $i, $i*$i ]
        })->take(100);
    rows_to_csv_fh (Keep($rows), xopen_write(".tmp/a1.csv"),
                    $csvparams);
    # or
    rows_to_csv_file ($rows, ".tmp/a2.csv", $csvparams);


    # -- Input: ---
    my $p = csv_line_xparser $csvparams;
    my @vals = &$p("1;2;3;4\n");
    is_equal \@vals, [1,2,3,4];

    my $itemstream1 =
            csv_fh_to_rows(xopen_read(".tmp/a1.csv"), $csvparams);
    # or
    my $itemstream2 = csv_file_to_rows(".tmp/a2.csv", $csvparams);

    is_equal $itemstream1, $itemstream2;
    is_equal $itemstream2->first, [ "i", "i^2" ];
    is_equal $itemstream2->second, [ 0, 0 ];
    is_equal $itemstream2->ref(10), [ 9, 81 ];


=head1 DESCRIPTION

Handle CSV input and output in the form of functional streams (lazily
computed linked lists).

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FP::Text::CSV;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use Exporter "import";

our @EXPORT    = qw();
our @EXPORT_OK = qw(
    new_csv_instance
    csv_line_xparser
    csv_fh_to_rows
    csv_file_to_rows
    csv_printer
    rows_to_csv_fh
    rows_to_csv_file
);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

use FP::List ":all";
use FP::Lazy ":all";
use FP::Stream 'Weakened', 'weaken';
use Text::CSV;
use FP::HashSet 'hashset_union';
use Chj::xopen 'xopen_read';
use FP::Carp;

our $defaults = +{ binary => 1, sep_char => "\t", eol => "\r\n", };

sub params {
    @_ == 1 or die "wrong number of arguments";
    my ($maybe_params) = @_;
    defined $maybe_params ? hashset_union($maybe_params, $defaults) : $defaults
}

sub new_csv_instance {
    @_ >= 0 and @_ <= 1 or fp_croak_nargs "0-1";
    my ($maybe_params) = @_;
    Text::CSV->new(params $maybe_params)
}

sub csv_line_xparser {
    @_ >= 0 and @_ <= 1 or fp_croak_nargs "0-1";
    my ($maybe_params) = @_;
    my $csv = new_csv_instance $maybe_params;

    sub {
        @_ == 1 or die "wrong number of arguments";
        my ($line) = @_;
        $csv->parse($line)
            or die
            "CSV parsing failure"; # XX how to get error message from Text::CSV?
        $csv->fields
    }
}

sub csv_fh_to_rows {
    @_ >= 1 and @_ <= 2 or fp_croak_nargs "1-2";
    my ($in, $maybe_params) = @_;
    my $csv = new_csv_instance($maybe_params);
    my $next;
    $next = sub {
        my $next = $next;
        lazy {
            if (my $row = $csv->getline($in)) {

                # XX error checks?
                cons $row, &$next;
            } else {
                $in->xclose;
                null
            }
        }
    };
    &{ Weakened $next}
}

sub csv_file_to_rows {
    @_ >= 1 and @_ <= 2 or fp_croak_nargs "1-2";
    my ($path, $maybe_params) = @_;
    my $in = xopen_read $path;
    binmode($in, ":encoding(utf-8)") or die "binmode";
    csv_fh_to_rows $in, $maybe_params
}

# -- Output: ---

sub csv_printer {
    @_ >= 1 and @_ <= 2 or fp_croak_nargs "1-2";
    my ($fh, $maybe_params) = @_;
    my $csv = new_csv_instance($maybe_params);
    sub {
        my ($row) = @_;
        $csv->print($fh, $row)
            or die "could not write CSV row: " . $csv->error_diag;

        # XX ok?
    }
}

use FP::Stream "stream_for_each";

sub rows_to_csv_fh {
    @_ >= 2 and @_ <= 3 or fp_croak_nargs "2-3";
    my ($s, $fh, $maybe_params) = @_;
    weaken $_[0];
    stream_for_each csv_printer($fh, $maybe_params), $s
}

use Chj::xtmpfile;

sub rows_to_csv_file {
    @_ >= 2 and @_ <= 3 or fp_croak_nargs "2-3";
    my ($s, $path, $maybe_params) = @_;
    weaken $_[0];
    my $out = xtmpfile $path;
    rows_to_csv_fh($s, $out, $maybe_params);
    $out->xclose;
    $out->xputback(0666 & ~umask);
}

1
