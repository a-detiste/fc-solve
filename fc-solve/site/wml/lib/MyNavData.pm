package MyNavData;

use strict;
use warnings;
use utf8;

my $hosts = {
    'fc-solve' => {
        'base_url' => "http://fc-solve.shlomifish.org/",
    },
};

my $tree_contents = {
    'host'        => "fc-solve",
    'text'        => "Freecell Solver",
    'title'       => "Freecell Solver",
    'show_always' => 1,
    'subs'        => [
        {
            'text' => "Home",
            'url'  => "",
        },
        {
            'text' => "Downloads",
            'url'  => "download.html",
            'subs' => [
                {
                    'text' => "Don Woods' Solver",
                    'url'  => "don_woods.html",
                },
                {
                    'text'  => "Verification",
                    'url'   => "verify-code/",
                    'title' => "Code to Verify the Solutions of Games",
                },
            ],
        },
        {
            'text'  => "Online (web-based) Apps",
            'title' => "Use Freecell Solver in your browser!",
            'url'   => "js-fc-solve/",
            'subs'  => [
                {
                    'text'  => "Solver",
                    'url'   => "js-fc-solve/text/",
                    'title' =>
                        "An online solver with graphical and text previews",
                },
                {
                    'text' => "Find a deal’s number",
                    'url'  => "js-fc-solve/find-deal/",
                },
                {
                    'text'  => "API Automated Tests",
                    'url'   => "js-fc-solve/automated-tests/",
                    'title' =>
"Automated tests that can be run in the browser; intended for developers",
                    'hide' => 1,
                    'skip' => 1,
                },
                {
                    'text'  => "API Automated Tests",
                    'url'   => "js-fc-solve/text/gui-tests.xhtml",
                    'title' =>
"Automated tests that can be run in the browser; intended for developers",
                    'hide' => 1,
                    'skip' => 1,
                },
            ],
        },
        {
            'text'  => "FAQ",
            'url'   => "faq.html",
            'title' => "Frequently Asked Questions List",
        },
        {
            'text' => "Documents",
            'url'  => "docs/",
            'subs' => [
                {
                    'text'  => "Arch Doc",
                    'title' => "Architecture Document",
                    'url'   => "arch_doc/",
                },
                {
                    'skip'  => 1,
                    'text'  => "Old Doxygen",
                    'title' => "Hypertext Cross-Reference",
                    'url'   => "michael_mann/",
                },
                {
                    'hide' => 1,
                    'skip' => 1,
                    'text' => "“The Well and the Wall”",
                    'url'  => "docs/Well-and-Wall.html",
                },
            ],
        },
        {
            'text' => "Links",
            'url'  => "links.html",
            'subs' => [
                {
                    'skip' => 1,
                    'text' => "Other Solvers",
                    'url'  => "links.html#other_solvers",
                },
                {
                    'skip' => 1,
                    'text' => "Front Ends",
                    'url'  => "links.html#front_ends",
                },
            ],
        },
        {
            'text'  => "Features",
            'url'   => "features.html",
            'title' => "A List of Freecell Solver Features",
        },
        {
            'text'  => "Contribute",
            'url'   => "contribute/",
            'title' => "Information about contributing to Freecell Solver",
            subs    => [
                {
                    'text'  => "To Do List",
                    'url'   => "to-do.html",
                    'title' =>
"A List of Major Tasks that can be Performed by Intereseted Developers",
                },
                {
                    'text' => "Site Source Code",
                    'url'  => "meta/site-source/",
                },
                {
                    'text'  => "Code of Conduct",
                    'url'   => "code-of-conduct/",
                    'title' => "Code of Conduct and Diversity Statement",
                },
                {
                    'text'  => "Give or Get Academic Credit",
                    'url'   => "getting-credit.html",
                    'title' => (
                              "Getting or Giving Academic Credit for "
                            . "Working on Freecell Solver"
                    ),
                },
            ],
        },
        {
            'text'  => "Support",
            'url'   => "support.html",
            'title' => "Report bugs, get help, and get other support",
            subs    => [
                {
                    'text' => "Forums",
                    'url'  => "forums.html",
                },
            ],
        },
        {
            'separator' => 1,
            'skip'      => 1,
        },
        {
            'text' => "Articles and Reports",
            'url'  => "articles/",
            subs   => [
                {
                    'text' => "How We Benchmark Freecell Solver",
                    'url'  => "articles/how-we-benchmark/v1/",
                },
                {
                    'text'  => "4FC Deals Solvability Statistics",
                    'url'   => "charts/fc-pro--4fc-deals-solvability--report/",
                    'title' =>
"Report: The solvability statistics of the Freecell Pro 4-Freecells Deals",
                },
            ],
        },
        {
            'separator' => 1,
            'skip'      => 1,
        },
        {
            'text' => "Old News Items",
            'url'  => "old-news/",
        },
    ],
};

sub get_params
{
    return (
        'hosts'         => $hosts,
        'tree_contents' => $tree_contents,
    );
}

sub get_hosts
{
    return $hosts;
}

1;
