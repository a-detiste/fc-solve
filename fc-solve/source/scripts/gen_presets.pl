#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long qw/ GetOptions /;
use Template;

my %presets = (
    'bakers_game'  => [qw(i freecell sbb suit)],
    'bakers_dozen' => [
        qw(s 13 f 0 d 1 sbb rank sm limited esf none to 0123456789 at 0123456789)
    ],
    'beleaguered_castle' => [qw(i freecell sbb rank f 0)],
    'cruel'              => [qw(i bakers_dozen s 12 sbb suit)],
    'der_katzenschwanz'  => [qw(i die_schlange sm unlimited)],
    'die_schlange'       => [qw(i freecell f 8 s 9 d 2 esf none)],
    'eight_off'          => [qw(i kings_only_bakers_game f 8)],
    'fan'      => [qw(i freecell s 18 sbb suit sm limited esf kings_only f 0)],
    'forecell' => [qw(i freecell esf kings_only)],
    'freecell' => [
        qw(s 8 f 4 d 1 sbb ac sm limited esf any_card to [01][23456789] at 0123456789ABCDE)
    ],
    'good_measure'            => [qw(i bakers_dozen s 10)],
    'kings_only_bakers_game'  => [qw(i bakers_game esf kings_only)],
    'relaxed_freecell'        => [qw(i freecell sm unlimited)],
    'relaxed_seahaven_towers' => [qw(i seahaven_towers sm unlimited)],
    'seahaven_towers'         => [qw(i bakers_game esf kings_only s 10)],
    'simple_simon' => [qw(i bakers_game s 10 f 0 to abcdefgh at abcdefghi)],

    # 'yukon' => [ qw(i freecell s 7 f 0 to ABCDEFG) ],
);

my @strings;

sub compile_preset
{
    my $preset_name = shift;
    my $preset      = $presets{$preset_name};

    # For inheritance
    my $compiled = shift || {};

    my @params = @{$preset};
    eval {
        while ( my $cmd = shift(@params) )
        {
            my $arg = shift(@params);

            if ( $cmd =~ /^(?:i|inherits?)$/ )
            {
                if ( !exists( $presets{$arg} ) )
                {
                    die "Unknown inheritor!\n";
                }
                compile_preset( $arg, $compiled );
            }
            elsif ( $cmd =~ /^(?:s|stacks?)$/ )
            {
                if ( $arg !~ /^[0-9]+$/ )
                {
                    die "Argument to stacks is not an integer!\n";
                }
                $compiled->{'stacks'} = $arg;
            }
            elsif ( $cmd =~ /^(?:f|freecells?)$/ )
            {
                if ( $arg !~ /^[0-9]+$/ )
                {
                    die "Argument to freecells is not an integer!\n";
                }
                $compiled->{'freecells'} = $arg;
            }
            elsif ( $cmd =~ /^(?:d|decks?)$/ )
            {
                if ( $arg !~ /^(?:1|2)$/ )
                {
                    die "Argument to decks is not 1 or 2!\n";
                }
                $compiled->{'decks'} = $arg;
            }
            elsif ( $cmd =~ /^(?:sbb|seqs_build_by)$/ )
            {
                if ( $arg !~ /^(?:ac|suit|rank)$/ )
                {
                    die "Argument to stacks_build_by is improper!\n";
                }
                $compiled->{'seqs_build_by'} = $arg;
            }
            elsif ( $cmd =~ /^(?:sm|(?:seq|sequence)_move)$/ )
            {
                if ( $arg !~ /^(?:limited|unlimited)$/ )
                {
                    die "Argument to sequence move is not limited/unlimited!\n";
                }
                $compiled->{'sequence_move'} =
                    ( ( $arg eq "unlimited" ) ? 1 : 0 );
            }
            elsif ( $cmd =~ /^(?:esf|empty_stacks_fill(?:ed(?:_by)?)?)$/ )
            {
                if ( $arg !~ /^(?:any_card|kings_only|none)$/ )
                {
                    die "Improper parameter to Empty Stacks Filled By!\n";
                }
                $compiled->{'empty_stacks_fill'} = $arg;
            }
            elsif ( $cmd =~ /^(?:to|tests_order)$/ )
            {
                if ( $arg =~ /[^0-9a-hA-G\[\(\)\]]/ )
                {
                    die "Unrecognized character in Tests order!\n";
                }
                $compiled->{'tests_order'} = $arg;
            }
            elsif ( $cmd =~ /^(?:at|allowed_tests)$/ )
            {
                if ( $arg =~ /[^0-9a-iA-G]/ )
                {
                    die "Unrecognized character in Allowed Tests!\n";
                }
                $compiled->{'allowed_tests'} = $arg;
            }
            else
            {
                die "Unknown Command $cmd\n";
            }
        }
    };

    if ($@)
    {
        die "Preset Name: $preset_name\n$@";
    }

    return $compiled;
}

