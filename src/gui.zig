const std = @import("std");
const gtk = @import("gtk.zig");
const allocator = std.heap.page_allocator;
const c = gtk.c;
const os = std.os;
const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();

const menu_size = @intToEnum(c.GtkIconSize, c.GTK_ICON_SIZE_MENU);
const horizontal = @intToEnum(c.GtkOrientation, 0);
const pack_end = @intToEnum(c.GtkPackType, c.GTK_PACK_END);
const pack_start = @intToEnum(c.GtkPackType, c.GTK_PACK_START);
const relief_none = @intToEnum(c.GtkReliefStyle, c.GTK_RELIEF_NONE);
const vertical = @intToEnum(c.GtkOrientation, 1);

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
    opts: *Opts,
    tabs: std.AutoHashMap(u64, *Tab),
};

var builder: *c.GtkBuilder = undefined;
var notebook: [*]c.GtkWidget = undefined;
var window: [*]c.GtkWidget = undefined;
var options: Opts = undefined;

pub fn activate(application: *c.GtkApplication, appdata: c.gpointer) void {
    // Cast the gpointer to a normal pointer and dereference it, giving us
    // our "opts" struct initialized earlier.
    options = @ptrCast(*Opts, @alignCast(8, appdata)).*;

    builder = c.gtk_builder_new();
    var ret = c.gtk_builder_add_from_file(builder, "./src/gui.glade", @intToPtr([*c][*c]c._GError, 0));
    if (ret == 0) {
        stderr.print("builder file fail\n", .{}) catch unreachable;
        std.process.exit(1);
    }
    c.gtk_builder_set_application(builder, application);

    window = gtk.builder_get_widget(builder, "window");
    const window_ptr = @ptrCast(*c.GtkWindow, window);
    c.gtk_window_set_title(window_ptr, options.title);

    notebook = gtk.builder_get_widget(builder, "notebook");
    const notebook_ptr = @ptrCast(*c.GtkNotebook, notebook);

    const new_tab = gtk.builder_get_widget(builder, "new_tab");
    const split_view = gtk.builder_get_widget(builder, "split_view");
    const rotate_view = gtk.builder_get_widget(builder, "rotate_view");
    const preferences = gtk.builder_get_widget(builder, "preferences");
    const close_tab = gtk.builder_get_widget(builder, "close_tab");
    const quit_app = gtk.builder_get_widget(builder, "quit_app");

    _ = gtk.g_signal_connect(
        new_tab,
        "activate",
        @ptrCast(c.GCallback, new_tab_callback),
        null,
    );

    const command = @ptrCast([*c][*c]c.gchar, &([2][*c]c.gchar{
        c.g_strdup(options.command),
        null,
    }));

    const tab = new_tab_init(command);
    // We have to get the terminal in order to grab focus, use an
    // iterator and return the first (and only) entry's value field
    var term = if (tab.terms.iterator().next()) |entry| termblk: {
        break :termblk entry.value;
    } else unreachable;

    _ = gtk.g_signal_connect(
        window,
        "delete-event",
        @ptrCast(c.GCallback, quit_callback),
        null,
    );

    std.debug.print("Application ready\n", .{});
    c.gtk_widget_show_all(window);
    c.gtk_widget_grab_focus(@ptrCast(*c.GtkWidget, term));
    c.gtk_main();
}

fn new_tab_callback(menuitem: *c.GtkMenuItem, user_data: c.gpointer) void {
    const command = @ptrCast([*c]const u8, os.getenvZ("SHELL") orelse "/bin/sh");
    _ = new_tab_init(
        @ptrCast([*c][*c]c.gchar, &([2][*c]c.gchar{
            c.g_strdup(command),
            null,
        })),
    );
}

fn new_term(command: [*c][*c]c.gchar) *c.GtkWidget {
    const term = c.vte_terminal_new();
    const term_ptr = @ptrCast([*c]c.VteTerminal, term);
    c.vte_terminal_spawn_async(
        term_ptr,
        @intToEnum(c.VtePtyFlags, c.VTE_PTY_DEFAULT),
        null,
        command,
        null,
        @intToEnum(c.GSpawnFlags, c.G_SPAWN_DEFAULT),
        null,
        @intToPtr(?*c_void, @as(c_int, 0)),
        null,
        -1,
        null,
        null,
        @intToPtr(?*c_void, @as(c_int, 0)),
    );
    return term;
}

fn new_tab_init(command: [*c][*c]c.gchar) Tab {
    const term = new_term(command);
    _ = gtk.g_signal_connect(
        term,
        "child-exited",
        @ptrCast(c.GCallback, struct {
        fn e(t: *c.VteTerminal) void {
            c.gtk_widget_destroy(@ptrCast(*c.GtkWidget, t));
        }}.e),
        null,
    );

    const box = c.gtk_box_new(horizontal, 10);
    const box_ptr = @ptrCast(*c.GtkBox, box);
    const label = c.gtk_label_new("Zterm");
    const closebutton = c.gtk_button_new_from_icon_name("window-close", menu_size);
    c.gtk_button_set_relief(@ptrCast(*c.GtkButton, closebutton), relief_none);
    c.gtk_widget_set_has_tooltip(closebutton, 1);
    c.gtk_widget_set_tooltip_text(closebutton, "Close tab");
    c.gtk_box_pack_start(box_ptr, label, 0, 1, 1);
    c.gtk_box_pack_start(box_ptr, closebutton, 0, 1, 1);
    c.gtk_widget_show_all(box);

    _ = gtk.g_signal_connect(
        closebutton,
        "clicked",
        @ptrCast(c.GCallback, struct {
        fn c(but: *c.GtkButton, terminal: c.gpointer) void {
            c.gtk_widget_destroy(@ptrCast(*c.GtkWidget, @alignCast(8, terminal)));
        }}.c),
        @ptrCast(c.gpointer, term),
    );

    var terms = std.AutoHashMap(u64, *c.GtkWidget).init(allocator);
    terms.putNoClobber(@ptrToInt(term), term) catch unreachable;
    var tab = Tab {
        .box = box,
        .tab_label = label,
        .terms = terms,
    };

    c.gtk_widget_show(@ptrCast(*c.GtkWidget, term));
    const notebook_ptr = @ptrCast(*c.GtkNotebook, notebook);
    _ = c.gtk_notebook_append_page(notebook_ptr, term, 0);
    c.gtk_notebook_set_tab_label(notebook_ptr, @ptrCast(*c.GtkWidget, term), @ptrCast(*c.GtkWidget, box));
    return tab;
}

pub fn quit_callback() void {
    c.gtk_main_quit();
}
