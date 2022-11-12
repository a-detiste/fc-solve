package Games::Solitaire::Verify::Move;

use warnings;
use strict;

=head1 NAME

Games::Solitaire::Verify::Move - a class wrapper for an individual
Solitaire move.

=cut

use parent 'Games::Solitaire::Verify::Base';

use Games::Solitaire::Verify::Exception ();

__PACKAGE__->mk_acc_ref(
    [
        qw(
            source_type
            dest_type
            source
            dest
            num_cards
            _game
        )
    ]
);

=head1 SYNOPSIS

    use Games::Solitaire::Verify::Move;

    my $move1 = Games::Solitaire::Verify::Move->new(
        {
            fcs_string => "Move a card from stack 0 to the foundations",
            game => "freecell",
        },
    );

=head1 FUNCTIONS

=cut

sub _from_fcs_string
{
    my ( $self, $str ) = @_;

    if ( $str =~ m{\AMove a card from stack ([0-9]+) to the foundations\z} )
    {
        my $source = $1;

        $self->source_type("stack");
        $self->dest_type("foundation");

        $self->source($source);
    }
    elsif (
        $str =~ m{\AMove a card from freecell ([0-9]+) to the foundations\z} )
    {
        my $source = $1;

        $self->source_type("freecell");
        $self->dest_type("foundation");

        $self->source($source);
    }
    elsif (
        $str =~ m{\AMove a card from freecell ([0-9]+) to stack ([0-9]+)\z} )
    {
        my ( $source, $dest ) = ( $1, $2 );

        $self->source_type("freecell");
        $self->dest_type("stack");

        $self->source($source);
        $self->dest($dest);
    }
    elsif (
        $str =~ m{\AMove a card from stack ([0-9]+) to freecell ([0-9]+)\z} )
    {
        my ( $source, $dest ) = ( $1, $2 );

        $self->source_type("stack");
        $self->dest_type("freecell");

        $self->source($source);
        $self->dest($dest);
    }
    elsif ( $str =~
        m{\AMove ([0-9]+) cards from stack ([0-9]+) to stack ([0-9]+)\z} )
    {
        my ( $num_cards, $source, $dest ) = ( $1, $2, $3 );

        $self->source_type("stack");
        $self->dest_type("stack");

        $self->source($source);
        $self->dest($dest);
        $self->num_cards($num_cards);
    }
    elsif ( $str =~
        m{\AMove the sequence on top of Stack ([0-9]+) to the foundations\z} )
    {
        my $source = $1;

        $self->source_type("stack_seq");
        $self->dest_type("foundation");

        $self->source($source);
    }
    else
    {
        Games::Solitaire::Verify::Exception::Parse::FCS->throw(
            error => "Cannot parse 'FCS' String", );
    }
}

sub _init
{
    my ( $self, $args ) = @_;

    $self->_game( $args->{game} );

    if ( exists( $args->{fcs_string} ) )
    {
        return $self->_from_fcs_string( $args->{fcs_string} );
    }
    return ();
}

=head1 METHODS

=head2 $move->source_type()

Accessor for the solitaire card game's board layout's type -
C<"stack">, C<"freecell">, etc. used in the layout.

=head2 $move->dest_type()

Accessor for the destination type - C<"stack">, C<"freecell">,
C<"destination">.

=head2 $move->source()

The index number of the source.

=head2 $move->dest()

The index number of the destination.

=head2 $move->num_cards()

Number of cards affects - only relevant for a stack-to-stack move usually.

=cut

1;    # End of Games::Solitaire::Verify::Move
