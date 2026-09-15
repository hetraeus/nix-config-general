#define _GNU_SOURCE
#include <getopt.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <wayland-client.h>

#include "wlr-foreign-toplevel-management-unstable-v1-client-protocol.h"

/* ---------- globals ---------- */
static struct zwlr_foreign_toplevel_manager_v1 *manager;
static struct zwlr_foreign_toplevel_handle_v1 *active_toplevel;
static volatile int got_signal = 0;
static struct wl_display *display = NULL;

/* ---------- signal handler for graceful shutdown ---------- */
static void
signal_handler(int sig)
{
    (void)sig;
    got_signal = 1;
}

static void
setup_signals(void)
{
    struct sigaction sa = {0};
    sa.sa_handler = signal_handler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGHUP, &sa, NULL);
}

/* ---------- toplevel handle listener ---------- */
static void
handle_app_id(void *data, struct zwlr_foreign_toplevel_handle_v1 *h,
              const char *app_id)
{
    (void)data; (void)h; (void)app_id;
}

static void
handle_title(void *data, struct zwlr_foreign_toplevel_handle_v1 *h,
             const char *title)
{
    (void)data; (void)h; (void)title;
}

static void
handle_output_enter(void *data, struct zwlr_foreign_toplevel_handle_v1 *h,
                    struct wl_output *o)
{
    (void)data; (void)h; (void)o;
}

static void
handle_output_leave(void *data, struct zwlr_foreign_toplevel_handle_v1 *h,
                    struct wl_output *o)
{
    (void)data; (void)h; (void)o;
}

static void
handle_state(void *data, struct zwlr_foreign_toplevel_handle_v1 *h,
             struct wl_array *state)
{
    (void)data;
    uint32_t *s = state->data;
    size_t count = state->size / sizeof(uint32_t);

    for (size_t i = 0; i < count; i++) {
        if (s[i] == ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_STATE_ACTIVATED) {
            active_toplevel = h;
            return;
        }
    }
}

static void
handle_done(void *data, struct zwlr_foreign_toplevel_handle_v1 *h)
{
    (void)data; (void)h;
}

static void
handle_closed(void *data, struct zwlr_foreign_toplevel_handle_v1 *h)
{
    (void)data;
    if (h == active_toplevel)
        active_toplevel = NULL;
    zwlr_foreign_toplevel_handle_v1_destroy(h);
}

static void
handle_parent(void *data, struct zwlr_foreign_toplevel_handle_v1 *h,
              struct zwlr_foreign_toplevel_handle_v1 *parent)
{
    (void)data; (void)h; (void)parent;
}

static const struct zwlr_foreign_toplevel_handle_v1_listener handle_listener = {
    .title        = handle_title,
    .app_id       = handle_app_id,
    .output_enter = handle_output_enter,
    .output_leave = handle_output_leave,
    .state        = handle_state,
    .done         = handle_done,
    .closed       = handle_closed,
    .parent       = handle_parent,
};

/* ---------- manager listener ---------- */
static void
manager_toplevel(void *data, struct zwlr_foreign_toplevel_manager_v1 *m,
                 struct zwlr_foreign_toplevel_handle_v1 *h)
{
    (void)data; (void)m;
    zwlr_foreign_toplevel_handle_v1_add_listener(h, &handle_listener, NULL);
}

static void
manager_finished(void *data, struct zwlr_foreign_toplevel_manager_v1 *m)
{
    (void)data; (void)m;
}

static const struct zwlr_foreign_toplevel_manager_v1_listener manager_listener = {
    .toplevel = manager_toplevel,
    .finished = manager_finished,
};

/* ---------- registry listener ---------- */
static void
registry_global(void *data, struct wl_registry *r, uint32_t name,
                const char *iface, uint32_t version)
{
    (void)data;
    if (strcmp(iface, zwlr_foreign_toplevel_manager_v1_interface.name) == 0) {
        manager = wl_registry_bind(r, name,
                                   &zwlr_foreign_toplevel_manager_v1_interface,
                                   version < 3 ? version : 3);
        zwlr_foreign_toplevel_manager_v1_add_listener(manager,
                                                      &manager_listener, NULL);
    }
}

static void
registry_global_remove(void *data, struct wl_registry *r, uint32_t name)
{
    (void)data; (void)r; (void)name;
}

static const struct wl_registry_listener registry_listener = {
    .global        = registry_global,
    .global_remove = registry_global_remove,
};

/* ---------- cleanup function ---------- */
static void
cleanup(struct wl_display *disp)
{
    if (manager) {
        zwlr_foreign_toplevel_manager_v1_destroy(manager);
        manager = NULL;
    }
    if (disp) {
        wl_display_disconnect(disp);
    }
}

/* ---------- main ---------- */
static void
usage(const char *argv0)
{
    fprintf(stderr, "usage: %s [-h]\n", argv0);
    fprintf(stderr, "  Closes the active toplevel window.\n");
    fprintf(stderr, "\nOptions:\n");
    fprintf(stderr, "  -h, --help    Show this help message and exit\n");
}

int
main(int argc, char **argv)
{
    static const struct option long_opts[] = {
        { "help", no_argument, NULL, 'h' },
        { NULL, 0, NULL, 0 },
    };

    int c;
    while ((c = getopt_long(argc, argv, "h", long_opts, NULL)) != -1) {
        switch (c) {
        case 'h': usage(argv[0]); return 0;
        default:  usage(argv[0]); return 2;
        }
    }

    /* Setup signal handlers for graceful shutdown */
    setup_signals();

    display = wl_display_connect(NULL);
    if (!display) {
        fprintf(stderr, "wlr-close: cannot connect to Wayland display\n");
        return 1;
    }

    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);

    /* First roundtrip: discover globals */
    if (got_signal || wl_display_dispatch_pending(display) < 0 || wl_display_roundtrip(display) < 0)
        goto proto_error;

    if (!manager) {
        fprintf(stderr, "wlr-close: compositor does not support "
                        "wlr-foreign-toplevel-management\n");
        cleanup(display);
        return 1;
    }

    /* Second roundtrip: receive initial toplevel list */
    if (got_signal || wl_display_dispatch_pending(display) < 0 || wl_display_roundtrip(display) < 0)
        goto proto_error;

    /* Additional roundtrips to ensure late state events are delivered */
    if (got_signal) {
        fprintf(stderr, "wlr-close: interrupted by signal\n");
        cleanup(display);
        return 130;  /* Standard exit code for SIGINT */
    }

    if (wl_display_dispatch_pending(display) < 0 || wl_display_roundtrip(display) < 0)
        goto proto_error;

    if (got_signal) {
        fprintf(stderr, "wlr-close: interrupted by signal\n");
        cleanup(display);
        return 130;
    }

    if (wl_display_dispatch_pending(display) < 0 || wl_display_roundtrip(display) < 0)
        goto proto_error;

    /* Final check for active toplevel with proper guarding */
    if (!active_toplevel) {
        fprintf(stderr, "wlr-close: no active toplevel found\n");
        cleanup(display);
        return 1;
    }

    /* Send close request */
    zwlr_foreign_toplevel_handle_v1_close(active_toplevel);

    /* Flush the request and wait for completion */
    if (wl_display_flush(display) < 0)
        goto proto_error;

    if (wl_display_roundtrip(display) < 0)
        goto proto_error;

    /* Graceful cleanup */
    cleanup(display);
    return 0;

proto_error:
    fprintf(stderr, "wlr-close: wayland connection lost\n");
    cleanup(display);
    return 1;
}
