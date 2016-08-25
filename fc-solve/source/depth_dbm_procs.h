#pragma once

#include "dbm_procs_inner.h"

static GCC_INLINE void dbm__spawn_threads(
    fcs_dbm_solver_instance_t *const instance, const size_t num_threads,
    main_thread_item_t *const threads)
{
#ifdef T
    FILE *const out_fh = instance->out_fh;
#endif
    TRACE("Running threads for curr_depth=%d\n", instance->curr_depth);
    for (size_t i = 0; i < num_threads; i++)
    {
        if (pthread_create(&(threads[i].id), NULL, instance_run_solver_thread,
                &(threads[i].arg)))
        {
            fprintf(
                stderr, "Worker Thread No. %zd Initialization failed!\n", i);
            exit(-1);
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
