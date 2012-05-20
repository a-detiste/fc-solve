/* Copyright (c) 2012 Shlomi Fish
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
 * dbm_kaztree_compare.h - contains the comparison routine. The record_t
 * definition can be found in delta_states.h.
 * Intended for dbm_kaztree.c. Should only be included by it and programs
 * that test it.
 */
#ifndef FC_SOLVE_DBM_KAZTREE_COMPARE_H
#define FC_SOLVE_DBM_KAZTREE_COMPARE_H

#ifdef __cplusplus
extern "C"
{
#endif

#include "delta_states.h"

/*
 * TODO : We waste too much space and fragment it storing the
 * key/parent_move separatley from the dnode_t. We should use a struct
 * for that instead of a pointer.
 * */

/* TODO: make sure the key is '\0'-padded. */
static int compare_records(
    const void * void_a, const void * void_b, void * context
)
{
#define GET_PARAM(p) (((const fcs_dbm_record_t *)(p))->key)
    return memcmp(&(GET_PARAM(void_a)), &(GET_PARAM(void_b)), sizeof(GET_PARAM(void_a)));
#undef GET_PARAM
}

#ifdef __cplusplus
}
#endif

#endif /*  FC_SOLVE_DBM_KAZTREE_COMPARE_H */

