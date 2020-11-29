#
# Copyright (c) 2015-2020 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#

=head1 NAME

FunctionalPerl::Htmlgen::Nav -- configurable navigation bar data structure

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 NOTE

This is alpha software! Read the status section in the package README
or on the L<website|http://functional-perl.org/>.

=cut

package FunctionalPerl::Htmlgen::Nav;
use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use experimental "signatures";
use Exporter "import";

our @EXPORT      = qw();
our @EXPORT_OK   = qw(_nav entry);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

# Constructors

sub _nav ($items, $nav_bar) {
    my $nav
        = FunctionalPerl::Htmlgen::Nav::TopEntry->new($items, $nav_bar, undef);
    $nav->index_set(nav_index($nav))
}

sub entry ($path0, @subentries) {
    FunctionalPerl::Htmlgen::Nav::RealEntry->new_(
        path0      => $path0,
        subentries => list(@subentries)
    );
}

# Classes

package FunctionalPerl::Htmlgen::Nav::Entry {
    use FP::Predicates ":all";
    use FP::List qw(list_of);    # should that be re-exported by
                                 # FP::Predicates?
    use FP::Ops qw(the_method);
    use FP::List;
    use FP::fix;
    use FP::Equal qw(equal);

    use FP::Struct [
        [
            list_of(instance_of "FunctionalPerl::Htmlgen::Nav::Entry"),
            "subentries"
        ]
    ];

    sub subentries_of_subentries($self) {
        $self->subentries->map(the_method "subentries")
    }

    # An FP::List of all nav levels, including level 0, but unlike the
    # result of nav_bar_level0, level 0 here is directly representing the
    # top level of the {nav} config value (unknown pages are dropped, and
    # non-existing pages show up). Feel free to drop it and replace with
    # nav_bar_level0.

    sub nav_bar_levels ($self, $viewed_at_item, $upitems) {
        fix(
            sub ($rec, $nav, $downitems, $upitem) {

                # only show subnavs until the given location
                # ($viewed_at_item), and then one more (to go down)?
                if (my ($item, $rest) = $downitems->perhaps_first_and_rest) {
                    my $entries = $nav->subentries;
                    my $active = $entries->filter(sub { $_[0] eq $item })->xone;

                    cons($self->nav_bar->($entries, $item, $viewed_at_item),
                        &$rec($active, $rest, $item))
                } else {

                    # the lowest level of the navigation stack: if the
                    # current item ($upitem, should also be the
                    # $viewed_at_item) has subentries, then show that
                    # (immediate) level as the last one. XX: this
                    # would better be shown in a different way; use
                    # (CSS based) mouse over submenu popups
                    # (advantage: show them on ~all the other items,
                    # too)?
                    if (is_pair(my $es = $upitem->subentries)) {
                        equal($upitem, $viewed_at_item) or die "bug?";

                        # hack: passing $upitem as the item here (*no*
                        # item should be marked as selected, this
                        # fulfills the purpose)
                        cons($self->nav_bar->($es, $upitem, $viewed_at_item),
                            null)
                    } else {
                        null
                    }
                }
            }
        )->($self, $upitems->reverse, undef)

            # an empty upitems list would be at odds with the given
            # undef $upitem, but that doesn't happen.
    }

    _END_
}

package FunctionalPerl::Htmlgen::Nav::TopEntry {
    use FP::Predicates ":all";
    use FP::Ops qw(the_method string_cmp);
    use FP::Combinators qw(compose);
    use FP::Array_sort;
    use FP::HashSet qw(hashset_to_predicate
        array_to_hashset);

    use FP::Struct [
        [*is_procedure,                                            "nav_bar"],
        [maybe(instance_of "FunctionalPerl::Htmlgen::Nav::Index"), "index"]
        ],
        "FunctionalPerl::Htmlgen::Nav::Entry";

    sub FP_Show_show ($self, $show) {
        ("nav(" . $self->subentries->map($show)->strings_join(", ") . ")")
    }

    # nav level 0: this is special since it does not just
    # show what the navigation defines, but show all
    # pages that are not in deeper levels

    sub item_is_in_lower_hierarchy($self) {
        compose(
            hashset_to_predicate(
                array_to_hashset(
                    $self->subentries_of_subentries->flatten->map(
                        the_method "path0"
                    )->array
                )
            ),
            the_method "path0"
        )
    }

    # In the toplevel of the nav hierarchy, still also show pages that are
    # missing in the nav declaration; thus, use the nav declaration to
    # *order* the pages instead:
    sub path0_to_sortkey($self) {
        my $sortprio = do {
            my $i = 1;
            +{
                map {
                    my $file = $_;
                    $file .= ".md" unless /\.\w{1,7}\z/;
                    $file => sprintf('-%04d', $i++)
                } $self->subentries->map(the_method "path0")->values
            }
        };
        sub($path0) {
            $$sortprio{$path0} || $path0
        }
    }

    sub path0_navigation_cmp($self) {
        on $self->path0_to_sortkey, *string_cmp
    }

    sub nav_bar_level0 ($self, $items, $item_selected, $viewed_at_item) {
        my $shownitems
            = $items->filter(complement $self->item_is_in_lower_hierarchy)
            ->sort(on the_method("path0"), $self->path0_navigation_cmp);
        $self->nav_bar->($shownitems, $item_selected, $viewed_at_item)
    }

    _END_
}

package FunctionalPerl::Htmlgen::Nav::RealEntry {
    use FP::Predicates ":all";
    use FP::Ops qw(the_method);
    use FP::Equal qw(equal);

    use FP::Struct [[*is_string, "path0"]],
        "FunctionalPerl::Htmlgen::Nav::Entry", "FP::Abstract::Equal";

    sub FP_Show_show ($self, $show) {
        ("entry("
                . $self->subentries->map($show)->cons(&$show($self->path0))
                ->strings_join(", ") . ")")
    }

    sub FP_Equal_equal ($self, $v) {
        ($self->path0 eq $v->path0 and equal($self->subentries, $v->subentries))
    }

    _END_
}

use FP::List;
use FP::fix;

# Build "index" data structure where each path0 is resolved back to an
# FP::List of items out of its location. Also to resolve path0 to its
# nav object.

package FunctionalPerl::Htmlgen::Nav::Index {
    use FP::List qw(null);

    use FP::Struct ["p0_to_upitems", "p0_to_item"];

    sub path0_to_upitems ($self, $p0) {

        # now includes the $p0 item itself
        $self->p0_to_upitems->{$p0}
            // FunctionalPerl::Htmlgen::Nav::entry($p0)    # not null
    }

    sub path0_to_item ($self, $p0) {
        $self->p0_to_item->{$p0} // FunctionalPerl::Htmlgen::Nav::entry($p0)
    }
    _END_
}

sub nav_index($nav) {
    my (%p0_to_upitems, %p0_to_item);
    my $index_level = fix sub ($index_level, $items, $upitems) {
        $items->subentries->for_each(
            sub($item) {
                my $p0       = $item->path0;
                my $upitems1 = $upitems->cons($item);
                $p0_to_upitems{$p0} = $upitems1;
                $p0_to_item{$p0}    = $item;
                &$index_level($item, $upitems1);
            }
        );
    };
    &$index_level($nav, null);
    FunctionalPerl::Htmlgen::Nav::Index->new(\%p0_to_upitems, \%p0_to_item);
}

1
