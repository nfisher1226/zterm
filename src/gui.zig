const std = @import("std");
const config = @import("config.zig");
usingnamespace @import("vte");
const prefs = @import("prefs.zig");
const allocator = std.heap.page_allocator;
const fmt = std.fmt;
const fs = std.fs;
const hashmap = std.AutoHashMap;
const os = std.os;
const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();

var conf = config.Config.default();
var gui: Gui = undefined;
var options: Opts = undefined;
var tabs: hashmap(u64, Tab) = undefined;
var terms: hashmap(u64, *c.VteTerminal) = undefined;

pub const Opts = struct {
    command: [:0]const u8,
    title: [:0]const u8,
    directory: [:0]const u8,
    hostname: [:0]const u8,
};

pub const Tab = struct {
    box: gtk.Box,
    tab_label: gtk.Label,
    close_button: gtk.Button,

    fn init(command: [:0]const u8) Tab {
        var tab = Tab{
            .box = gtk.Box.new(.horizontal, 0),
            .tab_label = gtk.Label.new("Zterm"),
            .close_button = gtk.Button.new_from_icon_name("window-close", .menu),
        };
        const term = new_term(command);
        const lbox = gtk.Box.new(.horizontal, 10);
        tab.close_button.set_relief(.none);
        const close_button_widget = tab.close_button.as_widget();
        close_button_widget.set_has_tooltip(true);
        close_button_widget.set_tooltip_text("Close tab");
        lbox.pack_start(tab.tab_label.as_widget(), false, true, 1);
        lbox.pack_start(close_button_widget, false, true, 1);
        lbox.as_widget().show_all();

        tab.box.set_homogeneous(true);
        tab.box.pack_start(term.as_widget(), true, true, 1);
        tab.box.as_widget().show_all();
        gui.notebook.append_page(tab.box.as_widget(), lbox.as_widget());
        gui.notebook.set_tab_label(tab.box.as_widget(), lbox.as_widget());

        tab.close_button.connect_clicked(@ptrCast(c.GCallback, close_tab_by_button), @ptrCast(c.gpointer, tab.box.ptr));

        return tab;
    }

    fn next_pane(self: Tab) void {
        if (self.box.as_container().get_children(allocator)) |kids| {
            defer kids.deinit();
            if (kids.items.len > 0) {
                var next: usize = 0;
                for (kids.items) |child, index| {
                    if (child.has_focus()) {
                        if (index < kids.items.len - 1) {
                            next = index + 1;
                        } else next = 0;
                    }
                }
                kids.items[next].grab_focus();
            }
        }
    }

    fn prev_pane(self: Tab) void {
        if (self.box.as_container().get_children(allocator)) |kids| {
            defer kids.deinit();
            if (kids.items.len > 0) {
                var prev: usize = 0;
                for (kids.items) |child, index| {
                    if (child.has_focus()) {
                        if (index > 0) {
                            prev = index - 1;
                        } else prev = kids.items.len - 1;
                    }
                }
                kids.items[prev].grab_focus();
            }
        }
    }
};

