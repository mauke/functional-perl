#
# Copyright (c) 2014-2019 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Htmlgen::Mediawiki

=head1 SYNOPSIS

=head1 DESCRIPTION

Expand `[[ ]]` in markdown source text into standard markdown format.

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut


package FunctionalPerl::Htmlgen::Mediawiki;
@ISA = "Exporter"; require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(mediawiki_prepare mediawiki_replace mediawiki_rexpand
              mediawiki_expand);
%EXPORT_TAGS = (all => [@EXPORT,@EXPORT_OK]);

use strict; use warnings; use warnings FATAL => 'uninitialized';

use Function::Parameters qw(:strict);
use Sub::Call::Tail;
use FP::Docstring;
use Chj::chompspace;
use Chj::TEST ":all";
use PXML::XHTML ":all";
use FP::Show;

# and for text display we need to *decode* URIs..
# COPY from chj-bin's `urldecode`
use URI;
use Encode;
sub url_decode {
    my ($str) = @_;
    my $u = URI->new($str);
    my $str2 = $u->uri_unescape;
    decode("utf-8", $str2, Encode::FB_CROAK)
}

# escape [ ] for markdown; XX is this correct?
fun squarebracked_escape ($str) {
    $str =~ s%([\[\]])%\\$1%sg;
    $str
}



# meant to preprocess the whole markdown document; keep the returned
# table and the used token for mediawiki_expand.

fun mediawiki_prepare ($str, $token) {
    __ '($str, $tokenstr) -> ($str, $hashtable) '.
        '-- replace "[[...]]" syntax in $str with replacement tokens '.
        'which use $tokenstr as prefix';
    my $table = {};
    my $n = 0;
    $str =~ s%(^|.)\[\[(.*?[^\\])\]\]%
      my ($pre,$cont) = ($1,$2);
      $n++;
      $$table{$n} = $cont;
      $pre.$token."-".$n."-" # must be inert to markdown parser
    %sge;
    ($str, $table)
}

TEST {[mediawiki_prepare 'foo [[bar]] [[baz]].', 'LO']}
  ['foo LO-1- LO-2-.',
   {
    '1' => 'bar',
    '2' => 'baz'
   }
  ];


# possibly should build PXML directly from here instead of string
# replace, but I'm lazy right now.

fun mediawiki_replace ($str, $token, $table) {
    __ '($str, $token, {tokenargument => $value,..}) -> $str '.
        '-- re-insert hidden parts';
    $str =~ s%\Q$token\E-(\d+)-%
       '[['.$$table{$1}.']]'
    %sge;
    $str
}

# here's the version that returns PXML, through the indirection of a
# string, which XXX may very well be unsafe.

fun mediawiki_rexpand ($str, $token, $table) {
    __ '($str, $token, $table) -> [PXML::Element] '.
        '-- mediawiki_replace then _expand';
    mediawiki_expand (mediawiki_replace ($str, $token, $table))
}


fun mediawiki_expand ($str) {
    __ '($text_segment_str) -> [string|PXML::Element] '.
        '-- expand "[[...]]" in $text_segment_str to link elements';
    my $res = [];
    my $lastpos = 0;
    while ($str =~ m%(^|.)\[\[(.*?[^\\])\]\]%sg) {
        next if $1 eq '\\';
        my $cont = $2;
        my $pos = pos $str;

        my $matchlen = 2 + length ($cont) + 2;
        my $prelen = $pos-$matchlen-$lastpos;
        push @$res, substr $str, $lastpos, $prelen
          if $prelen>0;
        $lastpos = $pos;

        $cont =~ s|(?<=[^\\])\\(.)|$1|sg; # remove quoting
        my @parts = map { chompspace $_ } split /(?<=[^\\])\|/, $cont;
        if (@parts == 1) {
            my ($docname_and_perhaps_fragment) = @parts;
            my $uri = URI->new($docname_and_perhaps_fragment);

            my $fragment = url_decode $uri->fragment;
            my $fragmenttext = do {
                if (length $fragment) {
                    my @f = split /,/, $fragment;
                    my $f = shift @f;
                    while (@f and length $f < 20 and length $f[0] < 20) {
                        $f .= ",".shift @f;
                    }
                    $f .= ".." if @f;
                    if (length $f > 40) {
                        $f = substr($f, 0, 28) . ".."
                    }
                    # convert underscores back to spaces (XX
                    # well.. that's lossy!)
                    $f =~ s/_/ /sg;
                    " ($f)";
                } else {
                    ""
                }
            };

            # (Get title of document at path? But may be too long,
            # probably not a good idea.)

            # XX use 'opaque' instead of 'path' for the url? for
            # locations with protocol or so? Or croak about those? Use
            # opaque for the text, though, ok?
            my $text = $uri->opaque;
            $text =~ tr/_/ /;
            push @$res,
              A({
                 href=>
                 "//"
                 . $uri->path.".md"
                 . do {
                     my $f = $uri->fragment;
                     length $f ? "#".$f : ""
                 }
                },
                $text.$fragmenttext);
        } elsif (@parts == 2) {
            my ($loc,$text) = @parts;
            push @$res,
              A({href=> $loc},
                $text)
        } else {
            # XX location?...
            die "more than 2 parts in a wiki style link: ".show($cont);
        }
    }

    my $postlen = length($str)-$lastpos;
    push @$res, substr $str, $lastpos, $postlen
      if $postlen > 0;

    $res
}


TEST { mediawiki_expand "<foo>[[bar]] baz</foo>" }
  ['<foo>', A({href=> "//bar.md"}, "bar"), ' baz</foo>'];

TEST { mediawiki_expand
         ' [[howto#References (and "mutation"), "variables" versus "bindings"]] ' }
  [' ', A({href=> '//howto.md#References%20(and%20%22mutation%22),%20%22variables%22%20versus%20%22bindings%22'},
          'howto (References (and "mutation")..)'), ' '];

TEST { mediawiki_expand ' [[Foo#yah_Hey\\[1\\]]] ' }
  [' ', A({href=> '//Foo.md#yah_Hey[1]'}, 'Foo (yah Hey[1])'), ' '];

TEST { mediawiki_expand ' [[Foo#(yah_Hey)\\[1\\]|Some \\[text\\]]] ' }
  [' ', A({href=> 'Foo#(yah_Hey)[1]'}, 'Some [text]'), ' ']; # note: no // and .md added to Foo!


TEST { mediawiki_expand 'foo [[bar]]' }
  ['foo ', A{href=>"//bar.md"}, "bar"];
TEST { mediawiki_expand '[[bar]]' }
  [A{href=>"//bar.md"}, "bar"];
TEST { mediawiki_expand ' \[[bar]]' }
  [' \[[bar]]'];

1
