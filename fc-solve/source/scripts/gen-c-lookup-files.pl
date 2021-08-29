#!/usr/bin/env perl

use 5.014;
use strict;
use warnings;
use autodie;

package Code::Gen::Emitter;

use Moo;

has lang    => ( is => 'ro', required => 1 );
has is_rust => (
    is      => 'lazy',
    default => sub {
        return shift()->lang eq 'rust';
    },
);
has typedefs       => ( is => 'ro', required => 1 );
has header_headers => ( is => 'ro', required => 1 );

my %lang_map = (
    'c' => {
        start_array => '{',
        end_array   => '}',
    },
    'rust' => {
        start_array => '[',
        end_array   => ']',
    },
);
has lang_record => (
    is      => 'lazy',
    default => sub {
        return $lang_map{ shift()->lang() };
    },
);

sub calc_headers_code
{
    my ($self) = @_;

    return join( '', map { qq{#include $_\n} } @{ $self->header_headers } );
}

sub calc_c_header_start
{
    my ($self) = @_;

    return
          "#pragma once\n"
        . $self->calc_headers_code()
        . $self->calc_typedefs_code();
}

sub calc_typedefs_code
{
    my ($self) = @_;

    return $self->typedefs();
}

sub lookup_lang_field
{
    my ( $self, $field ) = @_;

    return $self->lang_record()->{$field};
}

has start_array => (
    is      => 'lazy',
    default => sub {
        return shift()->lookup_lang_field('start_array');
    },
);
has end_array => (
    is      => 'lazy',
    default => sub {
        return shift()->lookup_lang_field('end_array');
    },
);

sub data2code
{
    my ( $self, $val ) = @_;
    return (
        ( ref($val) eq "ARRAY" )
        ? ( $self->start_array()
                . join( ',', map { $self->data2code($_) } @$val )
                . $self->end_array() )
        : $val
    );
}

package main;

use Path::Tiny qw/ path /;

my $false = 0;
my $true  = 1;

my $MAX_RANK              = $ENV{FCS_MAX_RANK} || 13;
my $NUM_SUITS             = 4;
my @SUITS                 = ( 0 .. $NUM_SUITS - 1 );
my @RANKS                 = ( 1 .. $MAX_RANK );
my @PARENT_RANKS          = ( 2 .. $MAX_RANK );
my $MAX_NUM_DECKS         = 1;
my $FCS_POS_BY_RANK_WIDTH = ( $MAX_NUM_DECKS << 3 );

sub make_card
{
    my ( $rank, $suit ) = @_;
    return ( ( $rank << 2 ) | $suit );
}

sub key
{
    my ( $parent, $child ) = @_;
    return "${parent}\t${child}";
}

my $NUM_CHILD_CARDS  = 64;
my $NUM_PARENT_CARDS = make_card( $MAX_RANK, $SUITS[-1] ) + 1;
my @is_king          = ( ($false) x $NUM_PARENT_CARDS );
my %lookup;
my %fcs_is_ss_false_parent;
my %fcs_is_ss_true_parent;
my @state_pos = ( map { [ (0) x $NUM_SUITS ] } 0 .. $MAX_RANK );
my @card_pos;
my @positions_by_rank__lookup;
my @pos_by_rank;

foreach my $parent_suit (@SUITS)
{
    foreach my $parent_rank (@RANKS)
    {
        my $parent = make_card( $parent_rank, $parent_suit );
        $is_king[$parent] = ( $parent_rank == $MAX_RANK ? $true : $false );
        $state_pos[$parent_rank][$parent_suit] = $card_pos[$parent] =
            $parent_rank - 1 + $parent_suit * $MAX_RANK;

        $positions_by_rank__lookup[$parent] =
            ($FCS_POS_BY_RANK_WIDTH) * ( $parent_rank - 1 ) +
            ( $parent_suit << 1 );

        my $start    = $FCS_POS_BY_RANK_WIDTH * $parent_rank;
        my $end      = $start + $FCS_POS_BY_RANK_WIDTH;
        my $offset_s = $start + ( ( ( $parent_suit & 0b1 ) ^ 0b1 ) << 1 );

        $pos_by_rank[$parent] = { start => $offset_s, end => $end };
        if ( $parent_rank > 1 )
        {
            my $start = ( ( $parent_suit ^ 0x1 ) & ( ~0x2 ) );
            foreach my $child_rank ( $parent_rank - 1 )
            {
                foreach my $child_suit ( $start, $start + 2 )
                {
                    $lookup{ key( $parent,
                            make_card( $child_rank, $child_suit ), ) } = $true;
                }
                foreach my $child_suit ($parent_suit)
                {
                    $fcs_is_ss_true_parent{ key( $parent,
                            make_card( $child_rank, $child_suit ), ) } = $true;
                }
                foreach my $child_suit (@SUITS)
                {
                    $fcs_is_ss_false_parent{ key( $parent,
                            make_card( $child_rank, $child_suit ), ) } = $true;
                }
            }
        }
    }
}

sub emit
{
    my ( $args, ) = @_;

    my $obj = Code::Gen::Emitter->new(
        {
            header_headers => ( $args->{header_headers} // ( die "foo" ) ),
            lang           => ( $args->{lang}           // 'c' ),
            typedefs       => ( $args->{typedefs}       // '' ),
        }
    );
    my $bn   = $args->{basename};
    my $DECL = ( ( $obj->is_rust() ? "pub " : "" ) . "const " . $args->{decl} );
    my $is_static = $args->{is_static};
    my $contents  = $args->{contents};

    my $header_fn = "$bn.h";

    my $out_header = sub {
        my $text = shift;
        path($header_fn)
            ->spew_utf8( $obj->calc_c_header_start() . join( '', @$text ) );

    };
    my $code = "$DECL = " . $obj->data2code( $contents, ) . ";\n";
    if ( $obj->is_rust )
    {
        path("$bn.rs")
            ->spew_utf8(
qq#// Generated by https://github.com/shlomif/fc-solve/blob/master/fc-solve/source/scripts/gen-c-lookup-files.pl\n// DO NOT MODIFY DIRECTLY!\n$code#
            );
    }
    elsif ($is_static)
    {
        $out_header->( ["static $code"] );
    }
    else
    {
        $out_header->( ["extern $DECL;\n"] );
        path("$bn.c")->spew_utf8(qq/#include "$header_fn"\n\n$code/);
    }
    return;
}

emit(
    {
        basename => 'simple_simon_rank_seqs',
        decl => "fcs_card simple_simon_rank_seqs[FCS_NUM_SUITS][FCS_MAX_RANK]",
        contents => [
            map {
                my $s = $_;
                [ map { make_card( $_, $s ) } reverse( 1 .. $MAX_RANK ) ]
            } @SUITS
        ],
        header_headers => [],
        is_static      => $true,
    }
);

sub emit_lookup
{
    my ( $array_name, $basename, $lookup_ref, ) = @_;
    return emit(
        {
            basename => $basename,
            decl => qq#bool ${array_name}[$NUM_PARENT_CARDS][$NUM_CHILD_CARDS]#,
            header_headers => [ q/<stdbool.h>/, ],
            is_static      => $false,
            contents       => [
                map {
                    my $parent = $_;
                    [
                        map {
                            exists( $lookup_ref->{ key( $parent, $_ ) } )
                                ? 'true'
                                : 'false'
                        } ( 0 .. $NUM_CHILD_CARDS - 1 )
                    ]
                } ( 0 .. $NUM_PARENT_CARDS - 1 )
            ],
        },
    );
}

emit_lookup( 'fc_solve_is_parent_buf', 'is_parent', \%lookup );
emit_lookup( 'fc_solve_is_ss_false_parent', 'fcs_is_ss_false_parent',
    \%fcs_is_ss_false_parent );
emit_lookup( 'fc_solve_is_ss_true_parent', 'fcs_is_ss_true_parent',
    \%fcs_is_ss_true_parent );
emit(
    {
        basename => 'debondt__state_pos',
        decl => qq#size_t fc_solve__state_pos[@{[$MAX_RANK+1]}][$NUM_SUITS]#,
        header_headers => [ q/<stddef.h>/, ],
        contents       => [ map { [@$_] } @state_pos ],
    },
);

sub _array
{
    my ($args)   = @_;
    my $DECL     = $args->{decl};
    my $lang     = $args->{lang} // 'c';
    my $contents = $args->{contents};
    my $type     = $args->{type};
    my $len      = @$contents;
    return (
        decl => (
            "${DECL}" . ( $lang eq 'rust' ? ": [$type;$len]" : "[$len]" )
        ),
        contents       => $contents,
        header_headers => [ q/<stddef.h>/, ],
    );
}

emit(
    {
        basename => 'debondt__card_pos',
        _array(
            {
                decl     => qq#size_t fc_solve__card_pos#,
                contents => [ map { $_ || 0 } @card_pos ],
            }
        ),
    },
);
emit(
    {
        basename => 'pos_by_rank__lookup',
        _array(
            {
                decl     => qq#size_t positions_by_rank__lookup#,
                contents => [ map { $_ || 0 } @positions_by_rank__lookup ],
            }
        ),
    },
);

emit(
    {
        basename => 'pos_by_rank__freecell',
        _array(
            {
                decl     => qq#pos_by_rank__freecell_t pos_by_rank__freecell#,
                contents => [
                    map {
                        my $s = $_ || +{ start => 0, end => 0 };
                        "{.start = $s->{start}, .end = $s->{end}}";
                    } @pos_by_rank
                ],
            }
        ),
        typedefs =>
"\ntypedef struct { size_t start, end; } pos_by_rank__freecell_t;\n",
    },
);

{
    my $TYPE_NAME  = 'fcs_seq_cards_power_type';
    my $ARRAY_NAME = 'fc_solve_seqs_over_cards_lookup';
    my $POWER      = 1.3;
    my $TOP        = 2 * $MAX_RANK * 4 + 1;
    emit(
        {
            basename => 'rate_state',
            _array(
                {
                    decl     => "$TYPE_NAME ${ARRAY_NAME}",
                    contents => [ map { $_**$POWER } ( 0 .. $TOP - 1 ) ],
                }
            ),
            typedefs =>
"\ntypedef double $TYPE_NAME;\n#define FCS_SEQS_OVER_RENEGADE_POWER(n) ${ARRAY_NAME}[(n)]\n",
        },
    );
}

emit(
    {
        basename => 'is_king',
        _array(
            {
                decl     => qq#bool fc_solve_is_king_buf#,
                contents => [ map { $_ ? 'true' : 'false' } @is_king ],
            }
        ),
        header_headers => [ q/<stdbool.h>/, ],
    },
);

{
    my @_board_gen_lookup = (
        contents => [
            map {
                my $i   = $_;
                my $col = ( $i & ( 8 - 1 ) );
                3 * ( $col * 7 -
                        ( ( $col > 4 ) ? ( $col - 4 ) : 0 ) +
                        ( $i >> 3 ) )
            } 0 .. ( 52 - 1 )
        ],
    );

    sub _board_gen_lookup_array
    {
        my ($opts) = @_;
        return _array( { @_board_gen_lookup, %{$opts}, } );
    }

}
{
    my @board_gen_lookup_args = (
        basename       => 'board_gen_lookup1',
        header_headers => [],
    );

    sub _emit_board_gen_lookup
    {
        my ($args) = @_;
        my @lang = ( lang => ( $args->{lang} // 'c' ), );
        return emit(
            {
                @board_gen_lookup_args,
                @lang,
                is_static => ( $args->{is_static} ),
                _board_gen_lookup_array(
                    {
                        decl => $args->{decl},
                        @lang,
                        type => ( $args->{type} // '' ),
                    }
                ),
            }
        );
    }
}
_emit_board_gen_lookup(
    {
        lang      => 'rust',
        is_static => $false,
        decl      => 'OFFSET_BY_I',
        type      => "usize",
    }
);
_emit_board_gen_lookup(
    {
        lang      => 'c',
        is_static => $true,
        decl      => 'size_t offset_by_i',
    }
);
