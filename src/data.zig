const std = @import("std");
const gtk = @import("gtk.zig");
const c = gtk.c;

pub const Opts = struct {
    command: [*c]const u8,
    title: [*c]const u8,
    directory: [*c]const u8,
};

pub const Tab = struct {
    box: *c.GtkWidget,
    tab_label: *c.GtkWidget,
    terms: std.AutoHashMap(u64, *c.GtkWidget),
};

pub const RunData = struct {
    window: *c.GtkWindow,
    notebook: *c.GtkWidget,
    opts: *Opts,
    tabs: std.HashMap(*Tab),
};

