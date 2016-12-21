/*
 * This file is part of Freecell Solver. It is subject to the license terms in
 * the COPYING.txt file found in the top-level directory of this distribution
 * and at http://fc-solve.shlomifish.org/docs/distro/COPYING.html . No part of
 * Freecell Solver, including this file, may be copied, modified, propagated,
 * or distributed except according to the terms contained in the COPYING file.
 *
 * Copyright (c) 2000 Shlomi Fish
 */
#pragma once

#include "dbm_procs_inner.h"

static inline void dbm__spawn_threads(fcs_dbm_solver_instance_t *const instance,
    const size_t num_threads, main_thread_item_t *const threads)
{
#ifdef T
    FILE *const out_fh = instance->common.out_fh;
#endif
    TRACE("Running threads for curr_depth=%d\n", instance->curr_depth);
    for (size_t i = 0; i < num_threads; i++)
    {
        if (pthread_create(&(threads[i].id), NULL, instance_run_solver_thread,
                &(threads[i].arg)))
        {
            fc_solve_err("Worker Thread No. %zd Initialization failed!\n", i);
        }
    }

    for (size_t i = 0; i < num_threads; i++)
    {
        pthread_join(threads[i].id, NULL);
    }
    TRACE("Finished running threads for curr_depth=%d\n", instance->curr_depth);
}

static void init_thread(fcs_dbm_solver_thread_t *const thread)
{
    fc_solve_meta_compact_allocator_init(&(thread->thread_meta_alloc));
}

static void free_thread(fcs_dbm_solver_thread_t *const thread)
{
    fc_solve_meta_compact_allocator_finish(&(thread->thread_meta_alloc));
}

/* Returns if the process should terminate. */
static fcs_bool_t handle_and_destroy_instance_solution(
    fcs_dbm_solver_instance_t *const instance,
    fc_solve_delta_stater_t *const delta)
{
    FILE *const out_fh = instance->common.out_fh;
    fcs_bool_t ret = FALSE;
    TRACE("%s\n", "handle_and_destroy_instance_solution start");
    instance_print_stats(instance);
    if (instance->common.queue_solution_was_found)
    {
        trace_solution(instance, out_fh, delta);
        ret = TRUE;
    }
    else if (instance->common.should_terminate != DONT_TERMINATE)
    {
        fprintf(out_fh, "%s\n", "Intractable.");
        fflush(out_fh);
        if (instance->common.should_terminate == MAX_ITERS_TERMINATE)
        {
            fprintf(out_fh, "Reached Max-or-more iterations of %ld.\n",
                instance->common.max_count_num_processed);
        }
    }
    else
    {
        fprintf(out_fh, "%s\n", "Could not solve successfully.");
    }

    TRACE("%s\n", "handle_and_destroy_instance_solution end");

    instance_destroy(instance);

    return ret;
}
