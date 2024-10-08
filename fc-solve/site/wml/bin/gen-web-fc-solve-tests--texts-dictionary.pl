#! /usr/bin/env perl
#
# Short description for gen-web-fc-solve-tests--texts-dictionary.pl
#
# Author Shlomi Fish <shlomif@cpan.org>
use strict;
use warnings;
use Path::Tiny    qw/ path /;
use File::Spec    ();
use Dir::Manifest ();
use JSON::MaybeXS ();

my $dir   = "lib/web-fcs-tests-strings/";
my $TEXTS = Dir::Manifest->new(
    {
        manifest_fn => "$dir/list.txt",
        dir         => "$dir/texts"
    }
)->texts_dictionary( { slurp_opts => {} } );

foreach my $out ( path("src/ts/web-fcs-tests-strings.ts") )
{
    $out->spew_utf8(
        "export const dict = ",

        JSON::MaybeXS->new->ascii->canonical(1)->encode($TEXTS), ";"
    );

    my $devnull = File::Spec->devnull();
    system(
qq#prettier --parser typescript --arrow-parens always --tab-width 4 --trailing-comma all --write "$out" >$devnull 2>$devnull#,
    );
}
