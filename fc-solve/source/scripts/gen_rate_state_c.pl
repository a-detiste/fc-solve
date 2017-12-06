use strict;
use warnings;
use autodie;
use File::Spec ();
use Path::Tiny qw/ path /;
use List::Util qw/ product sum /;

my $src_dir = shift(@ARGV);

sub fn
{
    return File::Spec->catfile( $src_dir, shift() );
}

my $text = path( fn("rate_state.h") )->slurp_utf8;

my $type_name  = 'fc_solve_seq_cards_power_type_t';
my $array_name = 'fc_solve_seqs_over_cards_lookup';
my $POWER      = 1.3;
my ( $decl, $limit ) = $text =~
    m/^extern\s+(const\s+\Q$type_name\E\s+\Q$array_name\E\[([^\]]+)\]);\s*$/ms;

if ( !defined($limit) )
{
    die "Could not match limit";
}

my $TOP = sum(
    map {
        product(
            map {
                if ( my ($n) = /\A([1-9][0-9]*)\z/ )
                {
                    $n;
                }
                else
                {
                    die "not an integer - $_!";
                }
                } split / *\* */,
            $_
            )
        } split / *\+ */,
    $limit
);

my @data = ( map { $_**$POWER } ( 0 .. $TOP - 1 ) );

path("rate_state.c")->spew_utf8(<<"EOF");
// This file was generated by gen_rate_state_c.pl .
// Do not modify directly.
#include "rate_state.h"

// This contains the exponents of the first few integers to the power
// of $POWER
$decl =
{
@{[join(", ", @data)]}
};
EOF