my $c_template = Template->new();

my $c_template_input = <<"EOF";
    {
        [% preset %],
        MAKE_GAME_PARAMS(
            [% fc %],
            [% s %],
            [% d %],

            [% sbb %],
            [% sm %],
            [% esf %]
        ),

        [% tests_order %],
        [% allowed_tests %]
    }
EOF

sub preset_to_string
{
    my ( $preset_name, $pc ) = @_;

    my @lines;
    eval {
        push @lines, ( "FCS_PRESET_" . uc($preset_name) );

        if ( !exists( $pc->{'freecells'} ) )
        {
            die "Freecells were not defined!\n";
        }
        push @lines, $pc->{'freecells'};

        if ( !exists( $pc->{'stacks'} ) )
        {
            die "Stacks were not defined!\n";
        }
        push @lines, $pc->{'stacks'};

        if ( !exists( $pc->{'decks'} ) )
        {
            die "Decks Number was not defined!\n";
        }
        push @lines, $pc->{'decks'};

        if ( !exists( $pc->{'seqs_build_by'} ) )
        {
            die "Seqs Build by was not defined!\n";
        }
        my $arg = $pc->{'seqs_build_by'};
        push @lines,
            (
            "FCS_SEQ_BUILT_BY_"
                . (
                  ( $arg eq "ac" )   ? "ALTERNATE_COLOR"
                : ( $arg eq "suit" ) ? "SUIT"
                :                      "RANK"
                )
            );

        if ( !exists( $pc->{'sequence_move'} ) )
        {
            die "Sequence move was not defined!\n";
        }
        push @lines, $pc->{'sequence_move'};

        if ( !exists( $pc->{'empty_stacks_fill'} ) )
        {
            die "Empty Stacks Fill is undefined!\n";
        }
        my $esf = $pc->{'empty_stacks_fill'};
        push @lines,
            "FCS_ES_FILLED_BY_"
            . (
              ( $esf eq "none" )     ? "NONE"
            : ( $esf eq "any_card" ) ? "ANY_CARD"
            :                          "KINGS_ONLY"
            );

        if ( !exists( $pc->{'tests_order'} ) )
        {
            die "Tests order is undefined!\n";
        }
        push @lines, "\"" . $pc->{'tests_order'} . "\"";

        if ( !exists( $pc->{'allowed_tests'} ) )
        {
            die "Allowed Tests' is undefined!\n";
        }
        push @lines, "\"" . $pc->{'allowed_tests'} . "\"";
    };

    if ($@)
    {
        die "Preset name: $preset_name\n$@\n";
    }

    my %vars;
    @vars{qw(preset fc s d sbb sm esf tests_order allowed_tests)} = @lines;

    my $ret;
    $c_template->process( \$c_template_input, \%vars, \$ret );
    $ret =~ s{\s+\z}{}ms;
    return $ret;
}

sub preset_to_docbook_string
{
    my ( $preset_name, $pc ) = @_;
    my @lines;

    push @lines,
        join( " ", ( map { ucfirst($_) } split( /_/, $preset_name ) ) );

    push @lines, ( $pc->{'stacks'}, $pc->{'freecells'}, $pc->{'decks'} );

    my $sbb = $pc->{'seqs_build_by'};
    push @lines,
        (
          ( $sbb eq "ac" )   ? "Alternate Colour"
        : ( $sbb eq "suit" ) ? "Suit"
        :                      "Rank"
        );

    my $arg = $pc->{'empty_stacks_fill'};
    push @lines,
        (
          ( $arg eq "none" )     ? "None"
        : ( $arg eq "any_card" ) ? "Any Card"
        :                          "Kings Only"
        );

    push @lines, ( $pc->{'sequence_move'} ? "Limited" : "Unlimited" );

    return join( "", map { "    <entry>$_</entry>\n" } @lines );
}

