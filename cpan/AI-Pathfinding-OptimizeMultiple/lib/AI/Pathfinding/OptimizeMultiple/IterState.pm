package AI::Pathfinding::OptimizeMultiple::IterState;

use strict;
use warnings;

use 5.012;

use MooX qw/late/;

use PDL ();

use vars (qw(@fields));

has _main => ( is => 'rw' );
has _num_solved =>
    ( isa => 'Int', is => 'ro', init_arg => 'num_solved', required => 1 );
has _quota => ( isa => 'Int', is => 'ro', init_arg => 'quota', required => 1 );
has _scan_idx =>
    ( isa => 'Int', is => 'ro', init_arg => 'scan_idx', required => 1 );

use Exception::Class ('AI::Pathfinding::OptimizeMultiple::Error::OutOfQuotas');

sub attach_to
{
    my $self     = shift;
    my $main_obj = shift;

    $self->_main($main_obj);

    return;
}

sub get_chosen_struct
{
    my $self = shift;
    return $self->_main->_calc_chosen_scan( $self->_scan_idx, $self->_quota );
}

sub detach
{
    my $self = shift;
    $self->_main(undef);
}

sub idx_slice
{
    my $self = shift;

    my $scans_data = $self->_main()->_scans_data();

    my @dims = $scans_data->dims();

    return $scans_data->slice(
        join( ",", ":", $self->_scan_idx(), ( ("(0)") x ( @dims - 2 ) ) ) );
}

sub update_total_iters
{
    my $state = shift;

    # $r is the result of this scan.
    my $r = $state->idx_slice();

    # Add the total iterations for all the states that were solved by
    # this scan.
    $state->_main()
        ->_add_to_total_iters(
        PDL::sum( ( ( $r <= $state->_quota() ) & ( $r > 0 ) ) * $r ) );

    # Find all the states that weren't solved.
    my $indexes = PDL::which( ( $r > $state->_quota() ) | ( $r < 0 ) );

    # Add the iterations for all the states that have not been solved
    # yet.
    $state->_main()
        ->_add_to_total_iters( $indexes->nelem() * $state->_quota() );

    # Keep only the states that have not been solved yet.
    $state->_main()
        ->_scans_data(
        $state->_main()->_scans_data()->dice( $indexes, "X" )->copy() );
}

sub update_idx_slice
{
    my $state = shift;
    my $r     = $state->idx_slice()->copy();

    # $r cannot be 0, because the ones that were 0, were already solved
    # in $state->update_total_iters().
    my $idx_slice = $state->idx_slice();
    $idx_slice .=
        ( ( $r > 0 ) * ( $r - $state->_quota() ) ) + ( ( $r < 0 ) * ($r) );
}

sub _mark_as_used
{
    my $state = shift;

    $state->_main()->_selected_scans()->[ $state->_scan_idx() ]->mark_as_used();

    return;
}

sub _add_chosen
{
    my $state = shift;

    push @{ $state->_main()->chosen_scans() }, $state->get_chosen_struct();

    return;
}

sub _update_total_boards_solved
{
    my $state = shift;

    $state->_main()->_add_to_total_boards_solved( $state->_num_solved() );

    return;
}

sub _trace_wrapper
{
    my $state = shift;

    $state->_main()->_trace(
        {
            'iters_quota'         => $state->_quota(),
            'selected_scan_idx'   => $state->_scan_idx(),
            'total_boards_solved' => $state->_main()->_total_boards_solved(),
        }
    );

    return;
}

sub register_params
{
    my $state = shift;

    $state->_add_chosen();
    $state->_mark_as_used();
    $state->_update_total_boards_solved();
    $state->_trace_wrapper();

    return;
}

1;

__END__

=pod

=head1 NAME

AI::Pathfinding::OptimizeMultiple::IterState - iteration state object.

=head1 SUBROUTINES/METHODS

=head2 $self->attach_to()

Internal use.

=head2 $self->get_chosen_struct()

Internal use.

=head2 $self->detach()

Internal use.

=head2 $self->idx_slice()

Internal use.

=head2 $self->update_total_iters()

Internal use.

=head2 $self->update_idx_slice()

Internal use.

=head2 $self->register_params()

Internal use.

=cut
