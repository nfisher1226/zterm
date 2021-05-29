const std = @import("std");
const gtk = @import("gtk.zig");
const prefs = @import("prefs.zig");
const allocator = std.heap.page_allocator;
const c = gtk.c;
const fs = std.fs;
const hashmap = std.AutoHashMap;
const os = std.os;
const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();

pub const Opts = struct {
    command: [*c]const u8,
    title: [*c]const u8,
    directory: [*c]const u8,
};

pub const Tab = struct {
    box: *c.GtkWidget,
    tab_label: *c.GtkWidget,
    close_button: *c.GtkWidget,
};

var builder: *c.GtkBuilder = undefined;
var notebook: *c.GtkWidget = undefined;
var window: *c.GtkWidget = undefined;
var options: Opts = undefined;
var tabs: hashmap(u64, Tab) = undefined;

pub fn activate(application: *c.GtkApplication, opts: c.gpointer) void {
    // Cast the gpointer to a normal pointer and dereference it, giving us
    // our "opts" struct initialized earlier.
    options = @ptrCast(*Opts, @alignCast(8, opts)).*;
    tabs= hashmap(u64, Tab).init(allocator);
    defer tabs.deinit();

    builder = c.gtk_builder_new();
    const glade_str = @embedFile("gui.glade");
    var ret = c.gtk_builder_add_from_string(builder, glade_str, glade_str.len, @intToPtr([*c][*c]c._GError, 0));
    if (ret == 0) {
        stderr.print("builder file fail\n", .{}) catch unreachable;
        std.process.exit(1);
    }
    c.gtk_builder_set_application(builder, application);

    window = gtk.builder_get_widget(builder, "window").?;
    const window_ptr = @ptrCast(*c.GtkWindow, window);
    c.gtk_window_set_title(window_ptr, options.title);

    notebook = gtk.builder_get_widget(builder, "notebook").?;
    const notebook_ptr = @ptrCast(*c.GtkNotebook, notebook);

    const new_tab = gtk.builder_get_widget(builder, "new_tab").?;
    const split_view = gtk.builder_get_widget(builder, "split_view").?;
    const rotate_view = gtk.builder_get_widget(builder, "rotate_view").?;
    const preferences = gtk.builder_get_widget(builder, "preferences").?;
    const close_tab = gtk.builder_get_widget(builder, "close_tab").?;
    const quit_app = gtk.builder_get_widget(builder, "quit_app").?;

    const command = @ptrCast([*c][*c]c.gchar, &([2][*c]c.gchar{
        c.g_strdup(options.command),
        null,
    }));

    const tab = new_tab_init(command);
    // We have to get the terminal in order to grab focus, use an
    // iterator and return the first (and only) entry's value field
    const kids = c.gtk_container_get_children(@ptrCast(*c.GtkContainer, tab.box));
    const term = c.g_list_nth_data(kids, 0);
    const term_ptr = @ptrCast(*c.GtkWidget, @alignCast(8, term));
    c.gtk_widget_show_all(window);
    c.gtk_widget_grab_focus(term_ptr);

    _ = gtk.g_signal_connect(
        new_tab,
        "activate",
        @ptrCast(c.GCallback, new_tab_callback),
        null,
    );

    _ = gtk.g_signal_connect(
        split_view,
        "activate",
        @ptrCast(c.GCallback, split_tab),
        null,
    );

    _ = gtk.g_signal_connect(
        rotate_view,
        "activate",
        @ptrCast(c.GCallback, rotate_tab),
        null,
    );

    _ = gtk.g_signal_connect(
        notebook,
        "page-removed",
        @ptrCast(c.GCallback, page_removed_callback),
        null,
    );

    _ = gtk.g_signal_connect(
        notebook,
        "select-page",
        @ptrCast(c.GCallback, select_page_callback),
        null,
    );

    _ = gtk.g_signal_connect(
        preferences,
        "activate",
        @ptrCast(c.GCallback, prefs.run),
        null,
    );

    _ = gtk.g_signal_connect(
        close_tab,
        "activate",
        @ptrCast(c.GCallback, close_current_tab),
        null,
    );

    _ = gtk.g_signal_connect(
        quit_app,
        "activate",
        @ptrCast(c.GCallback, quit_callback),
        null,
    );

    _ = gtk.g_signal_connect(
        window,
        "delete-event",
        @ptrCast(c.GCallback, quit_callback),
        null,
    );

    c.gtk_main();
}

