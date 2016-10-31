/*
 * This file is part of Freecell Solver. It is subject to the license terms in
 * the COPYING.txt file found in the top-level directory of this distribution
 * and at http://fc-solve.shlomifish.org/docs/distro/COPYING.html . No part of
 * Freecell Solver, including this file, may be copied, modified, propagated,
 * or distributed except according to the terms contained in the COPYING file.
 *
 * Copyright (c) 2000 Shlomi Fish
 */
/*
 * gen_ms_boards__hll_iface.c - high-level-language interface to the rand.
 */
#include "gen_ms_boards__hll_iface.h"
#include <string.h>

static fc_solve__hll_ms_rand_t singleton = {.gamenumber = 1, .seedx = 1};

fc_solve__hll_ms_rand_t *fc_solve__hll_ms_rand__get_singleton(void)
{
    return &singleton;
}

void fc_solve__hll_ms_rand__init(
    fc_solve__hll_ms_rand_t *const instance, const char *const gamenumber_s)
{
    const microsoft_rand_t gamenumber = atoll(gamenumber_s);
    instance->gamenumber = gamenumber;
    instance->seedx = microsoft_rand__calc_init_seedx(gamenumber);
}

extern int fc_solve__hll_ms_rand__mod_rand(
    fc_solve__hll_ms_rand_t *const instance, const int limit)
{
    return (microsoft_rand__game_num_rand(
                &(instance->seedx), instance->gamenumber) %
            limit);
}
