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
 *  forking_range_solver.c - a range solver that solves different boards in
 *  several UNIX processes.
 *
 *  See also:
 *      - fc_pro_range_solver.c
 *      - test_multi_parallel.c
 *      - threaded_range_solver.c
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef __linux__
#define USE_EPOLL
#endif

#include "alloc_wrap.h"
#include "portable_int64.h"
#include "portable_time.h"

#ifndef WIN32
#include <unistd.h>
#endif
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>

#ifdef USE_EPOLL
#include <sys/epoll.h>
#endif

#include "fcs_user.h"
#include "fcs_cl.h"
#include "unused.h"
#include "inline.h"
#include "range_solvers_gen_ms_boards.h"

struct fc_solve_display_information_context_struct
{
    fcs_bool_t debug_iter_state_output;
    fcs_bool_t parseable_output;
    fcs_bool_t canonized_order_output;
    fcs_bool_t display_10_as_t;
    fcs_bool_t display_parent_iter_num;
    fcs_bool_t debug_iter_output_on;
    fcs_bool_t display_moves;
    fcs_bool_t display_states;
    fcs_bool_t standard_notation;
};

typedef struct fc_solve_display_information_context_struct fc_solve_display_information_context_t;

static void my_iter_handler(
    void * user_instance,
    fcs_int_limit_t iter_num,
    int depth,
    void * ptr_state,
    fcs_int_limit_t parent_iter_num,
    void * lp_context
    )
{
    fc_solve_display_information_context_t * context;
    context = (fc_solve_display_information_context_t*)lp_context;

    fprintf(stdout, "Iteration: %li\n", (long)iter_num);
    fprintf(stdout, "Depth: %i\n", depth);
    if (context->display_parent_iter_num)
    {
        fprintf(stdout, "Parent Iteration: %li\n", (long)parent_iter_num);
    }
    fprintf(stdout, "\n");


    if (context->debug_iter_state_output)
    {
        char * state_string =
            freecell_solver_user_iter_state_as_string(
                user_instance,
                ptr_state,
                context->parseable_output,
                context->canonized_order_output,
                context->display_10_as_t
                );
        printf("%s\n---------------\n\n\n", state_string);
        free((void*)state_string);
    }

}

struct pack_item_struct
{
    fc_solve_display_information_context_t display_context;
    void * instance;
};

typedef struct pack_item_struct pack_item_t;


static int cmd_line_callback(
    void * instance,
    int argc GCC_UNUSED,
    freecell_solver_str_t argv[],
    int arg,
    int * num_to_skip,
    int * ret GCC_UNUSED,
    void * context
    )
{
    pack_item_t * item;
    fc_solve_display_information_context_t * dc;
    item = (pack_item_t * )context;
    dc = &(item->display_context);

    *num_to_skip = 0;

    if ((!strcmp(argv[arg], "-i")) || (!strcmp(argv[arg], "--iter-output")))
    {
        freecell_solver_user_set_iter_handler_long(
            instance,
            my_iter_handler,
            dc
            );
        dc->debug_iter_output_on = 1;
    }
    else if ((!strcmp(argv[arg], "-s")) || (!strcmp(argv[arg], "--state-output")))
    {
        dc->debug_iter_state_output = 1;
    }
    else if ((!strcmp(argv[arg], "-p")) || (!strcmp(argv[arg], "--parseable-output")))
    {
        dc->parseable_output = 1;
    }
    else if ((!strcmp(argv[arg], "-c")) || (!strcmp(argv[arg], "--canonized-order-output")))
    {
        dc->canonized_order_output = 1;
    }
    else if ((!strcmp(argv[arg], "-t")) || (!strcmp(argv[arg], "--display-10-as-t")))
    {
        dc->display_10_as_t = 1;
    }
    else if ((!strcmp(argv[arg], "-m")) || (!strcmp(argv[arg], "--display-moves")))
    {
        dc->display_moves = 1;
        dc->display_states = 0;
    }
    else if ((!strcmp(argv[arg], "-sn")) || (!strcmp(argv[arg], "--standard-notation")))
    {
        dc->standard_notation = 1;
    }
    else if ((!strcmp(argv[arg], "-sam")) || (!strcmp(argv[arg], "--display-states-and-moves")))
    {
        dc->display_moves = 1;
        dc->display_states = 1;
    }
    else if ((!strcmp(argv[arg], "-pi")) || (!strcmp(argv[arg], "--display-parent-iter")))
    {
        dc->display_parent_iter_num = 1;
    }
    else
    {
        fprintf(stderr, "Unknown option %s!\n", argv[arg]);
        exit(-1);
        return 0;
    }
    *num_to_skip = 1;
    return FCS_CMD_LINE_SKIP;
}

