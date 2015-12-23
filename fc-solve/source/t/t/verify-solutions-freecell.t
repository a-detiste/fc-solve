#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Carp (qw/confess/);
use Data::Dumper (qw/Dumper/);
use String::ShellQuote (qw/shell_quote/);
use File::Spec ();
use File::Basename qw( dirname );

use Games::Solitaire::Verify::Solution;

sub verify_solution_test
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $args = shift;
    my $msg = shift;

    my $board = $args->{board};
    my $deal = $args->{deal};
    my $msdeals = $args->{msdeals};

    if (! defined($board))
    {
        if (!defined($deal))
        {
            confess "Neither Deal nor board are specified";
        }
        if ($deal !~ m{\A[1-9][0-9]*\z})
        {
            confess "Invalid deal $deal";
        }
    }

    my $theme = $args->{theme} || ["-l", "gi"];

    my $variant = $args->{variant}  || "freecell";
    my $is_custom = ($variant eq "custom");
    my $variant_s = $is_custom ? "" : "-g $variant";

    my $fc_solve_exe = shell_quote($ENV{'FCS_PATH'} . "/fc-solve");

    open my $fc_solve_output,
        ($msdeals ?
            "pi-make-microsoft-freecell-board $deal | " :
            ($board ? "" : "make_pysol_freecell_board.py $deal $variant | ")
        ) .
        "$fc_solve_exe $variant_s " . shell_quote(@$theme) . " -p -t -sam " .
        ($board ? shell_quote($board) : "") .
        " |"
        or Carp::confess "Error! Could not open the fc-solve pipeline";

    # Initialise a column
    my $solution = Games::Solitaire::Verify::Solution->new(
        {
            input_fh => $fc_solve_output,
            variant => $variant,
            ($is_custom ? (variant_params => $args->{variant_params}) : ()),
        },
    );

    my $verdict = $solution->verify();
    my $test_verdict = ok (!$verdict, $msg);

    if (!$test_verdict)
    {
        diag("Verdict == " . Dumper($verdict));
    }

    close($fc_solve_output);

    return $test_verdict;
}

my $data_dir = File::Spec->catdir( dirname( __FILE__), 'data' );

sub _path_to_board
{
    my $fn = shift;

    return
        File::Spec->catfile(
            $data_dir,
            "sample-boards",
            $fn
        );
}

# TEST
verify_solution_test(
    {
        board => _path_to_board(
            "24-mid-with-colons.board",
        ),
    },
    "Accepting a board with leading colons as directly input from the -p -t solution",
);

# TEST
verify_solution_test(
    {
        board => _path_to_board(
            "larrysan-kings-only-0-freecells-unlimited-move.txt",
        ),
        theme => [qw(--freecells-num 0 --empty-stacks-filled-by kings --sequence-move unlimited)],
        variant => "custom",
        variant_params =>
            Games::Solitaire::Verify::VariantParams->new(
                {
                    'num_decks' => 1,
                    'num_columns' => 8,
                    'num_freecells' => 0,
                    'sequence_move' => "unlimited",
                    'seq_build_by' => "alt_color",
                    'empty_stacks_filled_by' => "kings",
                }
            ),

    },
    "sequence move unlimited is indeed unlimited (even if not esf-by-any)."
);

# TEST
verify_solution_test(
    {deal => 1, variant => "simple_simon",
        theme => ["-l", "tlm",],
    },
    "Simple Simon #1 using the 'the-last-mohican' theme",
);


# TEST
verify_solution_test(
    {deal => 24, theme => ["-nht",],
    },
    "Testing a solution with the -nht flag.",
);

# TEST
verify_solution_test(
    { deal => 254076, msdeals => 1,
        theme => ["-l", "by", "--scans-synergy", "dead-end-marks"],
    },
    "There is a solution for 254,076 with -l by and a scans synergy.",
);

# This command line theme yields an especially short solution to the
# previously intractable deal #12 .
# TEST
verify_solution_test(
    {
        deal => 12,
        theme => [qw(--freecells-num 2 -to '[012][347]' --method random-dfs -seed 33)],
        variant => "custom",
        msdeals => 1,
        variant_params =>
        Games::Solitaire::Verify::VariantParams->new(
            {
                'num_decks' => 1,
                'num_columns' => 8,
                'num_freecells' => 2,
                'sequence_move' => "limited",
                'seq_build_by' => "alt_color",
                'empty_stacks_filled_by' => "any",
            }
        ),
    },
    "Checking the 2-freecells '-seed 33' preset."
);

# This command line theme yields an ever shorter solution to the
# previously intractable deal #12 .
# TEST
verify_solution_test(
    {
        deal => 12,
        theme => [qw(--freecells-num 2 -to '[012][347]' --method random-dfs -seed 236)],
        variant => "custom",
        msdeals => 1,
        variant_params =>
        Games::Solitaire::Verify::VariantParams->new(
            {
                'num_decks' => 1,
                'num_columns' => 8,
                'num_freecells' => 2,
                'sequence_move' => "limited",
                'seq_build_by' => "alt_color",
                'empty_stacks_filled_by' => "any",
            }
        ),
    },
    "Checking the 2-freecells '-seed 236' preset."
);


# TEST
verify_solution_test({
        deal => 24,
        theme => ["--set-pruning", "r:tf"],
    },
    "Solving Deal #24 with set-pruning run-to-founds",
);

# TEST
verify_solution_test({
        deal => 1,
        theme => ["--set-pruning", "r:tf"],
    },
    "Solving Deal #1 with set-pruning run-to-founds",
);

# TEST
verify_solution_test({
        deal => 1,
        theme => ["--method", "a-star", "--set-pruning", "r:tf"],
    },
    "Solving Deal #1 with --method a-star and set-pruning run-to-founds",
);

# TEST
verify_solution_test({deal => 246, theme => ["-l", "eo"],},
    "Solving Deal #246 with the enlightened-ostrich"
);

# TEST
verify_solution_test(
    {
        deal => 24,
        theme => ["--method", "patsolve",],
    },
    "Solving Deal #24 with patsolve"
);

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008 Shlomi Fish

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