sub preset_to_perl_module
{
    my ( $preset_name, $pc ) = @_;

    my %sbb_map = (
        'ac'   => "alt_color",
        'suit' => "suit",
        'rank' => "rank",
    );

    my $sbb = $sbb_map{ $pc->{'seqs_build_by'} }
        or die "Hoola";

    my %esf_map = (
        'kings_only' => "kings",
        'none'       => "none",
        'any_card'   => "any",
    );
    my $esf = $esf_map{ $pc->{'empty_stacks_fill'} }
        or die "BlahBlajjor";

    my $seq_move = $pc->{sequence_move} ? "unlimited" : "limited";

    my $simple_simon = "";

    if ( $preset_name eq "simple_simon" )
    {
        $simple_simon = <<'EOF';
                'rules' => "simple_simon",
EOF

        chomp($simple_simon);
    }

    my $ret_val = <<"EOF";
    "$preset_name" =>
        Games::Solitaire::Verify::VariantParams->new(
            {
                'num_decks' => $pc->{decks},
                'num_columns' => $pc->{stacks},
                'num_freecells' => $pc->{freecells},
                'sequence_move' => "$seq_move",
                'seq_build_by' => "$sbb",
                'empty_stacks_filled_by' => "$esf",
$simple_simon
            }
        ),
EOF

    $ret_val =~ s{\n\s*\n}{\n}gms;

    return $ret_val;
}

sub preset_to_pod
{
    my ($preset_name) = @_;
    return "=item * $preset_name\n\n";
}

my $mode = "c";
my $output_fn;

GetOptions(
    'mode=s'   => \$mode,
    'output=s' => \$output_fn,
) or die "Failed to get options - $!";

my %mode_callbacks = (
    "c"        => \&preset_to_string,
    "docbook"  => \&preset_to_docbook_string,
    "perl-mod" => \&preset_to_perl_module,
    "pod"      => \&preset_to_pod,
);

if ( not exists $mode_callbacks{$mode} )
{
    die "Unknown mode '$mode'!";
}

my $out_fh;
if ( !defined $output_fn )
{
    $out_fh = *STDOUT;
}
else
{
    open $out_fh, '>', $output_fn
        or die "Cannot open '$output_fn' for writing.";
}

PRESETS_LOOP:
foreach my $preset_name ( sort { $a cmp $b } keys(%presets) )
{
    if ( $preset_name eq "simple_simon" and $mode eq "docbook" )
    {
        next PRESETS_LOOP;
    }

    my $preset_compiled = compile_preset($preset_name);
    push @strings, $mode_callbacks{$mode}->( $preset_name, $preset_compiled );
}

if ( $mode eq "docbook" )
{
    print join( "", map { "<row>\n$_</row>\n" } @strings );
}
elsif ( $mode eq "c" )
{
    print {$out_fh} <<"EOF";
// This file was auto-generated by gen_presets.pl. DO NOT EDIT BY HAND

static const fcs_preset_t fcs_presets[@{[0+@strings]}] =
{
@{[join( ",\n", @strings )]}
};
EOF
}
elsif ( $mode eq "perl-mod" )
{
    print "my %variants_map =\n";
    print "(\n";
    print join( "", @strings );
    print ");\n";
}
elsif ( $mode eq "pod" )
{
    print "=head1 PARAMETERS\n\n";
    print "=head2 Variants IDs\n\n";
    print "This is a list of the available variant IDs.\n\n";
    print "=over 4\n\n";
    print join( "", @strings );
    print "=back\n\n";
}

close($out_fh);

__END__

=head1 COPYRIGHT AND LICENSE

This file is part of Freecell Solver. It is subject to the license terms in
the COPYING.txt file found in the top-level directory of this distribution
and at http://fc-solve.shlomifish.org/docs/distro/COPYING.html . No part of
Freecell Solver, including this file, may be copied, modified, propagated,
or distributed except according to the terms contained in the COPYING file.

Copyright (c) 2000 Shlomi Fish

=cut
