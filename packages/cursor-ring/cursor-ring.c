/* cursor-ring.c
   Standalone Wayland layer-shell cursor highlight ring

   Build:
     wayland-scanner client-header \
       wlr-layer-shell-unstable-v1.xml \
       wlr-layer-shell-unstable-v1-client-protocol.h
     wayland-scanner private-code \
       wlr-layer-shell-unstable-v1.xml \
       wlr-layer-shell-unstable-v1-protocol.c
     gcc -O2 cursor-ring.c wlr-layer-shell-unstable-v1-protocol.c xdg-shell-protocol.c -o cursor-ring \
         $(pkg-config --cflags --libs wayland-client cairo) -lm

   Or with Nix:
   nix build .#cursor-ring
*/

#define _GNU_SOURCE
#include <wayland-client.h>
#include <wayland-client-protocol.h>
#include <cairo.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <math.h>
#include <signal.h>
#include <errno.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <sys/un.h>

// Generated protocol headers
#include "wlr-layer-shell-unstable-v1-client-protocol.h"

// Globals

static struct wl_display *display;
static struct wl_compositor *compositor;
static struct wl_shm *shm;
static struct wl_seat *seat;
static struct zwlr_layer_shell_v1 *layer_shell;
static struct wl_output *output;

static struct wl_surface *surface;
static struct zwlr_layer_surface_v1 *layer_surface;

static int width = 400, height = 400;
static int cursor_x = 0, cursor_y = 0;
static int configured = 0;
static int running = 1;
static double start_time;

#define RING_DURATION 0.63

static double now_seconds(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec / 1e9;
}

// SHM buffer helpers

static int create_shm_file(size_t size) {
    char name[] = "/tmp/cursor-ring-XXXXXX";
    int fd = mkstemp(name);
    if (fd < 0) return -1;
    unlink(name);
    if (ftruncate(fd, size) < 0) {
        close(fd);
        return -1;
    }
    return fd;
}

struct buffer {
    struct wl_buffer *buffer;
    cairo_surface_t *cairo_surface;
    void *data;
    size_t size;
};

static struct buffer *create_buffer(int w, int h) {
    int stride = cairo_format_stride_for_width(CAIRO_FORMAT_ARGB32, w);
    size_t size = stride * h;

    int fd = create_shm_file(size);
    if (fd < 0) return NULL;

    void *data = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (data == MAP_FAILED) {
        close(fd);
        return NULL;
    }

    struct wl_shm_pool *pool = wl_shm_create_pool(shm, fd, size);
    struct wl_buffer *buffer = wl_shm_pool_create_buffer(
        pool, 0, w, h, stride, WL_SHM_FORMAT_ARGB8888
    );
    wl_shm_pool_destroy(pool);
    close(fd);

    struct buffer *buf = calloc(1, sizeof(*buf));
    buf->buffer = buffer;
    buf->data = data;
    buf->size = size;
    buf->cairo_surface = cairo_image_surface_create_for_data(
        data, CAIRO_FORMAT_ARGB32, w, h, stride
    );

    return buf;
}

static void destroy_buffer(struct buffer *buf) {
    if (!buf) return;
    cairo_surface_destroy(buf->cairo_surface);
    wl_buffer_destroy(buf->buffer);
    munmap(buf->data, buf->size);
    free(buf);
}

// Drawing

