const std = @import("std");
const gtk = @import("gtk.zig");
const allocator = std.heap.page_allocator;
const c = gtk.c;
const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();

var prefs_builder: *c.GtkBuilder = undefined;
var prefs_window: [*]c.GtkWidget = undefined;

pub fn run() void {
    prefs_builder = c.gtk_builder_new();
    const glade_str = @embedFile("prefs.glade");
    _ = c.gtk_builder_add_from_string(prefs_builder, glade_str, glade_str.len, @intToPtr([*c][*c]c._GError, 0));
    prefs_window = gtk.builder_get_widget(prefs_builder, "prefs_window");
    c.gtk_widget_show_all(prefs_window);
    const prefs_window_ptr = @ptrCast(*c.GtkWindow, prefs_window);
    c.gtk_widget_show_all(prefs_window);
}
