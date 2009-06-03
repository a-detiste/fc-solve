/* Copyright (c) 2000 Shlomi Fish
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */
/*
 * test_arr.h - header file for some routines and macros involving tests and
 * the like for Freecell Solver.
 *
 */

#ifndef FC_SOLVE__TEST_ARR_H
#define FC_SOLVE__TEST_ARR_H

#ifdef __cplusplus
extern "C" {
#endif
/*
 * This macro marks a state as a dead end, and afterwards propogates
 * this information to its parent and ancestor states.
 * */
#define mark_as_dead_end(ptr_state_input_val) \
{      \
    if (scans_synergy)      \
    {        \
        fcs_state_extra_info_t * temp_state_val = (ptr_state_input_val); \
        /* Mark as a dead end */        \
        temp_state_val->visited |= FCS_VISITED_DEAD_END; \
        temp_state_val = temp_state_val->parent_val;          \
        if (temp_state_val != NULL)                    \
        {           \
            /* Decrease the refcount of the state */    \
            temp_state_val->num_active_children--;   \
            while((temp_state_val->num_active_children == 0) && (temp_state_val->visited & FCS_VISITED_ALL_TESTS_DONE))  \
            {          \
                /* Mark as dead end */        \
                temp_state_val->visited |= FCS_VISITED_DEAD_END;  \
                /* Go to its parent state */       \
                temp_state_val = temp_state_val->parent_val;    \
                if (temp_state_val == NULL)         \
                {                \
                    break;             \
                }      \
                /* Decrease the refcount */       \
                temp_state_val->num_active_children--;     \
            }       \
        }   \
    }      \
}

/*
 * This macro checks if we need to terminate from running this soft
 * thread and return to the soft thread manager with an
 * FCS_STATE_SUSPEND_PROCESS
 * */
#define check_if_limits_exceeded()                                    \
    (                                                                 \
        ((instance->max_num_times >= 0) &&                            \
        (instance->num_times >= instance->max_num_times))             \
            ||                                                        \
        ((hard_thread->ht_max_num_times >= 0) &&                      \
        (hard_thread->num_times >= hard_thread->ht_max_num_times))    \
            ||                                                        \
        ((hard_thread->max_num_times >= 0) &&                         \
        (hard_thread->num_times >= hard_thread->max_num_times))       \
            ||                                                        \
        ((instance->max_num_states_in_collection >= 0) &&             \
        (instance->num_states_in_collection >=                        \
            instance->max_num_states_in_collection)                   \
        )                                                             \
    )


#ifdef __cplusplus
}
#endif

#endif