const Gui = struct {
    window: gtk.Window,
    notebook: gtk.Notebook,
    new_tab: *c.GtkWidget,
    split_view: *c.GtkWidget,
    rotate_view: *c.GtkWidget,
    preferences: *c.GtkWidget,
    close_tab: *c.GtkWidget,
    quit_app: *c.GtkWidget,

    fn init(builder: gtk.Builder) Gui {
        return Gui{
            .window = builder.get_widget("window").?.to_window().?,
            .notebook = builder.get_widget("notebook").?.to_notebook().?,
            .new_tab = @ptrCast(*c.GtkWidget, builder.get_widget("new_tab").?.ptr),
            .split_view = @ptrCast(*c.GtkWidget, builder.get_widget("split_view").?.ptr),
            .rotate_view = @ptrCast(*c.GtkWidget, builder.get_widget("rotate_view").?.ptr),
            .preferences = @ptrCast(*c.GtkWidget, builder.get_widget("preferences").?.ptr),
            .close_tab = @ptrCast(*c.GtkWidget, builder.get_widget("close_tab").?.ptr),
            .quit_app = @ptrCast(*c.GtkWidget, builder.get_widget("quit_app").?.ptr),
        };
    }

    fn get_current_tab(self: Gui) Tab {
        const num = self.notebook.get_current_page();
        const box = self.notebook.get_nth_page(num).?;
        return if (tabs.get(@ptrToInt(box.ptr))) |t| t else unreachable;
    }

    fn nth_tab(self: Gui, num: c_int) void {
        self.notebook.set_current_page(num);
    }

    fn prev_tab(self: Gui) void {
        const page = self.notebook.get_current_page();
        if (page > 0) {
            self.notebook.prev_page();
        } else {
            const pages = self.notebook.get_n_pages();
            self.notebook.set_current_page(pages - 1);
        }
    }

    fn next_tab(self: Gui) void {
        const pages = self.notebook.get_n_pages();
        const page = self.notebook.get_current_page();
        if (page < pages - 1) {
            self.notebook.next_page();
        } else {
            self.notebook.set_current_page(0);
        }
    }

    fn set_title(self: Gui) void {
        const style = conf.dynamic_title_style;
        const title = switch (style) {
            .replaces_title => fmt.allocPrintZ(allocator, "{s} on {s}", .{ options.directory, options.hostname }),
            .before_title => fmt.allocPrintZ(allocator, "{s} on {s} - {s}", .{ options.directory, options.hostname, conf.initial_title }),
            .after_title => fmt.allocPrintZ(allocator, "{s} - {s} on {s}", .{ conf.initial_title, options.directory, options.hostname }),
            .not_displayed => fmt.allocPrintZ(allocator, "{s}", .{conf.initial_title}),
        } catch return;
        defer allocator.free(title);
        self.window.set_title(title);
    }

    fn set_background(self: Gui) void {
        const bg = conf.background;
        switch (bg) {
            .transparent => |percent| {
                const opacity = percent / 100.0;
                self.window.as_widget().set_opacity(opacity);
            },
            .solid_color, .image => {
                self.window.as_widget().set_opacity(1.0);
            },
        }
        var iter = terms.valueIterator();
        while (iter.next()) |term| {
            conf.set(term.*);
        }
    }

    fn apply_settings(self: Gui) void {
        self.set_title();
        self.set_background();
    }

    fn connect_signals(self: Gui) void {
        _ = gtk.signal_connect(self.new_tab, "activate", @ptrCast(c.GCallback, new_tab_callback), null);
        _ = gtk.signal_connect(self.split_view, "activate", @ptrCast(c.GCallback, split_tab), null);
        _ = gtk.signal_connect(self.rotate_view, "activate", @ptrCast(c.GCallback, rotate_tab), null);
        self.notebook.connect_page_removed(@ptrCast(c.GCallback, page_removed_callback), null);
        self.notebook.connect_select_page(@ptrCast(c.GCallback, select_page_callback), null);
        _ = gtk.signal_connect(self.preferences, "activate", @ptrCast(c.GCallback, run_prefs), null);
        _ = gtk.signal_connect(self.close_tab, "activate", @ptrCast(c.GCallback, close_current_tab), null);
        _ = gtk.signal_connect(self.quit_app, "activate", @ptrCast(c.GCallback, quit_callback), null);
        self.window.as_widget().connect("delete-event", @ptrCast(c.GCallback, quit_callback), null);
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
        const alt_up_closure = c.g_cclosure_new(goto_prev_pane, null, null);
        const alt_down_closure = c.g_cclosure_new(goto_next_pane, null, null);
        const accel_group = c.gtk_accel_group_new();
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_1, c.GDK_MOD1_MASK, c.GTK_ACCEL_LOCKED, tab1_closure);
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_2, c.GDK_MOD1_MASK, c.GTK_ACCEL_LOCKED, tab2_closure);
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_3, c.GDK_MOD1_MASK, c.GTK_ACCEL_LOCKED, tab3_closure);
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_4, c.GDK_MOD1_MASK, c.GTK_ACCEL_LOCKED, tab4_closure);
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_5, c.GDK_MOD1_MASK, c.GTK_ACCEL_LOCKED, tab5_closure);
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_6, c.GDK_MOD1_MASK, c.GTK_ACCEL_LOCKED, tab6_closure);
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_7, c.GDK_MOD1_MASK, c.GTK_ACCEL_LOCKED, tab7_closure);
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_8, c.GDK_MOD1_MASK, c.GTK_ACCEL_LOCKED, tab8_closure);
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_9, c.GDK_MOD1_MASK, c.GTK_ACCEL_LOCKED, tab9_closure);
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_Left, c.GDK_MOD1_MASK, c.GTK_ACCEL_LOCKED, alt_left_closure);
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_Right, c.GDK_MOD1_MASK, c.GTK_ACCEL_LOCKED, alt_right_closure);
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_Page_Up, c.GDK_CONTROL_MASK, c.GTK_ACCEL_LOCKED, ctrl_page_up_closure);
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_Page_Down, c.GDK_CONTROL_MASK, c.GTK_ACCEL_LOCKED, ctrl_page_down_closure);
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_Up, c.GDK_MOD1_MASK, c.GTK_ACCEL_LOCKED, alt_up_closure);
        c.gtk_accel_group_connect(accel_group, c.GDK_KEY_Down, c.GDK_MOD1_MASK, c.GTK_ACCEL_LOCKED, alt_down_closure);
        c.gtk_window_add_accel_group(@ptrCast(*c.GtkWindow, self.window.ptr), accel_group);
    }
};

