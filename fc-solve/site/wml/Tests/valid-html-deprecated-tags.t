#!/usr/bin/env perl

use strict;
use warnings;

use Test::HTML::Recursive::DeprecatedTags ();

Test::HTML::Recursive::DeprecatedTags->new(
    {
        filename_filter => sub { return shift !~ qr#mail-lists|yui-unpack#; },
        targets         => ['./dest'],
    }
)->run;
