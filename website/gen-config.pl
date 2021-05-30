use strict;
use warnings;
use warnings FATAL => 'uninitialized';
use utf8;
use experimental "signatures";

our ($mydir, $gitrepository);    # 'import' from main

use PXML::XHTML ":all";
use Clone 'clone';
use FP::Lazy;

# htmlgen is run with CWD set to website/
my $logocfg = require "./logo.pl";

my $css_path0 = "FP.css";

my $version_numrevisions = lazy {
    my $describe = $gitrepository->describe();
    my ($version, $maybe_numrevisions, $maybe_shorthash)
        = $describe =~ /^(.*?)(?:-(\d+)-g(.*))?\z/s
        or die "huh describe '$describe'";
    [$version, $maybe_numrevisions]
};

my $year = (localtime)[5] + 1900;

my $email = "copying\@christianjaeger.ch";    # ? or ch@?

+{
    map_code_body => sub ($str, $uplist, $path0) {
        my ($version, $maybe_numrevisions) = @{ force $version_numrevisions};
        my $version_underscores = $version;
        $version_underscores =~ tr/./_/;
        my $commits
            = $maybe_numrevisions
            ? ($maybe_numrevisions == 1
            ? "$maybe_numrevisions commit"
            : "$maybe_numrevisions commits")
            : "zero commits";

        $str =~ s|\$FP_VERSION\b|$version|sg;
        $str =~ s|\$FP_VERSION_UNDERSCORES\b|$version_underscores|sg;
        $str =~ s|\$FP_COMMITS_DIFFERENCE\b|$commits|sg;
        $str
    },

    #copy_paths => [], optional, for path0s from the main source root
    copy_paths_separate =>

        # source_root => path0s
        +{ "." => ["FP-logo.png", $css_path0,] },
    path0_handlers => +{},
    title          => sub($filetitle) {
        (
            $filetitle eq "Readme"
            ? "Functional programming in Perl"
            : $filetitle,
            " - functional-perl.org"
        )
    },
    head => sub($path0) {

        # HTML to add to the <head> section
        LINK(
            {
                rel  => "stylesheet",
                href => path_diff($path0, $css_path0),
                type => "text/css"
            }
        )
    },

    header => sub($path0) {

        # HTML above navigation

        # XX hack: clone it so that serialization doesn't kill parts of
        # it (by way of `weaken`ing)
        clone $logocfg->($path0)->{logo}
    },
    nav => nav(
        entry(
            "README.md",            entry("docs/intro.md"),
            entry("docs/howto.md"), entry("docs/design.md"),
            entry("examples/README.md")
        ),
        entry("functional_XML/README.md", entry("functional_XML/TODO.md")),
        entry("htmlgen/README.md",        entry("htmlgen/TODO.md")),
        entry("docs/ideas.md"),
        entry("docs/TODO.md", entry("docs/names.md")),
        entry("docs/HACKING.md"),
        entry("COPYING.md", entry("licenses/artistic_license_2.0.md")),
        entry("docs/links.md"),
        entry("docs/contact.md", entry("docs/mailing_list.md")),
        entry(
            "docs/blog/index.md",
            entry("docs/blog/perl-weekly-challenges-113.md"),
            entry("docs/blog/perl_weekly_challenges_114.md")
        )
    ),
    belownav => sub($path0) {

        # HTML between navigation and page content.
        # path0 is the source (.md) file.

        DIV(
            { class => "editandhist" },
            A(
                {
                    href =>
                        "https://github.com/pflanze/functional-perl/commits/master/$path0"
                },
                "history"
            ),
            " | ",
            A(
                {
                    href =>
                        "https://github.com/pflanze/functional-perl/edit/master/$path0"
                },
                "edit"
            )
        )
    },
    footer => sub($path0) {
        my $yearstart = 2014;
        my $years     = $year == $yearstart ? $year : "$yearstart-$year";
        DIV(
            { class => "footer_legalese" },

            # our part
            "© $years ", A({ href => "mailto:$email" }, "Christian Jaeger"),

            ". ",

            # camel logo
            "The Perl camel image is a trademark of ",
            A({ href => "http://www.oreilly.com" }, "O'Reilly Media, Inc."),
            " Used with permission."
        )
    },

    warn_hint => 1,    # warn if the website hint (header) is missing in a
                       # .md file

    downcaps =>
        1,    # whether to downcase all-caps filenames like README -> Readme
    }
