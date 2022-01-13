const VTE = @import("vte");
const c = VTE.c;
const gtk = VTE.gtk;
const vte = VTE.vte;
const std = @import("std");
const config = @import("config.zig");
const keys = @import("keys.zig");
const menus = @import("menus.zig");
const prefs = @import("prefs.zig");
const version = @import("version.zig").version;
const Keys = keys.Keys;
const Menu = menus.Menu;
const Nav = menus.Nav;
const allocator = std.heap.page_allocator;
const fmt = std.fmt;
const fs = std.fs;
const hashmap = std.AutoHashMap;
const mem = std.mem;
const os = std.os;
const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();

var conf: config.Config = undefined;
var gui: Gui = undefined;
var options: Opts = undefined;
var tabs: hashmap(u64, Tab) = undefined;
var terms: hashmap(u64, *c.VteTerminal) = undefined;
pub var css_provider: *c.GtkCssProvider = undefined;

pub const Opts = struct {
    command: [:0]const u8,
    title: [:0]const u8,
    directory: [:0]const u8,
    hostname: [:0]const u8,
    config_dir: []const u8,
};

pub const Tab = struct {
    box: gtk.Box,
    tab_label: gtk.Label,
    close_button: gtk.Button,

    const Self = @This();

    fn init(command: [:0]const u8) Self {
        var tab = Self{
            .box = gtk.Box.new(.horizontal, 0),
            .tab_label = gtk.Label.new("Zterm"),
            .close_button = gtk.Button.new_from_icon_name("window-close", .menu),
        };
        const term = Callbacks.newTerm(command);
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
        gui.notebook.set_tab_reorderable(tab.box.as_widget(), true);

        tab.close_button.connect_clicked(@ptrCast(c.GCallback, close_tab_by_button), @ptrCast(c.gpointer, tab.box.ptr));

        return tab;
    }

    fn currentTerm(self: Self) ?vte.Terminal {
        if (self.box.as_container().get_children(allocator)) |kids| {
            defer kids.deinit();
            for (kids.items) |child| {
                if (child.has_focus()) {
                    return vte.Terminal.from_widget(child);
                }
            }
            return null;
        } else return null;
    }

    fn termTitle(self: Self, alloc: mem.Allocator) ?[:0]const u8 {
        if (self.currentTerm()) |term| {
            return if (term.get_window_title(alloc)) |s| s else null;
        } else return null;
    }

    fn nextPane(self: Self) void {
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

    fn prevPane(self: Self) void {
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

    fn rotate(self: Self) void {
        const orientable = self.box.as_orientable();
        const orientation = orientable.get_orientation();
        switch (orientation) {
            .horizontal => orientable.set_orientation(.vertical),
            .vertical => orientable.set_orientation(.horizontal),
        }
    }

    fn split(self: Self) void {
        const term = Callbacks.newTerm(options.command);
        term.as_widget().show();
        self.box.pack_start(term.as_widget(), true, true, 1);
    }

    fn selectPage(self: Self) void {
        if (self.box.as_container().get_children(allocator)) |kids| {
            defer kids.deinit();
            kids.items[0].grab_focus();
        }
    }
};

const Gui = struct {
    window: gtk.Window,
    notebook: gtk.Notebook,
    menu: Menu,
    nav: Nav,

    const Self = @This();

    fn init(builder: gtk.Builder) Self {
        const glade_str = @embedFile("gui.glade");
        if (c.gtk_builder_add_from_string(builder.ptr, glade_str, glade_str.len, @intToPtr([*c][*c]c._GError, 0)) == 0) {
            stderr.print("builder file fail\n", .{}) catch unreachable;
            std.process.exit(1);
        }
        return Self{
            .window = builder.get_widget("window").?.to_window().?,
            .notebook = builder.get_widget("notebook").?.to_notebook().?,
            .menu = Menu.init(builder),
            .nav = Nav.init(builder),
        };
    }

    fn currentTab(self: Self) ?Tab {
        const num = self.notebook.get_current_page();
        if (self.notebook.get_nth_page(num)) |box| {
            return if (tabs.get(@ptrToInt(box.ptr))) |t| t else unreachable;
        } else return null;
    }

    fn currentTerm(self: Gui) ?vte.Terminal {
        if (self.currentTab()) |tab| {
            return if (tab.currentTerm()) |t| t else null;
        } else return null;
    }

    fn nthTab(self: Self, num: c_int) void {
        self.notebook.set_current_page(num);
    }

    fn prevTab(self: Self) void {
        const page = self.notebook.get_current_page();
        if (page > 0) {
            self.notebook.prev_page();
        } else {
            const pages = self.notebook.get_n_pages();
            self.notebook.set_current_page(pages - 1);
        }
    }

    fn nextTab(self: Self) void {
        const pages = self.notebook.get_n_pages();
        const page = self.notebook.get_current_page();
        if (page < pages - 1) {
            self.notebook.next_page();
        } else {
            self.notebook.set_current_page(0);
        }
    }

    fn setTitle(self: Self) void {
        const style = conf.dynamic_title_style;
        const title = switch (style) {
            .replaces_title => fmt.allocPrintZ(allocator, "{s} on {s}", .{ options.directory, options.hostname }),
            .before_title => fmt.allocPrintZ(allocator, "{s} on {s} ~ {s}-{s}", .{ options.directory, options.hostname, conf.initial_title, version }),
            .after_title => fmt.allocPrintZ(allocator, "{s}-{s} ~ {s} on {s}", .{ conf.initial_title, version, options.directory, options.hostname }),
            .not_displayed => fmt.allocPrintZ(allocator, "{s}-{s}", .{conf.initial_title, version}),
        } catch return;
        defer allocator.free(title);
        self.window.set_title(title);
    }

    fn setBackground(self: Self) void {
        const bg = conf.background;
        switch (bg) {
            .transparent => |percent| {
                const opacity = percent / 100.0;
                self.window.as_widget().set_opacity(opacity);
            },
            .solid_color, .image, .gradient => {
                self.window.as_widget().set_opacity(1.0);
            },
        }
        var iter = terms.valueIterator();
        while (iter.next()) |term| {
            conf.set(term.*);
        }
    }

    fn applySettings(self: Self) void {
        self.setTitle();
        self.setBackground();
    }

    fn pageRemoved(self: Self) void {
        const pages = self.notebook.get_n_pages();
        if (pages == 0) {
            c.gtk_main_quit();
        } else {
            Callbacks.selectPage();
        }
    }

    fn connectSignals(self: Self) void {
        self.menu.new_tab.connect_activate(@ptrCast(c.GCallback, Callbacks.newTab), null);
        self.menu.split_view.connect_activate(@ptrCast(c.GCallback, Callbacks.splitTab), null);
        self.menu.rotate_view.connect_activate(@ptrCast(c.GCallback, Callbacks.rotateView), null);
        self.notebook.connect_page_removed(@ptrCast(c.GCallback, Callbacks.pageRemoved), null);
        self.notebook.connect_select_page(@ptrCast(c.GCallback, Callbacks.selectPage), null);
        self.menu.preferences.connect_activate(@ptrCast(c.GCallback, runPrefs), null);
        self.menu.close_tab.connect_activate(@ptrCast(c.GCallback, Callbacks.closeCurrentTab), null);
        self.menu.quit.connect_activate(@ptrCast(c.GCallback, c.gtk_main_quit), null);
        self.window.as_widget().connect("delete-event", @ptrCast(c.GCallback, c.gtk_main_quit), null);
    }

    fn connectAccels(self: Self) void {
        // Check to see if our keyfile exists, and if it doesn't then create it
        // from the defaults
        const bindings: Keys = if (keys.getKeyFile(allocator)) |file| kblk: {
            defer allocator.free(file);
            if (fs.cwd().openFile(file, .{ .read=true, .write=false })) |f| {
                defer f.close();
                break :kblk if (Keys.fromFile(f)) |k| k else Keys.default();
            } else |_| {
                const k = Keys.default();
                Keys.save(k);
                break :kblk k;
            }
        } else Keys.default();

        const accel_group = c.gtk_accel_group_new();
        self.menu.setAccels(accel_group, bindings);
        self.nav.setAccels(accel_group, bindings);
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

    conf = if (config.Config.fromFile(options.config_dir)) |cfg| cfg else config.Config.default();
    //conf = config.Config.default();

    const builder = gtk.Builder.new();
    c.gtk_builder_set_application(builder.ptr, application);

    gui = Gui.init(builder);
    // In order to support transparency, we have to make the entire window
    // transparent, but we want to prevent the titlebar going transparent as well.
    // These three settings are a hack which achieves this.
    const screen = gui.window.as_widget().get_screen();
    const visual = c.gdk_screen_get_rgba_visual(screen);
    if (visual) |v| gui.window.as_widget().set_visual(v);

    css_provider = c.gtk_css_provider_new();
    c.gtk_style_context_add_provider_for_screen(
        screen,
        @ptrCast(*c.GtkStyleProvider, css_provider),
        c.GTK_STYLE_PROVIDER_PRIORITY_USER);

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

    gui.connectSignals();
    gui.connectAccels();
    gui.applySettings();

    c.gtk_main();
}

const Callbacks = struct {
    fn newTab() void {
        const tab = Tab.init(options.command);
        tabs.putNoClobber(@ptrToInt(tab.box.ptr), tab) catch |e| {
            stderr.print("{}\n", .{e}) catch unreachable;
        };
    }

    fn newTerm(command: [:0]const u8) vte.Terminal {
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

    fn splitTab() void {
        if (gui.currentTab()) |t| t.split();
    }

    fn rotateView() void {
        if (gui.currentTab()) |t| t.rotate();
    }

    fn pageRemoved() void {
        gui.pageRemoved();
    }

    fn selectPage() void {
        if (gui.currentTab()) |t| t.selectPage();
    }

    fn closeCurrentTab() void {
        const num = gui.notebook.get_current_page();
        const box = gui.notebook.get_nth_page(num);
        if (box) |b| {
            const key = @ptrToInt(b.ptr);
            close_tab_by_ref(key);
        }
    }
};

fn close_tab_by_button(_: *c.GtkButton, box: c.gpointer) void {
    const box_widget = @ptrCast(*c.GtkWidget, @alignCast(8, box));
    const key = @ptrToInt(box_widget);
    close_tab_by_ref(key);
}

fn close_tab_by_ref(key: u64) void {
    if (tabs.get(key)) |tab| {
        const num = gui.notebook.page_num(tab.box.as_widget());
        if (num) |n| {
            // if num < 0 tab is already closed
            if (n >= 0) {
                gui.notebook.remove_page(n);
                _ = tabs.remove(key);
            }
        }
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

pub fn runPrefs() void {
    if (prefs.run(conf)) |newconf| {
        conf = newconf;
        gui.applySettings();
        if (config.getConfigDir(allocator)) |d| {
            conf.save(d);
        }
    }
}

// C style closures below
pub const Closures = struct {
    pub fn newTab() callconv(.C) void {
        Callbacks.newTab();
    }

    pub fn splitView() callconv(.C) void {
        Callbacks.splitTab();
    }

    pub fn rotateView() callconv(.C) void {
        Callbacks.rotateView();
    }

    pub fn quit() callconv(.C) void {
        c.gtk_main_quit();
    }

    pub fn tab1() callconv(.C) void {
        gui.nthTab(0);
    }

    pub fn tab2() callconv(.C) void {
        gui.nthTab(1);
    }

    pub fn tab3() callconv(.C) void {
        gui.nthTab(2);
    }

    pub fn tab4() callconv(.C) void {
        gui.nthTab(3);
    }

    pub fn tab5() callconv(.C) void {
        gui.nthTab(4);
    }

    pub fn tab6() callconv(.C) void {
        gui.nthTab(5);
    }

    pub fn tab7() callconv(.C) void {
        gui.nthTab(6);
    }

    pub fn tab8() callconv(.C) void {
        gui.nthTab(7);
    }

    pub fn tab9() callconv(.C) void {
        gui.nthTab(8);
    }

    pub fn prevTab() callconv(.C) void {
        gui.prevTab();
    }

    pub fn nextTab() callconv(.C) void {
        gui.nextTab();
    }

    pub fn nextPane() callconv(.C) void {
        if (gui.currentTab()) |t| t.nextPane();
    }

    pub fn prevPane() callconv(.C) void {
        if (gui.currentTab()) |t| t.prevPane();
    }

    pub fn copy() callconv(.C) void {
        if (gui.currentTab()) |tab| {
            if (tab.currentTerm()) |term| {
                term.copy_primary();
            }
        }
    }

    pub fn paste() callconv(.C) void {
        if (gui.currentTab()) |tab| {
            if (tab.currentTerm()) |term| {
                term.paste_primary();
            }
        }
    }
};
