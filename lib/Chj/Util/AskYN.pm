#
# Copyright (c) 2003-2015 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

Chj::Util::AskYN

=head1 SYNOPSIS

    use Chj::Util::AskYN;

    LP: {
        if (maybe_askyn "Do you want to retry?") {
            redo LP;
        }
    }

=head1 DESCRIPTION

Simply ask for a boolean question on stdout/stdin. Accept y/n, yes/no
in english, german and french and return those as boolean
true/false. If the user closes the input (using ctl-d), undef is
returned.

=head1 TODO

Delete this and use something else?

=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package Chj::Util::AskYN;
use Exporter "import";
our @EXPORT = qw(maybe_askyn);

use strict;
use warnings;
use warnings FATAL => 'uninitialized';

sub maybe_askyn {
    my ($maybe_prompt) = @_;
    local $| = 1;
ASK: {
        if (defined $maybe_prompt) {
            print $maybe_prompt;
        }
        print " ";
        my $ans = <STDIN>;
        if (defined $ans) {
            if ($ans =~ /^n(?:o|ein|ada|on)?$/i) {
                ''
            } elsif ($ans =~ /^(?:ja|yes|j|y|oui)$/i) {
                1
            } else {
                print "Please answer with yes or no or their initials, "
                    . "or the same in french or german.\n";
                redo ASK;
            }
        } else {

            # EOF, i.e. ctl-d
            print "\n";
            undef
        }
    }
}

1