static void draw_ring(struct buffer *buf, double progress) {
    cairo_t *cr = cairo_create(buf->cairo_surface);
    cairo_set_antialias(cr, CAIRO_ANTIALIAS_SUBPIXEL);

    // Clear
    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
    cairo_paint(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER);

    double cx = width / 2.0;
    double cy = height / 2.0;

    // Close-in: starts big (2x old max), snaps down to cursor
    double start_radius = 156.0;
    double end_radius = 20.0;
    // Ease-in for accelerating close
    double t = progress * progress;
    double radius = start_radius + (end_radius - start_radius) * t;

    // Fade-in: ghostly start, solid at target
    double alpha = 0.25 + progress * 0.75;

    // Redshift: start bright teal, shift to red
    double r = 0.0 + progress * 1.0;
    double g = 1.0 - progress * 0.85;
    double b = 0.95 - progress * 0.75;

    // Dark background disc (kept more transparent)
    cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.18 * alpha);
    cairo_arc(cr, cx, cy, radius + 12.0, 0, 2.0 * M_PI);
    cairo_fill(cr);

    // Outer dark outline (kept more transparent)
    cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.35 * alpha);
    cairo_set_line_width(cr, 4.0);
    cairo_arc(cr, cx, cy, radius + 1.5, 0, 2.0 * M_PI);
    cairo_stroke(cr);

    // Main ring — bright, thick, kept fully opaque
    cairo_set_source_rgba(cr, r, g, b, fmin(1.0, alpha * 1.3));
    cairo_set_line_width(cr, 4.0);
    cairo_arc(cr, cx, cy, radius, 0, 2.0 * M_PI);
    cairo_stroke(cr);

    // Inner bright accent (brighter than before)
    cairo_set_source_rgba(cr, r, g * 0.85, b * 0.55, fmin(1.0, alpha * 1.4));
    cairo_set_line_width(cr, 2.0);
    cairo_arc(cr, cx, cy, radius - 5.0, 0, 2.0 * M_PI);
    cairo_stroke(cr);

    // Second inner ring, a bit dimmer
    cairo_set_source_rgba(cr, r, g * 0.6, b * 0.35, fmin(1.0, alpha * 1.0));
    cairo_set_line_width(cr, 1.5);
    cairo_arc(cr, cx, cy, radius - 10.0, 0, 2.0 * M_PI);
    cairo_stroke(cr);

    // Third inner ring, dimmest
    cairo_set_source_rgba(cr, r, g * 0.4, b * 0.2, fmin(1.0, alpha * 0.65));
    cairo_set_line_width(cr, 1.5);
    cairo_arc(cr, cx, cy, radius - 15.0, 0, 2.0 * M_PI);
    cairo_stroke(cr);

    // Center dot — bright white core
    cairo_set_source_rgba(cr, 1.0, 1.0, 1.0, alpha);
    cairo_arc(cr, cx, cy, 5.0, 0, 2.0 * M_PI);
    cairo_fill(cr);

    // Center dot hot core
    cairo_set_source_rgba(cr, r, g * 0.4, b * 0.2, alpha);
    cairo_arc(cr, cx, cy, 2.5, 0, 2.0 * M_PI);
    cairo_fill(cr);

    cairo_destroy(cr);
}

// Wayland callbacks

static void layer_surface_configure(void *data,
    struct zwlr_layer_surface_v1 *layer_surface, uint32_t serial,
    uint32_t w, uint32_t h)
{
    zwlr_layer_surface_v1_ack_configure(layer_surface, serial);
    configured = 1;
}

static void layer_surface_closed(void *data,
    struct zwlr_layer_surface_v1 *layer_surface)
{
    running = 0;
}

static const struct zwlr_layer_surface_v1_listener layer_surface_listener = {
    .configure = layer_surface_configure,
    .closed = layer_surface_closed,
};

static void pointer_enter(void *data, struct wl_pointer *pointer,
    uint32_t serial, struct wl_surface *surface,
    wl_fixed_t sx, wl_fixed_t sy)
{
}

static void pointer_leave(void *data, struct wl_pointer *pointer,
    uint32_t serial, struct wl_surface *surface)
{
}

static void pointer_motion(void *data, struct wl_pointer *pointer,
    uint32_t time, wl_fixed_t sx, wl_fixed_t sy)
{
}

static void pointer_button(void *data, struct wl_pointer *pointer,
    uint32_t serial, uint32_t time, uint32_t button, uint32_t state)
{
    if (state == WL_POINTER_BUTTON_STATE_PRESSED) {
        running = 0;
    }
}

static void pointer_axis(void *data, struct wl_pointer *pointer,
    uint32_t time, uint32_t axis, wl_fixed_t value)
{
}

