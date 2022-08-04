package PrepareAppAws;

use strict;
use warnings;

use Getopt::Long  qw/ GetOptions /;
use MooX          qw/ late /;
use PrepareCommon ();

has 'fcc_solver'        => ( is => 'ro', isa => 'Bool', default => '' );
has 'disable_threading' => ( is => 'ro', isa => 'Bool', default => '' );
has 'num_freecells'     => ( is => 'ro', isa => 'Int',  default => 4 );
has 'deals'          => ( is => 'ro', isa => 'ArrayRef[Int]', required => 1 );
has 'deal_num_width' => ( is => 'ro', isa => 'Int',           default  => 0 );
has compiler => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
        return ( $ENV{CC} // 'gcc' );
    },
);

sub run
{
    my ($self) = @_;

    my $flto = 0;

    my $who = 'sub';

    my $mem         = 200;
    my $num_threads = 4;
    my $num_hours   = 120;

    my $march_flag = "-march=native";

    GetOptions(
        'flto!' => \$flto,
        'who=s' => \$who,
        'mem=i' => \$mem,
    ) or die "No arguments";

    if ( !defined($who) )
    {
        die "Unknown who.";
    }

    my $sub   = 1;
    my $is_am = 0;

    my $depth_dbm = 1;

    if ( $who eq 'am' )
    {
        $is_am = 1;
        $sub   = 0;
    }

    my $dest_dir_base = 'dbm_fcs_dist';
    if ($sub)
    {
        $flto        = 1;
        $num_threads = 24;
        $mem         = 500;
        $num_hours   = 700;
    }
    elsif ($is_am)
    {
        $flto        = 0;
        $num_threads = 16;
        $mem         = 64;
        $num_hours   = 700;
        $march_flag  = '';
    }
    if ( $self->disable_threading )
    {
        $num_threads = 1;
    }
    return PrepareCommon->new(
        {
            fcc_solver        => scalar( $self->fcc_solver ),
            compiler          => $self->compiler,
            depth_dbm         => $depth_dbm,
            dest_dir_base     => $dest_dir_base,
            flto              => $flto,
            num_threads       => $num_threads,
            mem               => $mem,
            num_hours         => $num_hours,
            march_flag        => $march_flag,
            deals             => $self->deals,
            num_freecells     => $self->num_freecells,
            deal_num_width    => $self->deal_num_width,
            disable_threading => scalar( $self->disable_threading ),
        }
    )->run;
}
1;
