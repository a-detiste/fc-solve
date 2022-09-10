#!/usr/bin/perl

use strict;
use warnings;

use FC_Solve::Base64               ();
use FC_Solve::DeltaStater::DeBondt ();
use IO::All                        qw/ io /;

my $delta = FC_Solve::DeltaStater::DeBondt->new(
    { init_state_str => io->file( $ENV{I} )->all(), } );
$delta->set_derived( { state_str => io->file( $ENV{I} )->all(), } );

my $token = $delta->encode_composite();

my $buffer = $token;
my $count  = length($buffer);
while ( $count < 16 )
{
    ++$count;
    $buffer .= '\0';
}

print
    FC_Solve::Base64::base64_encode($buffer),
    " 0 ",
    FC_Solve::Base64::base64_encode(q{}),
    "\n";