static const struct wl_pointer_listener pointer_listener = {
    .enter = pointer_enter,
    .leave = pointer_leave,
    .motion = pointer_motion,
    .button = pointer_button,
    .axis = pointer_axis,
};

static void seat_capabilities(void *data, struct wl_seat *seat, uint32_t caps) {
    if (caps & WL_SEAT_CAPABILITY_POINTER) {
        struct wl_pointer *pointer = wl_seat_get_pointer(seat);
        wl_pointer_add_listener(pointer, &pointer_listener, NULL);
    }
}

static void seat_name(void *data, struct wl_seat *seat, const char *name) {
}

static const struct wl_seat_listener seat_listener = {
    .capabilities = seat_capabilities,
    .name = seat_name,
};

static void registry_global(void *data, struct wl_registry *registry,
    uint32_t id, const char *interface, uint32_t version)
{
    if (strcmp(interface, wl_compositor_interface.name) == 0) {
        compositor = wl_registry_bind(registry, id, &wl_compositor_interface, 4);
    } else if (strcmp(interface, wl_shm_interface.name) == 0) {
        shm = wl_registry_bind(registry, id, &wl_shm_interface, 1);
    } else if (strcmp(interface, wl_seat_interface.name) == 0) {
        seat = wl_registry_bind(registry, id, &wl_seat_interface, 1);
        wl_seat_add_listener(seat, &seat_listener, NULL);
    } else if (strcmp(interface, "wl_output") == 0) {
        if (!output) {
            output = wl_registry_bind(registry, id, &wl_output_interface, 1);
        }
    } else if (strcmp(interface, zwlr_layer_shell_v1_interface.name) == 0) {
        layer_shell = wl_registry_bind(registry, id, &zwlr_layer_shell_v1_interface, 1);
    }
}

static void registry_global_remove(void *data, struct wl_registry *registry,
    uint32_t id)
{
}

static const struct wl_registry_listener registry_listener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

// Cursor position (via Hyprland IPC socket or env vars)

static int get_cursor_position_from_hyprland(void) {
    const char *sig = getenv("HYPRLAND_INSTANCE_SIGNATURE");
    if (!sig) {
        fprintf(stderr, "cursor-ring: HYPRLAND_INSTANCE_SIGNATURE not set\n");
        return -1;
    }
    fprintf(stderr, "cursor-ring: HYPRLAND_INSTANCE_SIGNATURE=%s\n", sig);

    char sock_path[512];
    const char *runtime_dir = getenv("XDG_RUNTIME_DIR");
    if (runtime_dir) {
        snprintf(sock_path, sizeof(sock_path), "%s/hypr/%s/.socket.sock", runtime_dir, sig);
    } else {
        snprintf(sock_path, sizeof(sock_path), "/tmp/hypr/%s/.socket.sock", sig);
    }

    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return -1;

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    snprintf(addr.sun_path, sizeof(addr.sun_path), "%s", sock_path);

    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd);
        return -1;
    }

    const char *cmd = "cursorpos";
    if (write(fd, cmd, strlen(cmd)) < 0) {
        close(fd);
        return -1;
    }

    char buf[64];
    ssize_t n = read(fd, buf, sizeof(buf) - 1);
    close(fd);

    if (n <= 0) return -1;
    buf[n] = '\0';

    // Parse "1234,567" format
    int x, y;
    if (sscanf(buf, "%d,%d", &x, &y) == 2) {
        cursor_x = x;
        cursor_y = y;
        fprintf(stderr, "cursor-ring: got cursor pos %d,%d\n", cursor_x, cursor_y);
        return 0;
    }

    fprintf(stderr, "cursor-ring: failed to parse cursorpos response: '%s'\n", buf);
    return -1;
}

