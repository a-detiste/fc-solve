# How to build the fc-solve site.

## Dependencies:

1. [Latemp](https://github.com/thewml/latemp) , python3
and [Jinja2](http://jinja.pocoo.org/),
[Website Meta Language](https://bitbucket.org/shlomif/website-meta-language) .
2. [Emscripten](https://emscripten.org/)
3. [CMake](https://cmake.org/)
4. [GNU Make](https://www.gnu.org/software/make/)
5. Some [CPAN](http://metacpan.org/) Modules.
6. The [TypeScript](http://www.typescriptlang.org/) tsc compiler.
7. Possibly other stuff.

## Build procedure.

1. `perl gen-helpers`
2. `bash bin/install-npm-deps.sh`
3. `make`
4. `make test`
5. `make PROD=1`

The smoke tests can be run using:

1. `gmake smoke-tests`

To upload, use:

1. `make upload`
2. `make PROD=1 upload`

## Assets.

The assets (downloads/tarballs/etc.) for this site are kept in a
separate repository: http://github.com/shlomif/fc-solve-site-assets
