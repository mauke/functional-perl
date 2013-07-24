#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::PXML::Serialize

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::PXML::Serialize;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(pxml_xhtml_print);
@EXPORT_OK=qw(pxml_print_fragment
	      pxml_xhtml_print_fast
	      pxml_print_fragment_fast);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Data::Dumper;
use Chj::PXML;
use Chj::FP2::Lazy;
use Chj::FP2::List;
use Chj::FP2::Stream;
use Chj::xIO;

sub perhaps_dump {
    my ($v)=@_;
    if (ref ($v) eq "ARRAY" or ref($v) eq "HASH") {
	Dumper($v)
    } else {
	$v
    }
}

my %attribute_escape=
    ('&'=> '&amp;',
     '<'=> '&lt;',
     '>'=> '&gt;',
     '"'=> '&quot;');
sub attribute_escape {
    my ($str)=@_;
    $str=~ s/([&<>"])/$attribute_escape{$1}/sg;
    $str
}

my %content_escape=
    ('&'=> '&amp;',
     '<'=> '&lt;',
     '>'=> '&gt;');
sub content_escape {
    my ($str)=@_;
    $str=~ s/([&<>])/$content_escape{$1}/sg;
    $str
}

sub pxml_print_fragment_fast ($ $ );
sub pxml_print_fragment_fast ($ $ ) {
    my ($v,$fh)=@_;
  LP: {
	if (ref $v) {
	    if (UNIVERSAL::isa($v, "Chj::PXML")) {
		my $n= $v->name;
		xprint $fh,"<$n";
		if (my $attrs= $v->maybe_attributes) {
		    for my $k (sort keys %$attrs) {
			xprint $fh, " $k=\"", attribute_escape($$attrs{$k}),"\"";
		    }
		}
		my $body= $v->body;
		if (# fast path
		    not @$body
		    or
		    # slow path
		    nullP(Force(stream_mixed_flatten ($body)))) {
		    xprint $fh,"/>";
		} else {
		    xprint $fh,">";
		    pxml_print_fragment_fast ($body, $fh);
		    xprint $fh,"</$n>";
		}
	    } elsif (pairP $v) {
		pxml_print_fragment_fast (car $v, $fh);
		#pxml_print_fragment_fast (cdr $v, $fh);
		$v= cdr $v;
		redo LP;
	    } elsif (promiseP $v) {
		#pxml_print_fragment_fast (Force($v), $fh);
		$v= Force($v,1);
		redo LP;
	    } else {
		if (ref ($v) eq "ARRAY") {
		    pxml_print_fragment_fast ($_, $fh)
			for (@$v);
		} else {
		    die "unexpected type of reference: ".(perhaps_dump $v);
		}
	    }
	} elsif (nullP $v) {
	    # end of linked list, nothing
	} else {
	    xprint $fh,content_escape($v)
	}
    }
}

sub pxml_xhtml_print_fast ($ $ ;$ ) {
    my ($v, $fh, $maybe_lang)= @_;
    if (not UNIVERSAL::isa($v, "Chj::PXML")) {
	die "not an element: ".(perhaps_dump $v);
    }
    if (not "html" eq $v->name) {
	die "not an 'html' element: ".(perhaps_dump $v);
    }
    xprint $fh, "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
    xprint $fh, "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
    # add attributes to toplevel element
    my $v2= $v->maybe_attributes ? $v :
	$v->set_attributes
	(do {
	    my $lang= $maybe_lang
		or die "missing 'lang' attribute from html element and no lang option given";
	    +{
		xmlns=> "http://www.w3.org/1999/xhtml",
		"xml:lang"=> $lang,
		lang=> $lang
	    }
	 });
    pxml_print_fragment_fast ($v2, $fh);
}

# for now,
sub pxml_xhtml_print ($ $ ;$ );
*pxml_xhtml_print = *pxml_xhtml_print_fast;


1
