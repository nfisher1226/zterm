const std = @import("std");
const clap = @import("zig-clap");
const gtk = @import("zig-gtk");
const c = gtk.c;
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    const app = c.gtk_application_new("org.hitchhiker-linux.zterm", .G_APPLICATION_FLAGS_NONE) orelse @panic("null app :(");
    defer c.g_object_unref(app);

    _ = c.g_signal_connect_data(
        app,
        "activate",
        @ptrCast(c.GCallback, struct {
            fn f(a: *c.GtkApplication, data: c.gpointer) void {
                const window = c.gtk_application_window_new(a);
                const window_ptr = @ptrCast(*c.GtkWindow, window);
                c.gtk_window_set_title(window_ptr, "Zterm");
                c.gtk_window_set_default_size(window_ptr, 400, 400);

                const box = c.gtk_box_new(@intToEnum(c.GtkOrientation, 1), 10);
                const box_ptr = @ptrCast(*c.GtkBox, box);

                const heading = c.gtk_label_new(null);
                const heading_ptr = @ptrCast(*c.GtkLabel, heading);
                c.gtk_label_set_markup(heading_ptr, "<span size=\"xx-large\" weight=\"ultrabold\">A Heading</span>");
                c.gtk_label_set_selectable(heading_ptr, 1);

                const text = c.gtk_label_new("Label of a nice little window I created with zig and gtk4. I hope you like this little demonstration of programming an interface using Zig and gtk4.");
                const text_ptr = @ptrCast(*c.GtkLabel, text);
                c.gtk_label_set_wrap(text_ptr, 1);
                //c.gtk_label_set_line_wrap(text_ptr, 1);
                c.gtk_label_set_selectable(text_ptr, 1);

                const link = c.gtk_label_new(null);
                const link_ptr = @ptrCast(*c.GtkLabel, link);
                c.gtk_label_set_markup(link_ptr, "<a href=\"gemini://gemini.circumlunar.space\">Circumlunar Space</a>");
                c.gtk_label_set_selectable(link_ptr, 1);

                _ = gtk.g_signal_connect(
                    link,
                    "activate_link",
                    @ptrCast(c.GCallback, struct {
                    fn x(label: *c.GtkLabel, uri: [*]u8, user_data: c.gpointer) void {
                        stdout.print("Link clicked\n", .{}) catch |e| {
                            std.debug.print("Printing failed", .{});
                        };
                    }
                }.x),
                null,
                );

                c.gtk_box_append(box_ptr, heading);
                c.gtk_box_append(box_ptr, text);
                c.gtk_box_append(box_ptr, link);
                //c.gtk_box_pack_start(box_ptr, heading, 0, 1, 1);
                //c.gtk_box_pack_start(box_ptr, text, 0, 1, 1);
                //c.gtk_box_pack_start(box_ptr, link, 0, 1, 1);
                c.gtk_window_set_child(window_ptr, box);
                //c.gtk_container_add(@ptrCast(*g.GtkContainer, window), box);

                c.gtk_widget_show(window);
                //c.gtk_widget_show_all(window);
            }
        }.f),
        null,
        null,
        @intToEnum(c.GConnectFlags, 0),
    );

    _ = c.g_application_run(@ptrCast(*c.GApplication, app), 0, null);
}