static void get_cursor_position(void) {
    // Already set from command line?
    if (cursor_x != 0 || cursor_y != 0) {
        fprintf(stderr, "cursor-ring: position already set to %d,%d\n", cursor_x, cursor_y);
        return;
    }

    // Try Hyprland IPC first
    if (get_cursor_position_from_hyprland() == 0) {
        fprintf(stderr, "cursor-ring: using Hyprland IPC position\n");
        return;
    }

    // Fallback: env vars
    const char *cx = getenv("CURSOR_X");
    const char *cy = getenv("CURSOR_Y");
    if (cx && cy) {
        cursor_x = atoi(cx);
        cursor_y = atoi(cy);
        fprintf(stderr, "cursor-ring: using env var position %d,%d\n", cursor_x, cursor_y);
        return;
    }

    // Final fallback: screen center
    cursor_x = 960;
    cursor_y = 540;
    fprintf(stderr, "cursor-ring: fallback to center %d,%d\n", cursor_x, cursor_y);
}

// Main

static void sig_handler(int sig) {
    running = 0;
}

int main(int argc, char **argv) {
    signal(SIGINT, sig_handler);
    signal(SIGTERM, sig_handler);

    /* Parse cursor position from command line.
       Accepts either: cursor-ring 1234 567
       or:  cursor-ring "944, 1064"  (hyprctl cursorpos format)
    */
    if (argc >= 2) {
        char *arg = argv[1];
        // Remove comma if present
        char *comma = strchr(arg, ',');
        if (comma) {
            *comma = ' ';
            if (sscanf(arg, "%d %d", &cursor_x, &cursor_y) == 2) {
                fprintf(stderr, "cursor-ring: using parsed position %d,%d\n", cursor_x, cursor_y);
            }
        } else if (argc >= 3) {
            cursor_x = atoi(argv[1]);
            cursor_y = atoi(argv[2]);
            fprintf(stderr, "cursor-ring: using cmdline position %d,%d\n", cursor_x, cursor_y);
        }
    }

    display = wl_display_connect(NULL);
    if (!display) {
        fprintf(stderr, "Failed to connect to Wayland display\n");
        return 1;
    }

    struct wl_registry *registry = wl_display_get_registry(display);
    wl_registry_add_listener(registry, &registry_listener, NULL);
    wl_display_roundtrip(display);

    if (!compositor || !shm || !layer_shell) {
        fprintf(stderr, "Missing required Wayland globals\n");
        return 1;
    }

    get_cursor_position();
    fprintf(stderr, "cursor-ring: positioning at %d,%d (margin: top=%d, left=%d)\n",
            cursor_x, cursor_y, cursor_y - height/2, cursor_x - width/2);

    surface = wl_compositor_create_surface(compositor);
    layer_surface = zwlr_layer_shell_v1_get_layer_surface(
        layer_shell, surface, output,
        ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY, "cursor-ring"
    );

    zwlr_layer_surface_v1_set_size(layer_surface, width, height);
    zwlr_layer_surface_v1_set_anchor(layer_surface,
        ZWLR_LAYER_SURFACE_V1_ANCHOR_TOP |
        ZWLR_LAYER_SURFACE_V1_ANCHOR_LEFT);
    zwlr_layer_surface_v1_set_margin(layer_surface,
        cursor_y - height/2, 0, 0, cursor_x - width/2);
    zwlr_layer_surface_v1_set_keyboard_interactivity(layer_surface, 0);

    zwlr_layer_surface_v1_add_listener(layer_surface, &layer_surface_listener, NULL);
    wl_surface_commit(surface);

    while (!configured && running) {
        wl_display_dispatch(display);
    }

    struct buffer *buf = create_buffer(width, height);
    if (!buf) {
        fprintf(stderr, "Failed to create buffer\n");
        return 1;
    }

    start_time = now_seconds();

    while (running) {
        double now = now_seconds();
        double elapsed = now - start_time;

        if (elapsed >= RING_DURATION) break;

        double progress = elapsed / RING_DURATION;
        draw_ring(buf, progress);

        wl_surface_attach(surface, buf->buffer, 0, 0);
        wl_surface_damage(surface, 0, 0, width, height);
        wl_surface_commit(surface);

        wl_display_dispatch_pending(display);
        wl_display_flush(display);

        usleep(16000);
    }

    destroy_buffer(buf);
    zwlr_layer_surface_v1_destroy(layer_surface);
    wl_surface_destroy(surface);
    wl_display_disconnect(display);

    return 0;
}
