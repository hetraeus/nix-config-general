#define _GNU_SOURCE
#include <errno.h>
#include <spawn.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>
#include <wayland-client.h>

#include "wlr-foreign-toplevel-management-unstable-v1-client-protocol.h"

extern char **environ;

/* ---------- globals ---------- */
static struct zwlr_foreign_toplevel_manager_v1 *manager;
static struct wl_seat *seat;          /* bound from registry */
static const char *target;
static int matched;

/* ---------- toplevel handle listener ---------- */
static void
handle_app_id(void *data, struct zwlr_foreign_toplevel_handle_v1 *h,
              const char *app_id)
{
    (void)data;
    if (matched || !app_id)
        return;
    if (strstr(app_id, target)) {
        matched = 1;
        /* The protocol requires a non-NULL wl_seat here.
         * Passing NULL is what produced the marshalling error. */
        zwlr_foreign_toplevel_handle_v1_activate(h, seat);
    }
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
    (void)data; (void)h; (void)state;
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
    } else if (strcmp(iface, wl_seat_interface.name) == 0) {
        /* bind the seat; activate() needs a real wl_seat object */
        seat = wl_registry_bind(r, name, &wl_seat_interface,
                                version < 1 ? version : 1);
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

/* ---------- main ---------- */
int
main(int argc, char **argv)
{
    if (argc < 2 || argv[1][0] == '\0') {
        fprintf(stderr,
                "usage: %s <app_id-substring> [command ...]\n", argv[0]);
        return 2;
    }
    target = argv[1];

    struct wl_display *display = wl_display_connect(NULL);
    if (!display) {
        fprintf(stderr, "wlr-focus: cannot connect to Wayland display\n");
        return 1;
    }

    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);

    /* globals: this binds both manager and seat */
    if (wl_display_roundtrip(display) < 0)
        goto proto_error;

    if (!manager) {
        fprintf(stderr, "wlr-focus: compositor does not support "
                        "wlr-foreign-toplevel-management\n");
        wl_display_disconnect(display);
        return 1;
    }

    if (!seat) {
        /* No seat means we cannot legally call activate().
         * In practice every compositor has at least one seat. */
        fprintf(stderr, "wlr-focus: no wl_seat available\n");
        wl_display_disconnect(display);
        return 1;
    }

    /* list of toplevels */
    if (wl_display_roundtrip(display) < 0)
        goto proto_error;
    /* initial app_id/title events for each toplevel */
    if (wl_display_roundtrip(display) < 0)
        goto proto_error;
    /* flush the activate request if we matched */
    if (wl_display_roundtrip(display) < 0)
        goto proto_error;

    wl_display_disconnect(display);

    if (matched)
        return 0;

    /* No running window matched: spawn the fallback command if given. */
    if (argc > 2) {
        posix_spawn_file_actions_t fa;
        posix_spawnattr_t attr;
        pid_t pid;
        int rc;

        posix_spawn_file_actions_init(&fa);
        posix_spawnattr_init(&attr);
        posix_spawnattr_setflags(&attr, POSIX_SPAWN_SETSID);

        rc = posix_spawnp(&pid, argv[2], &fa, &attr, &argv[2], environ);

        posix_spawnattr_destroy(&attr);
        posix_spawn_file_actions_destroy(&fa);

        if (rc != 0) {
            errno = rc;
            perror("wlr-focus: posix_spawnp");
            return 1;
        }
        return 0;
    }

    return 1;

proto_error:
    fprintf(stderr, "wlr-focus: wayland connection lost\n");
    wl_display_disconnect(display);
    return 1;
}