pub fn activate(application: *c.GtkApplication, opts: c.gpointer) void {
    // Cast the gpointer to a normal pointer and dereference it, giving us
    // our "opts" struct initialized earlier.
    options = @ptrCast(*Opts, @alignCast(8, opts)).*;
    tabs = hashmap(u64, Tab).init(allocator);
    defer tabs.deinit();

    terms = hashmap(u64, *c.VteTerminal).init(allocator);
    defer terms.deinit();

    const config_file = config.get_config_file(allocator);
    if (config_file) |f| {
        std.debug.print("{s}\n", .{f});
        defer allocator.free(f);
    }

    const builder = gtk.Builder.new();
    const glade_str = @embedFile("gui.glade");
    if (c.gtk_builder_add_from_string(builder.ptr, glade_str, glade_str.len, @intToPtr([*c][*c]c._GError, 0)) == 0) {
        stderr.print("builder file fail\n", .{}) catch unreachable;
        std.process.exit(1);
    }
    c.gtk_builder_set_application(builder.ptr, application);

    gui = Gui.init(builder);
    // In order to support transparency, we have to make the entire window
    // transparent, but we want to prevent the titlebar going transparent as well.
    // These three settings are a hack which achieves this.
    const screen = gui.window.as_widget().get_screen();
    const visual = c.gdk_screen_get_rgba_visual(screen);
    if (visual) |v| gui.window.as_widget().set_visual(v);

    gui.window.set_title(options.title);

    const tab = Tab.init(options.command);
    tabs.putNoClobber(@ptrToInt(tab.box.ptr), tab) catch |e| {
        stderr.print("{}\n", .{e}) catch unreachable;
    };
    // We have to get the terminal in order to grab focus, use an
    // iterator and return the first (and only) entry's value field
    const kids = c.gtk_container_get_children(@ptrCast(*c.GtkContainer, tab.box.ptr));
    const term = c.g_list_nth_data(kids, 0);
    const term_ptr = @ptrCast(*c.GtkWidget, @alignCast(8, term));
    gui.window.as_widget().show_all();
    c.gtk_widget_grab_focus(term_ptr);

    gui.connect_signals();
    gui.connect_accels();
    gui.apply_settings();

    c.gtk_main();
}

fn new_tab_callback() void {
    const tab = Tab.init(options.command);
    tabs.putNoClobber(@ptrToInt(tab.box.ptr), tab) catch |e| {
        stderr.print("{}\n", .{e}) catch unreachable;
    };
}

fn new_term(command: [:0]const u8) vte.Terminal {
    const term = vte.Terminal.new();
    terms.put(@ptrToInt(term.ptr), term.ptr) catch {};
    term.spawn_async(.default, options.directory, command, null, .default, null, -1, null);
    conf.set(term.ptr);
    _ = gtk.signal_connect(
        term.ptr,
        "child-exited",
        @ptrCast(c.GCallback, close_term_callback),
        null,
    );
    return term;
}

fn close_tab_by_button(_: *c.GtkButton, box: c.gpointer) void {
    const box_widget = @ptrCast(*c.GtkWidget, @alignCast(8, box));
    const key = @ptrToInt(box_widget);
    close_tab_by_ref(key);
}

fn close_tab_by_ref(key: u64) void {
    if (tabs.get(key)) |tab| {
        const num = gui.notebook.page_num(tab.box.as_widget());
        // if num < 0 tab is already closed
        if (num) |n| {
            if (n >= 0) {
                gui.notebook.remove_page(n);
                _ = tabs.remove(key);
            }
        }
    }
}

fn close_current_tab() void {
    const num = gui.notebook.get_current_page();
    const box = gui.notebook.get_nth_page(num);
    if (box) |b| {
        const key = @ptrToInt(b.ptr);
        close_tab_by_ref(key);
    }
}

fn close_term_callback(term: *c.VteTerminal) void {
    const box = c.gtk_widget_get_parent(@ptrCast(*c.GtkWidget, term));
    const key = @ptrToInt(box);
    const termkey = @ptrToInt(@ptrCast(*c.GtkWidget, term));
    _ = terms.remove(termkey);
    c.gtk_container_remove(@ptrCast(*c.GtkContainer, box), @ptrCast(*c.GtkWidget, term));
    c.gtk_widget_destroy(@ptrCast(*c.GtkWidget, term));
    if (tabs.get(key)) |_| {
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
    const pages = gui.notebook.get_n_pages();
    if (pages == 0) {
        c.gtk_main_quit();
    } else {
        select_page_callback();
    }
}

fn select_page_callback() void {
    const tab = gui.get_current_tab();
    const kids = c.gtk_container_get_children(@ptrCast(*c.GtkContainer, tab.box.ptr));
    const first = c.g_list_nth_data(kids, 0);
    const first_ptr = @ptrCast(*c.GtkWidget, @alignCast(8, first));
    c.gtk_widget_grab_focus(first_ptr);
}

fn split_tab() void {
    var tab = gui.get_current_tab();
    const term = new_term(options.command);
    term.as_widget().show();
    tab.box.pack_start(term.as_widget(), true, true, 1);
}

fn rotate_tab() void {
    const tab = gui.get_current_tab();
    const orientable = tab.box.as_orientable();
    const orientation = orientable.get_orientation();
    switch (orientation) {
        .horizontal => orientable.set_orientation(.vertical),
        .vertical => orientable.set_orientation(.horizontal),
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

fn goto_next_pane() callconv(.C) void {
    const tab = gui.get_current_tab();
    tab.next_pane();
}

fn goto_prev_pane() callconv(.C) void {
    const tab = gui.get_current_tab();
    tab.prev_pane();
}

fn run_prefs() void {
    if (prefs.run(conf)) |newconf| {
        conf = newconf;
        gui.apply_settings();
    }
}

pub fn quit_callback() void {
    c.gtk_main_quit();
}