static const char * known_parameters[] = {
    "-i", "--iter-output",
    "-s", "--state-output",
    "-p", "--parseable-output",
    "-t", "--display-10-as-t",
    "-pi", "--display-parent-iter",
    NULL
    };

#define BINARY_OUTPUT_NUM_INTS 16

static void print_help(void)
{
    printf("\n%s",
"freecell-solver-range-parallel-solve start end print_step\n"
"   [--binary-output-to filename] [--total-iterations-limit limit]\n"
"   [fc-solve Arguments...]\n"
"\n"
"Solves a sequence of boards from the Microsoft/Freecell Pro Deals\n"
"\n"
"start - the first board in the sequence\n"
"end - the last board in the sequence (inclusive)\n"
"print_step - at which division to print a status line\n"
"\n"
"--total-iterations-limit  limit\n"
"     Limits each board for up to 'limit' iterations.\n"
          );
}

typedef struct {
    int argc;
    char * * argv;
    int arg;
    int stop_at;
} context_t;

static fcs_int_limit_t total_iterations_limit_per_board = -1;

static fcs_int64_t total_num_iters = 0;

#define READ_FD 0
#define WRITE_FD 1
typedef struct
{
    int child_to_parent_pipe[2];
    int parent_to_child_pipe[2];
} worker_t;

typedef struct
{
    int board_num;
    int quota_end;
} request_t;

typedef struct
{
    fcs_int_limit_t num_iters;
    int num_finished_boards;
} response_t;

static GCC_INLINE int worker_func(const int idx, const worker_t w, void * const instance)
{
    /* I'm one of the slaves */
    request_t request;
    response_t response;
    fcs_state_string_t state_string;
    fcs_portable_time_t mytime;

    while(1)
    {
        response.num_iters = 0;

        read(w.parent_to_child_pipe[READ_FD], &request, sizeof(request));

        if (request.board_num == -1)
        {
            break;
        }

        response.num_finished_boards =
            request.quota_end - request.board_num + 1;

#define board_num (request.board_num)
#define total_num_iters_temp (response.num_iters)
        for(;board_num<=request.quota_end;board_num++)
        {
            get_board(board_num, state_string);

            freecell_solver_user_limit_iterations_long(instance, total_iterations_limit_per_board);

            switch (
                freecell_solver_user_solve_board(
                    instance,
                    state_string
                    )
            )
            {
                case FCS_STATE_SUSPEND_PROCESS:
                {
                    FCS_PRINT_INTRACTABLE_BOARD(mytime, board_num);
                    fflush(stdout);
                }
                break;
                case FCS_STATE_FLARES_PLAN_ERROR:
                {
                    fprintf(stderr, "Flares Plan: %s\n", freecell_solver_user_get_last_error_string(instance));

                    goto next_board;
                }
                break;

                case FCS_STATE_IS_NOT_SOLVEABLE:
                {
                    FCS_PRINT_UNSOLVED_BOARD(mytime, board_num);
                    fflush(stdout);
                }
                break;
            }

            total_num_iters_temp += freecell_solver_user_get_num_times_long(instance);

            /*  TODO : implement at the master. */
#if 0

#endif

next_board:
            freecell_solver_user_recycle(instance);
        }
#undef board_num
#undef total_num_iters_temp

        write(w.child_to_parent_pipe[WRITE_FD], &response, sizeof(response));
    }

    /* Cleanup */
    freecell_solver_user_free(instance);

    close(w.child_to_parent_pipe[WRITE_FD]);
    close(w.parent_to_child_pipe[READ_FD]);

    return 0;
}

static GCC_INLINE void write_request(
    const int end_board,
    const int board_num_step,
    int * const next_board_num_ptr,
    const worker_t * const worker
)
{
    request_t request;
    if ((*next_board_num_ptr) > end_board)
    {
        request.board_num = -1;
    }
    else
    {
        request.board_num = *(next_board_num_ptr);
        if (((*next_board_num_ptr) += board_num_step) > end_board)
        {
            (*next_board_num_ptr) = end_board+1;
        }
        request.quota_end = (*next_board_num_ptr)-1;
    }

    write(
        worker->parent_to_child_pipe[WRITE_FD],
        &request,
        sizeof(request)
    );
}

