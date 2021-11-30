#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use List::MoreUtils qw/ none /;
use Env::Path ();
use Path::Tiny qw/ path /;
use Test::Differences qw/ eq_or_diff /;
use Test::Trap
    qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

# Remove FCS_TEST_BUILD so we won't run the tests with infinite recursion.
if ( !delete( $ENV{'FCS_TEST_BUILD'} ) )
{
    plan skip_all => "Skipping because FCS_TEST_BUILD is not set";
}

# delete( $ENV{'CPATH'} );
if ( exists $ENV{'LD_LIBRARY_PATH__ORIG'} )
{
    $ENV{'LD_LIBRARY_PATH'} =
        delete( $ENV{'LD_LIBRARY_PATH__ORIG'} );
}

plan tests => 20;

# Change directory to the Freecell Solver base distribution directory.
my $src_path = path( $ENV{"FCS_SRC_PATH"} );

sub test_cmd
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $cmd, $blurb ) = @_;

    my @cmd = ( ref($cmd) eq "ARRAY" ) ? @$cmd : $cmd;

    # These environment variables confuse the input for the harness.
    my $sys_ret = do
    {
        local %ENV = %ENV;
        delete( $ENV{HARNESS_VERBOSE} );

        system(@cmd);
    };

    if ( !ok( !$sys_ret, $blurb ) )
    {
        Carp::confess( "Command ["
                . join( " ", ( map { qq/"$_"/ } @cmd ) )
                . "] failed! $!." );
    }
}

{
    my $temp_dir        = Path::Tiny->tempdir;
    my $build_dir       = $temp_dir->child("build-dir")->absolute;
    my $install_dir     = $temp_dir->child("fc-solve--install-dir")->absolute;
    my $run_dir         = $temp_dir->child("myuuuu-run-dir")->absolute;
    my $before_temp_cwd = Path::Tiny->cwd->absolute;

    $build_dir->mkpath;
    chdir($build_dir);

    {
        local %ENV = %ENV;
        delete $ENV{FREECELL_SOLVER_PRESETRC};

        # TEST
        test_cmd( [ "cmake", "-DCMAKE_INSTALL_PREFIX=$install_dir", $src_path ],
            "cmake succeeded" );
        0
            and system(
qq#set -x ; grep -rnE "FREECELL_SOLVER_PKG_DATA_DIR|root" \$HOME /tmp ; printenv#
            );

        # TEST
        test_cmd( [ "make", "boards" ] );

        # TEST
        test_cmd( [ "make", "install" ] );

        $run_dir->mkpath;
        chdir($run_dir);

0 and        system("set -x ; find $install_dir");

        # TEST
        test_cmd(
            [
                $install_dir->child( "bin", "fc-solve" ),
                "-l", "lg", $build_dir->child("24.board")
            ]
        );

        # TEST*2
        foreach my $doc_basename (qw/README USAGE/)
        {
            ok(
                scalar(
                    -f $install_dir->child(
                        "share", "doc", "freecell-solver", $doc_basename
                    )
                ),
                "'$doc_basename' document was installed."
            );
        }

    }

    chdir($build_dir);

    # TEST
    test_cmd( [ "make", "package_source" ],
        "make package_source is successful" );

    my ($version) = $src_path->child("ver.txt")->lines_utf8( { chomp => 1 } );

    my $base     = path("freecell-solver-$version");
    my $tar_arc  = "$base.tar";
    my $arc_name = "$tar_arc.xz";

    # The code starting from here makes sure we can run "make package_source"
    # inside the freecell-solver-$X.$Y.$Z/ directory generated by the unpacked
    # archive. So we don't have to rename it.

    # TEST
    test_cmd( [ "tar", "-xvf", $arc_name ], "Unpacking the arc name" );

    # TEST
    ok( scalar( -d $base ), "The directory was created" );

    my $orig_cwd = Path::Tiny->cwd->absolute;

    $base = $base->absolute;
    chdir($base);

    mkdir("build");
    chdir("build");

    # TEST
    test_cmd( [ "cmake", ".." ], "CMaking in the unpacked dir" );

    # TEST
    test_cmd( [ "make", "package_source" ] );

    # TEST
    test_cmd( [ "tar", "-xvf", $arc_name ],
        "Unpacking the arc name in the unpacked dir" );

    # TEST
    ok( scalar( -d $base ), "The directory was created again" );

    # TEST
    ok( scalar( -f $base->child("CMakeLists.txt") ), "CMakeLists.txt exists", );

    # TEST
    ok(
        scalar( -f $base->child("HACKING.asciidoc") ),
        "HACKING.asciidoc exists",
    );

    chdir($orig_cwd);

    my $failing_asciidoc_dir = $orig_cwd->child("asciidoc-fail");
    $failing_asciidoc_dir->remove_tree;
    $failing_asciidoc_dir->mkpath;

    my $asciidoc_bin = $failing_asciidoc_dir->child("asciidoc");
    $asciidoc_bin->spew_utf8(<<"EOF");
#!$^X
exit(-1);
EOF
    chmod( 0755, $asciidoc_bin );

    # Delete the unpacked directory.
    $base->remove_tree;

    # Now test the rpm building.
    {
        local $ENV{PATH} = $ENV{PATH};

        Env::Path->PATH->Prepend( $failing_asciidoc_dir, );

        # We need to delete the tar.gz/tar.bz2 because rpmbuild -tb may work
        # on them with the .xz still present.
        unlink( map { "$tar_arc.$_" } qw/bz2 gz/ );

        # TEST
        ok( scalar( -e $arc_name ), "Archive exists." );

        open my $tar_fh, "-|", "tar", "-tvf", $arc_name
            or die "Could not open Tar '$arc_name' for opening.";

        my @tar_lines = (<$tar_fh>);
        close($tar_fh);

        chomp(@tar_lines);

        # TEST
        eq_or_diff( [ grep { m{/config\.h\z} } @tar_lines ],
            [], "Archive does not contain config.h files" );

        # TEST
        ok(
            (
                none { m{/freecell-solver-range-parallel-solve\z} }
                @tar_lines
            ),
            "Archive does not contain the range solver executable"
        );

        # TEST
        ok(
            ( none { m{/libfreecell-solver\.a\z} } @tar_lines ),
            "Archive does not contain libfreecell-solver.a"
        );

        my $ret;

        # TEST
        trap
        {
            local %ENV = %ENV;

            # CFLAGS messes with cmake on rpmbuild on fedora 31 x86-64
            delete $ENV{CFLAGS};
            $ret = system("rpmbuild -tb $arc_name ");
        };
        if ( !is( $ret, 0, "rpmbuild -tb is successful." ) )
        {
            diag(     "stderr =<<<"
                    . $trap->stderr
                    . ">>>\n stdout=<<<"
                    . $trap->stdout
                    . ">>>\n" );
        }
    }

    $failing_asciidoc_dir->remove_tree;

    chdir($before_temp_cwd);
}

__END__

=head1 COPYRIGHT AND LICENSE

This file is part of Freecell Solver. It is subject to the license terms in
the COPYING.txt file found in the top-level directory of this distribution
and at http://fc-solve.shlomifish.org/docs/distro/COPYING.html . No part of
Freecell Solver, including this file, may be copied, modified, propagated,
or distributed except according to the terms contained in the COPYING file.

Copyright (c) 2009 Shlomi Fish

=cut