fn new_tab_callback(menuitem: *c.GtkMenuItem, user_data: c.gpointer) void {
    const command = @ptrCast([*c]const u8, os.getenvZ("SHELL") orelse "/bin/sh");
    const tab = new_tab_init(
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
    const lbox = c.gtk_box_new(gtk.horizontal, 10);
    const lbox_ptr = @ptrCast(*c.GtkBox, lbox);
    const label = c.gtk_label_new("Zterm");
    const close_button = c.gtk_button_new_from_icon_name("window-close", gtk.menu_size);
    c.gtk_button_set_relief(@ptrCast(*c.GtkButton, close_button), gtk.relief_none);
    c.gtk_widget_set_has_tooltip(close_button, 1);
    c.gtk_widget_set_tooltip_text(close_button, "Close tab");
    c.gtk_box_pack_start(lbox_ptr, label, 0, 1, 1);
    c.gtk_box_pack_start(lbox_ptr, close_button, 0, 1, 1);
    c.gtk_widget_show_all(lbox);

    const box = c.gtk_box_new(gtk.horizontal, 0);
    c.gtk_box_set_homogeneous(@ptrCast(*c.GtkBox, box), 1);
    var tab = Tab {
        .box = box,
        .tab_label = label,
        .close_button = close_button,
    };

    tabs.putNoClobber(@ptrToInt(box), tab) catch |e| {
        stderr.print("{}\n", .{e}) catch unreachable;
    };

    const data = @ptrCast(c.gpointer, box);
    _ = gtk.g_signal_connect(
        close_button,
        "clicked",
        @ptrCast(c.GCallback, close_tab_by_button),
        data,
    );

    _ = gtk.g_signal_connect(
        term,
        "child-exited",
        @ptrCast(c.GCallback, close_term_callback),
        null,
    );

    c.gtk_box_pack_start(@ptrCast(*c.GtkBox, box), term, 1, 1, 1);
    c.gtk_widget_show_all(@ptrCast(*c.GtkWidget, box));
    const notebook_ptr = @ptrCast(*c.GtkNotebook, notebook);
    _ = c.gtk_notebook_append_page(notebook_ptr, box, 0);
    c.gtk_notebook_set_tab_label(notebook_ptr, @ptrCast(*c.GtkWidget, box), @ptrCast(*c.GtkWidget, lbox));
    return tab;
}

fn close_tab_by_button(button: *c.GtkButton, box: c.gpointer) void {
    const box_widget = @ptrCast(*c.GtkWidget, @alignCast(8, box));
    const key = @ptrToInt(box_widget);
    if (tabs.get(key)) |tab| {
        close_tab_by_ref(tab);
    }
}

fn close_tab_by_ref(tab: Tab) void {
    const key = @ptrToInt(tab.box);
    const num = c.gtk_notebook_page_num(@ptrCast(*c.GtkNotebook, notebook), tab.box);
    c.gtk_notebook_remove_page(@ptrCast(*c.GtkNotebook, notebook), num);
    if (tabs.get(key)) |_| {
        _ = tabs.remove(key);
    }
}

fn close_current_tab() void {
    const num = c.gtk_notebook_get_current_page(@ptrCast(*c.GtkNotebook, notebook));
    const box = c.gtk_notebook_get_nth_page(@ptrCast(*c.GtkNotebook, notebook), num);
    const key = @ptrToInt(box);
    if (tabs.get(key)) |tab| {
        close_tab_by_ref(tab);
    }
}

fn close_term_callback(term: *c.VteTerminal) void {
    const box = c.gtk_widget_get_parent(@ptrCast(*c.GtkWidget, term));
    const key = @ptrToInt(box);
    const num = c.gtk_notebook_page_num(@ptrCast(*c.GtkNotebook, notebook), box);
    c.gtk_container_remove(
        @ptrCast(*c.GtkContainer, box),
        @ptrCast(*c.GtkWidget, term));
    c.gtk_widget_destroy(@ptrCast(*c.GtkWidget, term));
    if (tabs.get(key)) |tab| {
        const termkey = @ptrToInt(term);
        const kids = c.gtk_container_get_children(@ptrCast(*c.GtkContainer, box));
        const len = c.g_list_length(kids);
        if (len == 0) {
            close_tab_by_ref(tab);
        } else {
            const first = c.g_list_nth_data(kids, 0);
            const first_ptr = @ptrCast(*c.GtkWidget, @alignCast(8, first));
            c.gtk_widget_grab_focus(first_ptr);
        }
    }
}

fn page_removed_callback() void {
    const pages = c.gtk_notebook_get_n_pages(@ptrCast(*c.GtkNotebook, notebook));
    if (pages == 0) {
        c.gtk_main_quit();
    } else {
        select_page_callback();
    }
}

fn select_page_callback() void {
    const tab = get_current_tab();
    const kids = c.gtk_container_get_children(@ptrCast(*c.GtkContainer, tab.box));
    const first = c.g_list_nth_data(kids, 0);
    const first_ptr = @ptrCast(*c.GtkWidget, @alignCast(8, first));
    c.gtk_widget_grab_focus(first_ptr);
}


fn get_current_tab() Tab {
    const tab_num = c.gtk_notebook_get_current_page(@ptrCast(*c.GtkNotebook, notebook));
    const box_widget = c.gtk_notebook_get_nth_page(@ptrCast(*c.GtkNotebook, notebook), tab_num);
    const tab = if (tabs.get(@ptrToInt(box_widget))) |t| t else unreachable;
    return tab;
}

fn split_tab() void {
    var tab = get_current_tab();
    const command = @ptrCast([*c][*c]c.gchar, &([2][*c]c.gchar{
        c.g_strdup(options.command),
        null,
    }));
    const term = new_term(command);
    c.gtk_widget_show(term);
    c.gtk_box_pack_start(@ptrCast(*c.GtkBox, tab.box), term, 1, 1, 1);
    _ = gtk.g_signal_connect(
        term,
        "child-exited",
        @ptrCast(c.GCallback, close_term_callback),
        @ptrCast(c.gpointer, tab.box),
    );
}

fn rotate_tab() void {
    const tab = get_current_tab();
    const orientation = c.gtk_orientable_get_orientation(@ptrCast(*c.GtkOrientable, tab.box));
    if (@enumToInt(orientation) == 0) {
        c.gtk_orientable_set_orientation(@ptrCast(*c.GtkOrientable, tab.box), gtk.vertical);
    } else {
        c.gtk_orientable_set_orientation(@ptrCast(*c.GtkOrientable, tab.box), gtk.horizontal);
    }
}

pub fn quit_callback() void {
    c.gtk_main_quit();
}
