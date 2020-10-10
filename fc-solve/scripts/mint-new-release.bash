#! /usr/bin/env bash
#
# mint-new-release.bash
# Copyright (C) 2018 Shlomi Fish <shlomif@cpan.org>
#
# Distributed under the terms of the MIT license.
#

# This script should be run from the fc-solve/source sub directory
# of the fc-solve repository checkout. E.g:

# shlomif[fcs]:$trunk/fc-solve/source$ pwd
# /home/shlomif/progs/freecell/git/fc-solve/fc-solve/source
# shlomif[fcs]:$trunk/fc-solve/source$ bash ../scripts/mint-new-release.bash ; notifier notify -m 'new fcs release'

set -x
set -e
set -u
cat <<'EOF'
This script should be run from the fc-solve/source sub directory
of the fc-solve repository checkout. E.g:

shlomif[fcs]:$trunk/fc-solve/source$ pwd
/home/shlomif/progs/freecell/git/fc-solve/fc-solve/source
shlomif[fcs]:$trunk/fc-solve/source$ bash ../scripts/mint-new-release.bash ; notifier notify -m 'new fcs release'
EOF
which cookiecutter
which git
which make
which perl
which unxz
which xz
perl -E 'use Task::FreecellSolver::Testing::MultiConfig v0.0.2; exit(0)'
src="$(pwd)"
tzr="$src/../scripts/Tatzer"
test -f "$tzr"
test -f "$src/freecell.c"
build="$src/../prerel-build"
assets_dir="$src/../../../../Arcs/fc-solve-site-assets/fc-solve-site-assets"
test -d "$assets_dir"
mkdir "$build"
cd "$build"
"$tzr" -l n2t
make
FCS_TEST_BUILD=1 perl "$src"/run-tests.pl
cd "$src"
perl ../scripts/multi_config_tests.pl
cd "$build"
make package_source
unxz *.tar.xz
arc="$(echo *.tar)"
xz -9 --extreme *.tar
cp "$arc.xz" "$assets_dir/dest/fc-solve/"
cd "$assets_dir"
commit_fn="dest/commit.msg"
arc_path="dest/fc-solve/$arc.xz"
bash gen_src_arc_commit_msg.bash "$arc_path"  > "$commit_fn"
git add "$arc_path"
git commit -F "$commit_fn"
git push
make upload
make upload-sf
rm -fr "$build"
