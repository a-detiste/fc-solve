#! /usr/bin/env perl

use strict;
use warnings;
use 5.014;
use autodie;

use Path::Tiny qw/ path tempdir tempfile cwd /;
use Docker::CLI::Wrapper::Container v0.0.4 ();

sub do_system
{
    my ($args) = @_;

    my $cmd = $args->{cmd};
    print "Running [@$cmd]\n";
    if ( system(@$cmd) )
    {
        die "Running [@$cmd] failed!";
    }
}

my @deps;    #= map { /^BuildRequires:\s*(\S+)/ ? ("'$1'") : () }

# path("freecell-solver.spec.in")->lines_utf8;
my $SYS       = "debian:sid";
my $CONTAINER = "pypi-pysol-cards--deb--test-build";
my $obj       = Docker::CLI::Wrapper::Container->new(
    { container => $CONTAINER, sys => $SYS, }, );
my $USER                  = "mygbp";
my $HOMEDIR               = "/home/$USER";
my $PYPI_BASE             = "pysol-cards";
my $VER                   = '0.8.7';
my $SRC_ROOT_DIR          = $PYPI_BASE;
my $SRC_ROOT_DIR_fullpath = "$HOMEDIR/$SRC_ROOT_DIR";

$obj->clean_up();
$obj->run_docker();
my $REPO = 'fortune-mod';
my $URL  = "https://salsa.debian.org/shlomif-guest/$REPO";

if ( !-e $REPO )
{
    do_system( { cmd => [ "git", "clone", $URL, ] } );
}
my $cwd = cwd;
chdir "./$REPO";
do_system( { cmd => [ "git", "pull", "--ff-only", ] } );
chdir $cwd;

my $LOG_FN = "git-buildpackage-log.txt";

my $BASH_SAFETY = "set -e -x ; set -o pipefail ; ";

# do_system( { cmd => [ 'docker', 'cp', "../scripts", "fcsfed:scripts", ] } );
my $script = <<"EOSCRIPTTTTTTT";
$BASH_SAFETY
apt-get -y update
apt-get -y install eatmydata sudo
sudo eatmydata apt -y install build-essential chrpath cmake git-buildpackage librecode-dev perl pypi2deb python-all python-pbr python-setuptools python-six python3-all python3-pbr python3-setuptools recode
sudo adduser --disabled-password --gecos '' "$USER"
sudo usermod -a -G sudo "$USER"
echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
EOSCRIPTTTTTTT

$obj->exe_bash_code( { code => $script, } );

if (0)
{
    $obj->docker(
        { cmd => [ 'cp', "./$REPO", "$CONTAINER:$HOMEDIR/$REPO", ] } );
}

sub _docker_chown
{
    $obj->exe_bash_code(
        {
            code => "$BASH_SAFETY chown -R $USER:$USER $HOMEDIR",
        }
    );
    return;
}

if ( -e $PYPI_BASE )
{
    $obj->docker(
        {
            cmd => [ 'cp', $SRC_ROOT_DIR, "$CONTAINER:$SRC_ROOT_DIR_fullpath", ]
        }
    );
    _docker_chown();
    $script = <<"EOSCRIPTTTTTTT";
$BASH_SAFETY
( cd $SRC_ROOT_DIR_fullpath/$PYPI_BASE-$VER && dpkg-buildpackage -us -uc ) 2>&1 | tee ~/"$LOG_FN"
EOSCRIPTTTTTTT

    $obj->exe_bash_code(
        {
            user => $USER,
            code => $script,
        }
    );

    $script = <<"EOSCRIPTTTTTTT";
$BASH_SAFETY
apt-get -y install $SRC_ROOT_DIR_fullpath/*.deb
EOSCRIPTTTTTTT

    $obj->exe_bash_code(
        {
            code => $script,
        }
    );

}
else
{
    _docker_chown();
    $script = <<"EOSCRIPTTTTTTT";
$BASH_SAFETY
cd "$HOMEDIR"
fn1="./overrides/$PYPI_BASE/ctx.json"
fn2="./overrides/pysol_cards/ctx.json"
for fn in "\$fn1" "\$fn2"
do
    mkdir -p "\$(dirname \"\$fn\")"
    echo "{\\"interpreters\\":[\\"python3\\"]}" > "\$fn"
done
( py2dsp $PYPI_BASE --root $SRC_ROOT_DIR_fullpath ) 2>&1 | tee ~/"$LOG_FN"
EOSCRIPTTTTTTT

    $obj->exe_bash_code(
        {
            user => $USER,
            code => $script,
        }
    );
    $obj->docker(
        { cmd => [ 'cp', "$CONTAINER:$HOMEDIR/$LOG_FN", $LOG_FN, ] } );

    $obj->docker(
        {
            cmd => [ 'cp', "$CONTAINER:$SRC_ROOT_DIR_fullpath", $SRC_ROOT_DIR, ]
        }
    );
}
$obj->clean_up();

__END__

=head1 COPYRIGHT & LICENSE

Copyright 2019 by Shlomi Fish

This program is distributed under the MIT / Expat License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut
