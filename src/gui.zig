const std = @import("std");
const config = @import("config.zig");
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

    fn init(command: [*c][*c]c.gchar) Tab {
        var tab = Tab {
            .box = c.gtk_box_new(gtk.horizontal, 0),
            .tab_label = c.gtk_label_new("Zterm"),
            .close_button = c.gtk_button_new_from_icon_name("window-close", gtk.menu_size),
        };
        const term = new_term(command);
        const lbox = c.gtk_box_new(gtk.horizontal, 10);
        const lbox_ptr = @ptrCast(*c.GtkBox, lbox);
        c.gtk_button_set_relief(@ptrCast(*c.GtkButton, tab.close_button), gtk.relief_none);
        c.gtk_widget_set_has_tooltip(tab.close_button, 1);
        c.gtk_widget_set_tooltip_text(tab.close_button, "Close tab");
        c.gtk_box_pack_start(lbox_ptr, tab.tab_label, 0, 1, 1);
        c.gtk_box_pack_start(lbox_ptr, tab.close_button, 0, 1, 1);
        c.gtk_widget_show_all(lbox);

        c.gtk_box_set_homogeneous(@ptrCast(*c.GtkBox, tab.box), 1);
        c.gtk_box_pack_start(@ptrCast(*c.GtkBox, tab.box), term, 1, 1, 1);
        c.gtk_widget_show_all(@ptrCast(*c.GtkWidget, tab.box));
        const notebook_ptr = @ptrCast(*c.GtkNotebook, gui.notebook);
        _ = c.gtk_notebook_append_page(notebook_ptr, tab.box, 0);
        c.gtk_notebook_set_tab_label(notebook_ptr, @ptrCast(*c.GtkWidget, tab.box), @ptrCast(*c.GtkWidget, lbox));

        _ = gtk.g_signal_connect(
            tab.close_button, "clicked",
            @ptrCast(c.GCallback, close_tab_by_button),
            @ptrCast(c.gpointer, tab.box),
        );

        return tab;
    }
};

const Gui = struct {
    window: *c.GtkWidget,
    notebook: *c.GtkWidget,
    new_tab: *c.GtkWidget,
    split_view: *c.GtkWidget,
    rotate_view: *c.GtkWidget,
    preferences: *c.GtkWidget,
    close_tab: *c.GtkWidget,
    quit_app: *c.GtkWidget,

    fn init(builder: *c.GtkBuilder) Gui {
        return Gui {
            .window = gtk.builder_get_widget(builder, "window").?,
            .notebook = gtk.builder_get_widget(builder, "notebook").?,
            .new_tab = gtk.builder_get_widget(builder, "new_tab").?,
            .split_view = gtk.builder_get_widget(builder, "split_view").?,
            .rotate_view = gtk.builder_get_widget(builder, "rotate_view").?,
            .preferences = gtk.builder_get_widget(builder, "preferences").?,
            .close_tab = gtk.builder_get_widget(builder, "close_tab").?,
            .quit_app = gtk.builder_get_widget(builder, "quit_app").?,
        };
    }

    fn get_current_tab(self: Gui) Tab {
        const tab_num = c.gtk_notebook_get_current_page(@ptrCast(*c.GtkNotebook, self.notebook));
        const box_widget = c.gtk_notebook_get_nth_page(@ptrCast(*c.GtkNotebook, self.notebook), tab_num);
        const tab = if (tabs.get(@ptrToInt(box_widget))) |t| t else unreachable;
        return tab;
    }

    fn nth_tab(self: Gui, num: c_int) void {
        c.gtk_notebook_set_current_page(@ptrCast(*c.GtkNotebook, self.notebook), num);
    }

    fn prev_tab(self: Gui) void {
        const nb_ptr = @ptrCast(*c.GtkNotebook, self.notebook);
        const pages = c.gtk_notebook_get_n_pages(nb_ptr);
        const page = c.gtk_notebook_get_current_page(nb_ptr);
        if (page > 0) {
            c.gtk_notebook_prev_page(nb_ptr);
        } else {
            c.gtk_notebook_set_current_page(nb_ptr, pages - 1);
        }
    }

    fn next_tab(self: Gui) void {
        const nb_ptr = @ptrCast(*c.GtkNotebook, self.notebook);
        const pages = c.gtk_notebook_get_n_pages(nb_ptr);
        const page = c.gtk_notebook_get_current_page(nb_ptr);
        if (page < pages - 1) {
            c.gtk_notebook_next_page(nb_ptr);
        } else {
            c.gtk_notebook_set_current_page(nb_ptr, 0);
        }
    }

    fn connect_signals(self: Gui) void {
        _ = gtk.g_signal_connect(
            self.new_tab, "activate", @ptrCast(c.GCallback, new_tab_callback), null);

        _ = gtk.g_signal_connect(
            self.split_view, "activate", @ptrCast(c.GCallback, split_tab), null);

        _ = gtk.g_signal_connect(
            self.rotate_view, "activate", @ptrCast(c.GCallback, rotate_tab), null);

        _ = gtk.g_signal_connect(
            self.notebook, "page-removed", @ptrCast(c.GCallback, page_removed_callback), null);

        _ = gtk.g_signal_connect(
            self.notebook, "select-page", @ptrCast(c.GCallback, select_page_callback), null);

        _ = gtk.g_signal_connect(
            self.preferences, "activate", @ptrCast(c.GCallback, run_prefs), null);

        _ = gtk.g_signal_connect(
            self.close_tab, "activate", @ptrCast(c.GCallback, close_current_tab), null);

        _ = gtk.g_signal_connect(
            self.quit_app, "activate", @ptrCast(c.GCallback, quit_callback), null);

        _ = gtk.g_signal_connect(
            self.window, "delete-event", @ptrCast(c.GCallback, quit_callback), null);
    }

    fn connect_accels(self: Gui) void {
        const tab1_closure = c.g_cclosure_new(goto_tab_1, null, null);
        const tab2_closure = c.g_cclosure_new(goto_tab_2, null, null);
        const tab3_closure = c.g_cclosure_new(goto_tab_3, null, null);
        const tab4_closure = c.g_cclosure_new(goto_tab_4, null, null);
        const tab5_closure = c.g_cclosure_new(goto_tab_5, null, null);
        const tab6_closure = c.g_cclosure_new(goto_tab_6, null, null);
        const tab7_closure = c.g_cclosure_new(goto_tab_7, null, null);
        const tab8_closure = c.g_cclosure_new(goto_tab_8, null, null);
        const tab9_closure = c.g_cclosure_new(goto_tab_9, null, null);
        const alt_left_closure = c.g_cclosure_new(goto_prev_tab, null, null);
        const alt_right_closure = c.g_cclosure_new(goto_next_tab, null, null);
        const ctrl_page_up_closure = c.g_cclosure_new(goto_prev_tab, null, null);
        const ctrl_page_down_closure = c.g_cclosure_new(goto_next_tab, null, null);
        const accel_group = c.gtk_accel_group_new();
        c.gtk_accel_group_connect(
            accel_group, c.GDK_KEY_1, gtk.alt_mask, gtk.accel_locked, tab1_closure);
        c.gtk_accel_group_connect(
            accel_group, c.GDK_KEY_2, gtk.alt_mask, gtk.accel_locked, tab2_closure);
        c.gtk_accel_group_connect(
            accel_group, c.GDK_KEY_3, gtk.alt_mask, gtk.accel_locked, tab3_closure);
        c.gtk_accel_group_connect(
            accel_group, c.GDK_KEY_4, gtk.alt_mask, gtk.accel_locked, tab4_closure);
        c.gtk_accel_group_connect(
            accel_group, c.GDK_KEY_5, gtk.alt_mask, gtk.accel_locked, tab5_closure);
        c.gtk_accel_group_connect(
            accel_group, c.GDK_KEY_6, gtk.alt_mask, gtk.accel_locked, tab6_closure);
        c.gtk_accel_group_connect(
            accel_group, c.GDK_KEY_7, gtk.alt_mask, gtk.accel_locked, tab7_closure);
        c.gtk_accel_group_connect(
            accel_group, c.GDK_KEY_8, gtk.alt_mask, gtk.accel_locked, tab8_closure);
        c.gtk_accel_group_connect(
            accel_group, c.GDK_KEY_9, gtk.alt_mask, gtk.accel_locked, tab9_closure);
        c.gtk_accel_group_connect(
            accel_group, c.GDK_KEY_Left, gtk.alt_mask, gtk.accel_locked, alt_left_closure);
        c.gtk_accel_group_connect(
            accel_group, c.GDK_KEY_Right, gtk.alt_mask, gtk.accel_locked, alt_right_closure);
        c.gtk_accel_group_connect(
            accel_group, c.GDK_KEY_Page_Up, gtk.ctrl_mask, gtk.accel_locked, ctrl_page_up_closure);
        c.gtk_accel_group_connect(
            accel_group, c.GDK_KEY_Page_Down, gtk.ctrl_mask, gtk.accel_locked, ctrl_page_down_closure);
        c.gtk_window_add_accel_group(@ptrCast(*c.GtkWindow, self.window), accel_group);
    }
};

var gui: Gui = undefined;
var options: Opts = undefined;
var tabs: hashmap(u64, Tab) = undefined;
var conf = config.Config.default();

pub fn activate(application: *c.GtkApplication, opts: c.gpointer) void {
    // Cast the gpointer to a normal pointer and dereference it, giving us
    // our "opts" struct initialized earlier.
    options = @ptrCast(*Opts, @alignCast(8, opts)).*;
    tabs = hashmap(u64, Tab).init(allocator);
    defer tabs.deinit();

    const builder = c.gtk_builder_new();
    const glade_str = @embedFile("gui.glade");
    var ret = c.gtk_builder_add_from_string(builder, glade_str, glade_str.len, @intToPtr([*c][*c]c._GError, 0));
    if (ret == 0) {
        stderr.print("builder file fail\n", .{}) catch unreachable;
        std.process.exit(1);
    }
    c.gtk_builder_set_application(builder, application);

    gui = Gui.init(builder);
    const window_ptr = @ptrCast(*c.GtkWindow, gui.window);
    c.gtk_window_set_title(window_ptr, options.title);

    const notebook_ptr = @ptrCast(*c.GtkNotebook, gui.notebook);

    const tab = Tab.init(
        @ptrCast([*c][*c]c.gchar, &([2][*c]c.gchar{
            c.g_strdup(options.command),
            null,
        })),
    );
    tabs.putNoClobber(@ptrToInt(tab.box), tab) catch |e| {
        stderr.print("{}\n", .{e}) catch unreachable;
    };
    // We have to get the terminal in order to grab focus, use an
    // iterator and return the first (and only) entry's value field
    const kids = c.gtk_container_get_children(@ptrCast(*c.GtkContainer, tab.box));
    const term = c.g_list_nth_data(kids, 0);
    const term_ptr = @ptrCast(*c.GtkWidget, @alignCast(8, term));
    c.gtk_widget_show_all(gui.window);
    c.gtk_widget_grab_focus(term_ptr);

    gui.connect_signals();
    gui.connect_accels();

    c.gtk_main();
}

fn new_tab_callback(menuitem: *c.GtkMenuItem) void {
    const tab = Tab.init(
        @ptrCast([*c][*c]c.gchar, &([2][*c]c.gchar{
            c.g_strdup(options.command),
            null,
        })),
    );
    tabs.putNoClobber(@ptrToInt(tab.box), tab) catch |e| {
        stderr.print("{}\n", .{e}) catch unreachable;
    };
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
    _ = gtk.g_signal_connect(
        term,
        "child-exited",
        @ptrCast(c.GCallback, close_term_callback),
        null,
    );
    return term;
}

fn close_tab_by_button(button: *c.GtkButton, box: c.gpointer) void {
    const box_widget = @ptrCast(*c.GtkWidget, @alignCast(8, box));
    const key = @ptrToInt(box_widget);
    close_tab_by_ref(key);
}

fn close_tab_by_ref(key: u64) void {
    if (tabs.get(key)) |tab| {
        const num = c.gtk_notebook_page_num(@ptrCast(*c.GtkNotebook, gui.notebook), tab.box);
        // if num < 0 tab is already closed
        if (num >= 0) {
            c.gtk_notebook_remove_page(@ptrCast(*c.GtkNotebook, gui.notebook), num);
            _ = tabs.remove(key);
        }
    }
}

fn close_current_tab() void {
    const num = c.gtk_notebook_get_current_page(@ptrCast(*c.GtkNotebook, gui.notebook));
    const box = c.gtk_notebook_get_nth_page(@ptrCast(*c.GtkNotebook, gui.notebook), num);
    const key = @ptrToInt(box);
    close_tab_by_ref(key);
}

fn close_term_callback(term: *c.VteTerminal) void {
    const box = c.gtk_widget_get_parent(@ptrCast(*c.GtkWidget, term));
    const key = @ptrToInt(box);
    const num = c.gtk_notebook_page_num(@ptrCast(*c.GtkNotebook, gui.notebook), box);
    c.gtk_container_remove(
        @ptrCast(*c.GtkContainer, box),
        @ptrCast(*c.GtkWidget, term));
    c.gtk_widget_destroy(@ptrCast(*c.GtkWidget, term));
    if (tabs.get(key)) |tab| {
        const termkey = @ptrToInt(term);
        const kids = c.gtk_container_get_children(@ptrCast(*c.GtkContainer, box));
        const len = c.g_list_length(kids);
        if (len == 0) {
            close_tab_by_ref(key);
        } else {
            const first = c.g_list_nth_data(kids, 0);
            const first_ptr = @ptrCast(*c.GtkWidget, @alignCast(8, first));
            c.gtk_widget_grab_focus(first_ptr);
        }
    }
}

fn page_removed_callback() void {
    const pages = c.gtk_notebook_get_n_pages(@ptrCast(*c.GtkNotebook, gui.notebook));
    if (pages == 0) {
        c.gtk_main_quit();
    } else {
        select_page_callback();
    }
}

fn select_page_callback() void {
    const tab = gui.get_current_tab();
    const kids = c.gtk_container_get_children(@ptrCast(*c.GtkContainer, tab.box));
    const first = c.g_list_nth_data(kids, 0);
    const first_ptr = @ptrCast(*c.GtkWidget, @alignCast(8, first));
    c.gtk_widget_grab_focus(first_ptr);
}


fn split_tab() void {
    var tab = gui.get_current_tab();
    const command = @ptrCast([*c][*c]c.gchar, &([2][*c]c.gchar{
        c.g_strdup(options.command),
        null,
    }));
    const term = new_term(command);
    c.gtk_widget_show(term);
    c.gtk_box_pack_start(@ptrCast(*c.GtkBox, tab.box), term, 1, 1, 1);
}

fn rotate_tab() void {
    const tab = gui.get_current_tab();
    const orientation = c.gtk_orientable_get_orientation(@ptrCast(*c.GtkOrientable, tab.box));
    if (@enumToInt(orientation) == 0) {
        c.gtk_orientable_set_orientation(@ptrCast(*c.GtkOrientable, tab.box), gtk.vertical);
    } else {
        c.gtk_orientable_set_orientation(@ptrCast(*c.GtkOrientable, tab.box), gtk.horizontal);
    }
}

fn goto_tab_1() callconv(.C) void {
    gui.nth_tab(0);
}

fn goto_tab_2() callconv(.C) void {
    gui.nth_tab(1);
}

fn goto_tab_3() callconv(.C) void {
    gui.nth_tab(2);
}

fn goto_tab_4() callconv(.C) void {
    gui.nth_tab(3);
}

fn goto_tab_5() callconv(.C) void {
    gui.nth_tab(4);
}

fn goto_tab_6() callconv(.C) void {
    gui.nth_tab(5);
}

fn goto_tab_7() callconv(.C) void {
    gui.nth_tab(6);
}

fn goto_tab_8() callconv(.C) void {
    gui.nth_tab(7);
}

fn goto_tab_9() callconv(.C) void {
    gui.nth_tab(8);
}

fn goto_prev_tab() callconv(.C) void {
    gui.prev_tab();
}

fn goto_next_tab() callconv(.C) void {
    gui.next_tab();
}

fn run_prefs() void {
    if (prefs.run()) |newconf| {
        conf = newconf;
        std.debug.print("Title Style: {s}\n", .{conf.dynamic_title_style});
        const background = conf.background;
        switch (background) {
            .solid_color => std.debug.print("Background: Solid Color\n", .{}),
            .image => |value| {
                std.debug.print("Background Image File = {s}\nImage Style = {s}\n", .{value.file, value.style});
            },
            .transparent => |value| {
                std.debug.print("Background Transparency: {d}\n", .{value});
            },
        }
    }
}

pub fn quit_callback() void {
    c.gtk_main_quit();
}
