package Shlomif::FCS::CalcMetaScan::PostProcessor;

use strict;
use warnings;

use base 'Shlomif::FCS::CalcMetaScan::Base';

__PACKAGE__->mk_acc_ref(
    [
        qw(
            _should_do_rle
            _offset_quotas
        )
    ]
);

sub _init
{
    my $self = shift;
    my $args = shift;

    $self->_should_do_rle( $args->{do_rle} );
    $self->_offset_quotas( $args->{offset_quotas} );

    return $self;
}

sub scans_rle
{
    my $self = shift;

    my @scans_list = @{ shift() };

    my $scan = shift(@scans_list);

    my (@a);
    while ( my $next_scan = shift(@scans_list) )
    {
        if ( $next_scan->scan() == $scan->scan() )
        {
            $scan->iters( $scan->iters() + $next_scan->iters() );
        }
        else
        {
            push @a, $scan;
            $scan = $next_scan;
        }
    }
    push @a, $scan;
    return \@a;
}

sub process
{
    my $self = shift;

    my $scans_orig = shift;

    # clone the scans.
    my $scans = [ map { $_->clone(); } @{$scans_orig} ];

    if ( $self->_offset_quotas )
    {
        $scans = [
            map {
                my $ret = $_->clone();
                $ret->iters( $ret->iters() + 1 );
                $ret;
            } @$scans
        ];
    }

    if ( $self->_should_do_rle )
    {
        $scans = $self->scans_rle($scans);
    }

    return $scans;
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

This file is part of Freecell Solver. It is subject to the license terms in
the COPYING.txt file found in the top-level directory of this distribution
and at http://fc-solve.shlomifish.org/docs/distro/COPYING.html . No part of
Freecell Solver, including this file, may be copied, modified, propagated,
or distributed except according to the terms contained in the COPYING file.

Copyright (c) 2010 Shlomi Fish

=cut