int main(int argc, char * argv[])
{

    int arg = 1;

    if (argc < 4)
    {
        fprintf(stderr, "Not Enough Arguments!\n");
        print_help();
        exit(-1);
    }
    int next_board_num = atoi(argv[arg++]);
    const int end_board = atoi(argv[arg++]);
    const int stop_at = atoi(argv[arg++]);
    if (stop_at <= 0)
    {
        fprintf(stderr, "print_step (the third argument) must be greater than 0.\n");
        print_help();
        exit(-1);

    }

    int num_workers = 3;
    int board_num_step = 1;
    for (;arg < argc; arg++)
    {
        if (!strcmp(argv[arg], "--total-iterations-limit"))
        {
            arg++;
            if (arg == argc)
            {
                fprintf(stderr, "--total-iterations-limit came without an argument!\n");
                print_help();
                exit(-1);
            }
            total_iterations_limit_per_board = (fcs_int_limit_t)atol(argv[arg]);
        }
        else if (!strcmp(argv[arg], "--num-workers"))
        {
            arg++;
            if (arg == argc)
            {
                fprintf(stderr, "--num-workers came without an argument!\n");
                print_help();
                exit(-1);
            }
            num_workers = atoi(argv[arg]);
        }
        else if (!strcmp(argv[arg], "--worker-step"))
        {
            arg++;
            if (arg == argc)
            {
                fprintf(stderr, "--worker-step came without an argument!\n");
                print_help();
                exit(-1);
            }
            board_num_step = atoi(argv[arg]);
        }
        else if (!strcmp(argv[arg], "--iters-update-on"))
        {
            arg++;
            if (arg == argc)
            {
                fprintf(stderr, "--iters-update-on came without an argument!\n");
                print_help();
                exit(-1);
            }
        }
        else
        {
            break;
        }
    }

    fcs_portable_time_t mytime;
    FCS_PRINT_STARTED_AT(mytime);
    fflush(stdout);

    pack_item_t user = {.instance = freecell_solver_user_alloc(), .display_context = {.debug_iter_state_output = FALSE, .parseable_output = FALSE , .canonized_order_output = FALSE, .display_10_as_t = FALSE, .display_parent_iter_num = FALSE, .debug_iter_output_on = FALSE, .display_moves = FALSE, .display_states = FALSE , .standard_notation = FALSE } };

    char * error_string;
    switch (
        freecell_solver_user_cmd_line_parse_args(
            user.instance,
            argc,
            (freecell_solver_str_t *)(void *)argv,
            arg,
            known_parameters,
            cmd_line_callback,
            &user,
            &error_string,
            &arg
        )
    )
    {
        case FCS_CMD_LINE_UNRECOGNIZED_OPTION:
        {
            fprintf(stderr, "Unknown option: %s", argv[arg]);
            return -1;
        }
        case FCS_CMD_LINE_PARAM_WITH_NO_ARG:
        {
            fprintf(stderr, "The command line parameter \"%s\" requires an argument"
                " and was not supplied with one.\n", argv[arg]);
            return -1;
        }
        case FCS_CMD_LINE_ERROR_IN_ARG:
        {
            if (error_string != NULL)
            {
                fprintf(stderr, "%s", error_string);
                free(error_string);
            }
            return -1;
        }
    }

    worker_t * const workers = SMALLOC(workers, num_workers);

    for ( int idx = 0 ; idx < num_workers ; idx++)
    {
        int fork_ret;

        if (pipe(workers[idx].child_to_parent_pipe))
        {
            fprintf(stderr, "C->P Pipe for worker No. %i failed! Exiting.\n", idx);
            exit(-1);
        }
        if (pipe(workers[idx].parent_to_child_pipe))
        {
            fprintf(stderr, "P->C Pipe for worker No. %i failed! Exiting.\n", idx);
            exit(-1);
        }


        fork_ret = fork();

        if (fork_ret == -1)
        {
            fprintf(stderr, "Fork for worker No. %i failed! Exiting.\n", idx);
            exit(-1);
        }

        if (! fork_ret)
        {
            /* I'm the child. */
            {
                const worker_t w = workers[idx];
                free(workers);
                close(w.parent_to_child_pipe[WRITE_FD]);
                close(w.child_to_parent_pipe[READ_FD]);
                return worker_func(idx, w, user.instance);
            }
        }
        else
        {
            /* I'm the parent. */
            close(workers[idx].parent_to_child_pipe[READ_FD]);
            close(workers[idx].child_to_parent_pipe[WRITE_FD]);
        }
    }

    freecell_solver_user_free(user.instance);

    {
        /* I'm the master. */
#ifdef USE_EPOLL
#define MAX_EVENTS 10
        struct epoll_event ev, events[MAX_EVENTS];
        int epollfd = epoll_create1(0);
        if (epollfd == -1) {
            perror("epoll_create1");
            exit(EXIT_FAILURE);
        }
#else
        fd_set initial_readers;
        FD_ZERO(&initial_readers);
        int mymax = -1;
#endif

        for (int idx=0 ; idx < num_workers ; idx++)
        {
#define GET_READ_FD(worker) ((worker).child_to_parent_pipe[READ_FD])
            const int fd = GET_READ_FD(workers[idx]);
#ifdef USE_EPOLL
            ev.events = EPOLLIN;
            ev.data.ptr = &(workers[idx]);

            if (epoll_ctl(epollfd, EPOLL_CTL_ADD, fd, &ev) == -1) {
                perror("epoll_ctl: listen_sock");
                exit(EXIT_FAILURE);
            }
#else
            FD_SET(fd, &initial_readers);
            if (fd > mymax)
            {
                mymax = fd;
            }
#endif
        }

#ifndef USE_EPOLL
        mymax++;
#endif

        int total_num_finished_boards = 0;
        const int total_num_boards_to_check = end_board - next_board_num + 1;

        int next_milestone = next_board_num + stop_at;
        next_milestone -= (next_milestone % stop_at);

        for (int idx=0 ; idx < num_workers ; idx++)
        {
            write_request(end_board, board_num_step,
                &next_board_num, &(workers[idx])
            );
        }


        while (total_num_finished_boards < total_num_boards_to_check)
        {
            if (total_num_finished_boards >= next_milestone)
            {
                FCS_PRINT_REACHED_BOARD(
                    mytime,
                    next_milestone,
                    total_num_iters
                );
                fflush(stdout);

                next_milestone += stop_at;
            }

#ifdef USE_EPOLL
            const int nfds = epoll_wait(epollfd, events, MAX_EVENTS, -1);
            if (nfds == -1)
            {
                perror("epoll_pwait");
                exit(EXIT_FAILURE);
            }

            for (int i = 0 ; i < nfds ; i++)
            {
                const worker_t * const worker = events[i].data.ptr;
                response_t response;
                if (read (GET_READ_FD(*worker), &response, sizeof(response)) < sizeof(response))
                {
                    continue;
                }

                total_num_iters += response.num_iters;
                total_num_finished_boards += response.num_finished_boards;

                write_request(end_board, board_num_step,
                    &next_board_num, worker
                );
            }

#else
            fd_set readers = initial_readers;
            /* I'm the master. */
            const int select_ret = select (mymax, &readers, NULL, NULL, NULL);

            if (select_ret == -1)
            {
                perror("select()");
            }
            else if (select_ret)
            {
                for(int idx = 0 ; idx < num_workers ; idx++)
                {
                    const int fd = workers[idx].child_to_parent_pipe[READ_FD];

                    if (FD_ISSET(fd, &readers))
                    {
                        /* FD_ISSET can be set on EOF, so we check if
                         * read failed. */
                        response_t response;
                        if (read (fd, &response, sizeof(response)) < sizeof(response))
                        {
                            continue;
                        }

                        total_num_iters += response.num_iters;
                        total_num_finished_boards += response.num_finished_boards;

                        write_request(end_board, board_num_step,
                            &next_board_num, &(workers[idx])
                        );
                    }
                }
            }
#endif
        }
    }


    {
        int status;
        for(int idx=0 ; idx < num_workers ; idx++)
        {
            wait(&status);
        }
    }

    FCS_PRINT_FINISHED(mytime, total_num_iters);

    free(workers);

    return 0;
}

