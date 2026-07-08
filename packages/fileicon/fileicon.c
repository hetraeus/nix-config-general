#include <gtk/gtk.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static char *render_pixbuf_to_tmp(GdkPixbuf *pixbuf, const char *cache_key)
{
    const char *tmp = g_get_tmp_dir();
    guint hash = g_str_hash(cache_key);
    char *tmp_path = g_strdup_printf("%s/fileicon_%u.png", tmp, hash);

    struct stat st;
    if (stat(tmp_path, &st) == 0 && st.st_size > 0) {
        return tmp_path;
    }

    unlink(tmp_path);

    GError *err = NULL;
    gdk_pixbuf_save(pixbuf, tmp_path, "png", &err, NULL);
    g_object_unref(pixbuf);

    if (err) {
        g_error_free(err);
        g_free(tmp_path);
        return NULL;
    }

    return tmp_path;
}

static char *resolve_themed_icon(GtkIconTheme *theme, const char *name)
{
    if (!name || !*name) return NULL;

    GtkIconInfo *info = gtk_icon_theme_lookup_icon(
        theme, name, 48, GTK_ICON_LOOKUP_GENERIC_FALLBACK);

    if (!info) return NULL;

    const char *src = gtk_icon_info_get_filename(info);

    if (src && g_str_has_suffix(src, ".png")) {
        char *res = g_strdup(src);
        g_object_unref(info);
        return res;
    }

    GError *err = NULL;
    GdkPixbuf *pixbuf = gtk_icon_info_load_icon(info, &err);
    g_object_unref(info);

    if (!pixbuf) {
        if (err) g_error_free(err);
        return NULL;
    }

    return render_pixbuf_to_tmp(pixbuf, name);
}

static char *resolve_file_icon(GIcon *icon)
{
    if (!G_IS_FILE_ICON(icon)) return NULL;

    GFile *file = g_file_icon_get_file(G_FILE_ICON(icon));
    char *path = g_file_get_path(file);

    if (!path) return NULL;

    if (g_str_has_suffix(path, ".png")) {
        return path;
    }

    GError *err = NULL;
    GdkPixbuf *pixbuf = gdk_pixbuf_new_from_file(path, &err);
    if (!pixbuf) {
        if (err) g_error_free(err);
        g_free(path);
        return NULL;
    }

    GdkPixbuf *scaled = gdk_pixbuf_scale_simple(pixbuf, 48, 48, GDK_INTERP_BILINEAR);
    g_object_unref(pixbuf);

    if (!scaled) {
        g_free(path);
        return NULL;
    }

    char *result = render_pixbuf_to_tmp(scaled, path);
    g_free(path);
    return result;
}

static char *icon_to_png_path(GtkIconTheme *theme, GIcon *icon, gboolean is_dir)
{
    if (!icon) return NULL;

    if (G_IS_EMBLEMED_ICON(icon)) {
        GIcon *base = g_emblemed_icon_get_icon(G_EMBLEMED_ICON(icon));
        return icon_to_png_path(theme, base, is_dir);
    }

    if (G_IS_THEMED_ICON(icon)) {
        const gchar * const *names = g_themed_icon_get_names(G_THEMED_ICON(icon));
        for (int n = 0; names && names[n]; n++) {
            /* Skip the ugly generic inode-directory; prefer folder-* or folder */
            if (is_dir && g_str_equal(names[n], "inode-directory")) {
                continue;
            }
            char *resolved = resolve_themed_icon(theme, names[n]);
            if (resolved) return resolved;
        }
        /* Final fallback for directories */
        if (is_dir) {
            return resolve_themed_icon(theme, "folder");
        }
        return NULL;
    }

    if (G_IS_FILE_ICON(icon)) {
        return resolve_file_icon(icon);
    }

    return NULL;
}

int main(int argc, char **argv)
{
    if (!gtk_init_check(&argc, &argv)) {
        fprintf(stderr, "gtk_init_check failed\n");
        return 1;
    }

    GtkIconTheme *theme = gtk_icon_theme_get_default();

    for (int i = 1; i < argc; i++) {
        const char *path = argv[i];
        char *icon_png = NULL;

        GFile *file = g_file_new_for_path(path);
        GFileInfo *info = g_file_query_info(
            file,
            "standard::icon,standard::content-type,standard::type",
            G_FILE_QUERY_INFO_NONE, NULL, NULL);

        gboolean is_dir = FALSE;

        if (info) {
            GFileType ftype = g_file_info_get_file_type(info);
            is_dir = (ftype == G_FILE_TYPE_DIRECTORY);

            /* 1. Try the file's own icon */
            GIcon *icon = g_file_info_get_icon(info);
            if (icon) {
                icon_png = icon_to_png_path(theme, icon, is_dir);
            }

            /* 2. Fallback: content-type icon */
            if (!icon_png) {
                const char *ctype = g_file_info_get_content_type(info);
                if (ctype) {
                    GIcon *ctype_icon = g_content_type_get_icon(ctype);
                    if (ctype_icon) {
                        icon_png = icon_to_png_path(theme, ctype_icon, is_dir);
                        g_object_unref(ctype_icon);
                    }
                }
            }

            /* 3. Final fallback for directories */
            if (!icon_png && is_dir) {
                icon_png = resolve_themed_icon(theme, "folder");
            }

            g_object_unref(info);
        }

        g_object_unref(file);

        printf("%s\t%s\n", path, icon_png ? icon_png : "");
        g_free(icon_png);
    }

    return 0;
}
