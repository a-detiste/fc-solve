package MyNavData;

use strict;
use warnings;

my $hosts =
{
    'fc-solve' =>
    {
        'base_url' => "http://fc-solve.berlios.de",
    },
};

my $tree_contents =
{
    'host' => "fc-solve",
    'text' => "Freecell Solver",
    'title' => "Freecell Solver",
    'show_always' => 1,
    'subs' =>
    [
        {
            'text' => "Home",
            'url' => "",
        },
        {
            'text' => "Downloads",
            'url' => "download.html",
            'subs' =>
            [
                {
                    'text' => "Don Woods' Solver",
                    'url' => "don_woods.html",
                },
                {
                    'text' => "PySol Integration",
                    'url' => "pysol/",
                },
                {
                    'text' => "Verification",
                    'url' => "verify-code/",
                    'title' => "Code to Verify the Solutions of Games",
                },
            ],
        },
        {
            'text' => "FAQ",
            'url' => "faq.html",
            'title' => "Frequently Asked Questions List",
        },
        {
            'text' => "Documents",
            'url' => "docs/",
            'subs' =>
            [
                {
                    'text' => "Arch Doc",
                    'title' => "Architecture Document",
                    'url' => "arch_doc/",
                },
                {
                    'text' => "Doxygen",
                    'title' => ("Hypertext documentation for the Freecell " .
                        "Solver code generated by Doxygen"),
                    'url' => "http://fc-solve.berlios.de/michael_mann/",
                    'url_is_abs' => 1,
                    'skip' => 1,
                },
            ],
        },
        {
            'text' => "Links",
            'url' => "links.html",
            'subs' =>
            [
                {
                    'text' => "Other Solvers",
                    'url' => "links.html#other_solvers",
                },
                {
                    'text' => "Front Ends",
                    'url' => "links.html#front_ends",
                },
            ],
        },
        {
            'text' => "Features",
            'url' => "features.html",
            'title' => "A Feature List of Freecell Solver",
        },
        {
            'text' => "To Do List",
            'url' => "to-do.html",
            'title' => "A List of Major Tasks that can be Performed by Interesetd Developers",
        },
        {
            'text' => "Status",
            'url' => "current-status.html",
            'title' => "What is the current status of Freecell Solver? Is it dead?",
        },
        {
            'text' => "Support",
            'url' => "support.html",
            'title' => "Report bugs, get help and get other support",
        },
        {
            'text' => "Code of Conduct",
            'url' => "code-of-conduct/",
            'title' => "Code of Conduct and Diversity Statement",
        },
        {
            'text' => "Give or Get Academic Credit",
            'url' => "getting-credit.html",
            'title' => ("Getting or Giving Academic Credit for " .
                "Working on Freecell Solver"),
        },
        {
            'separator' => 1,
            'skip' => 1,
        },
        {
            'text' => "The Book",
            'url' => "book.html",
        },
        {
            'text' => "Old News Items",
            'url' => "old-news.html",
        },
    ],
};

sub get_params
{
    return
        (
            'hosts' => $hosts,
            'tree_contents' => $tree_contents,
        );
}

sub get_hosts
{
    return $hosts;
}

1;
