const std = @import("std");
const data = @import("data.zig");
const gtk = @import("gtk.zig");
const allocator = std.heap.page_allocator;
const c = gtk.c;
const os = std.os;
const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();

const menu_size = @intToEnum(c.GtkIconSize, c.GTK_ICON_SIZE_MENU);
const pack_end = @intToEnum(c.GtkPackType, c.GTK_PACK_END);
const pack_start = @intToEnum(c.GtkPackType, c.GTK_PACK_START);
const relief_none = @intToEnum(c.GtkReliefStyle, c.GTK_RELIEF_NONE);

pub fn activate(a: *c.GtkApplication, appdata: c.gpointer) void {
    // Cast the gpointer to a normal pointer and dereference it, giving us
    // our "opts" struct initialized earlier.
    const options = @ptrCast(*data.Opts, @alignCast(8, appdata)).*;
    const window = c.gtk_application_window_new(a);
    const window_ptr = @ptrCast(*c.GtkWindow, window);
    c.gtk_window_set_title(window_ptr, options.title);

    var notebook = c.gtk_notebook_new();
    const notebook_ptr = @ptrCast(*c.GtkNotebook, notebook);

    const addbutton = c.gtk_button_new_from_icon_name("tab-new", menu_size);
    c.gtk_button_set_relief(@ptrCast(*c.GtkButton, addbutton), relief_none);
    c.gtk_widget_set_has_tooltip(addbutton, 1);
    c.gtk_widget_set_tooltip_text(addbutton, "Open new tab");
    c.gtk_widget_set_can_focus(addbutton, 0);

    const splitbutton = c.gtk_button_new_from_icon_name("list-add", menu_size);
    c.gtk_button_set_relief(@ptrCast(*c.GtkButton, splitbutton), relief_none);
    c.gtk_widget_set_has_tooltip(splitbutton, 1);
    c.gtk_widget_set_tooltip_text(splitbutton, "Split view");
    c.gtk_widget_set_can_focus(splitbutton, 0);

    const rotatebutton = c.gtk_button_new_from_icon_name("object-rotate-right", menu_size);
    c.gtk_button_set_relief(@ptrCast(*c.GtkButton, rotatebutton), relief_none);
    c.gtk_widget_set_has_tooltip(rotatebutton, 1);
    c.gtk_widget_set_tooltip_text(rotatebutton, "Change split orientation");
    c.gtk_widget_set_can_focus(rotatebutton, 0);

    const ctrlbox = c.gtk_box_new(@intToEnum(c.GtkOrientation, 0), 0);
    c.gtk_box_pack_start(@ptrCast(*c.GtkBox, ctrlbox), addbutton, 0, 1, 1);
    c.gtk_box_pack_start(@ptrCast(*c.GtkBox, ctrlbox), splitbutton, 0, 1, 1);
    c.gtk_box_pack_start(@ptrCast(*c.GtkBox, ctrlbox), rotatebutton, 0, 1, 1);
    c.gtk_widget_show_all(ctrlbox);
    c.gtk_notebook_set_action_widget(notebook_ptr, ctrlbox, pack_end);

    _ = gtk.g_signal_connect(
        addbutton,
        "clicked",
        @ptrCast(c.GCallback, addbutton_callback),
        @ptrCast(c.gpointer, notebook),
    );

    const command = @ptrCast([*c][*c]c.gchar, &([2][*c]c.gchar{
        c.g_strdup(options.command),
        null,
    }));

    const tab = new_tab(notebook_ptr, command);
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

    c.gtk_container_add(@ptrCast(*c.GtkContainer, window), notebook);

    c.gtk_widget_show_all(window);
    c.gtk_widget_grab_focus(@ptrCast(*c.GtkWidget, term));
}

pub fn addbutton_callback(button: *c.GtkButton, notebook: c.gpointer) void {
    const command = @ptrCast([*c]const u8, os.getenvZ("SHELL") orelse "/bin/sh");
    _ = new_tab(
        @ptrCast(*c.GtkNotebook, @alignCast(8, notebook)),
        @ptrCast([*c][*c]c.gchar, &([2][*c]c.gchar{
            c.g_strdup(command),
            null,
        })),
    );
}

pub fn new_tab(notebook: *c.GtkNotebook, command: [*c][*c]c.gchar) data.Tab {
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

    _ = gtk.g_signal_connect(
        term,
        "child-exited",
        @ptrCast(c.GCallback, struct {
        fn e(t: *c.VteTerminal) void {
            c.gtk_widget_destroy(@ptrCast(*c.GtkWidget, t));
        }}.e),
        null,
    );

    const box = c.gtk_box_new(@intToEnum(c.GtkOrientation, 0), 10);
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
    var tab = data.Tab {
        .box = box,
        .tab_label = label,
        .terms = terms,
    };

    c.gtk_widget_show(@ptrCast(*c.GtkWidget, term));
    _ = c.gtk_notebook_append_page(notebook, term, 0);
    c.gtk_notebook_set_tab_label(notebook, @ptrCast(*c.GtkWidget, term), @ptrCast(*c.GtkWidget, box));
    return tab;
}

pub fn quit_callback() void {
    c.gtk_main_quit();
}
