const VTE = @import("vte");
const c = VTE.c;
const gtk = VTE.gtk;
const vte = VTE.vte;
const std = @import("std");
const allocator = std.heap.page_allocator;
const Closures = @import("gui.zig").Closures;
const k = @import("keys.zig");
const Accel = k.Accel;
const Keys = k.Keys;

pub const Menu = struct {
    new_tab: gtk.MenuItem,
    split_view: gtk.MenuItem,
    rotate_view: gtk.MenuItem,
    copy: gtk.MenuItem,
    paste: gtk.MenuItem,
    about: gtk.MenuItem,
    preferences: gtk.MenuItem,
    close_tab: gtk.MenuItem,
    quit: gtk.MenuItem,

    const Self = @This();

    pub fn init(builder: gtk.Builder) Self {
        return Self{
            .new_tab = builder.get_widget("new_tab").?.to_menu_item().?,
            .split_view = builder.get_widget("split_view").?.to_menu_item().?,
            .rotate_view = builder.get_widget("rotate_view").?.to_menu_item().?,
            .copy = builder.get_widget("copy").?.to_menu_item().?,
            .about = builder.get_widget("about").?.to_menu_item().?,
            .paste = builder.get_widget("paste").?.to_menu_item().?,
            .preferences = builder.get_widget("preferences").?.to_menu_item().?,
            .close_tab = builder.get_widget("close_tab").?.to_menu_item().?,
            .quit = builder.get_widget("quit_app").?.to_menu_item().?,
        };
    }

    pub fn setAccels(self: Self, accel_group: *c.GtkAccelGroup, keys: Keys) void {
        const newTab = c.g_cclosure_new(Closures.newTab, null, null);
        const splitView = c.g_cclosure_new(Closures.splitView, null, null);
        const rotateView = c.g_cclosure_new(Closures.rotateView, null, null);
        const copy = c.g_cclosure_new(Closures.copy, null, null);
        const paste = c.g_cclosure_new(Closures.paste, null, null);
        const quit = c.g_cclosure_new(Closures.quit, null, null);

        var accel: Accel = undefined;

        if (self.new_tab.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.tabs.new_tab);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, newTab);
        }

        if (self.split_view.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.views.split_view);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, splitView);
        }

        if (self.rotate_view.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.views.rotate_view);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, rotateView);
        }

        if (self.copy.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.actions.copy);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, copy);
        }

        if (self.paste.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.actions.paste);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, paste);
        }

        if (self.quit.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.actions.quit);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, quit);
        }
    }
};

pub const Nav = struct {
    prev_pane: gtk.MenuItem,
    next_pane: gtk.MenuItem,
    prev_tab: gtk.MenuItem,
    next_tab: gtk.MenuItem,
    tab1: gtk.MenuItem,
    tab2: gtk.MenuItem,
    tab3: gtk.MenuItem,
    tab4: gtk.MenuItem,
    tab5: gtk.MenuItem,
    tab6: gtk.MenuItem,
    tab7: gtk.MenuItem,
    tab8: gtk.MenuItem,
    tab9: gtk.MenuItem,

    const Self = @This();

    pub fn init(builder: gtk.Builder) Self {
        return Self{
            .prev_pane = builder.get_widget("prev_pane").?.to_menu_item().?,
            .next_pane = builder.get_widget("next_pane").?.to_menu_item().?,
            .prev_tab = builder.get_widget("prev_tab").?.to_menu_item().?,
            .next_tab = builder.get_widget("next_tab").?.to_menu_item().?,
            .tab1 = builder.get_widget("tab_1").?.to_menu_item().?,
            .tab2 = builder.get_widget("tab_2").?.to_menu_item().?,
            .tab3 = builder.get_widget("tab_3").?.to_menu_item().?,
            .tab4 = builder.get_widget("tab_4").?.to_menu_item().?,
            .tab5 = builder.get_widget("tab_5").?.to_menu_item().?,
            .tab6 = builder.get_widget("tab_6").?.to_menu_item().?,
            .tab7 = builder.get_widget("tab_7").?.to_menu_item().?,
            .tab8 = builder.get_widget("tab_8").?.to_menu_item().?,
            .tab9 = builder.get_widget("tab_9").?.to_menu_item().?,
        };
    }

    pub fn setAccels(self: Self, accel_group: *c.GtkAccelGroup, keys: Keys) void {
        const tab1 = c.g_cclosure_new(Closures.tab1, null, null);
        const tab2 = c.g_cclosure_new(Closures.tab2, null, null);
        const tab3 = c.g_cclosure_new(Closures.tab3, null, null);
        const tab4 = c.g_cclosure_new(Closures.tab4, null, null);
        const tab5 = c.g_cclosure_new(Closures.tab5, null, null);
        const tab6 = c.g_cclosure_new(Closures.tab6, null, null);
        const tab7 = c.g_cclosure_new(Closures.tab7, null, null);
        const tab8 = c.g_cclosure_new(Closures.tab8, null, null);
        const tab9 = c.g_cclosure_new(Closures.tab9, null, null);
        const prevPane = c.g_cclosure_new(Closures.prevPane, null, null);
        const nextPane = c.g_cclosure_new(Closures.nextPane, null, null);
        const prevTab = c.g_cclosure_new(Closures.prevTab, null, null);
        const nextTab = c.g_cclosure_new(Closures.nextTab, null, null);

        var accel: Accel = undefined;

        if (self.tab1.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.tabs.tab1);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, tab1);
        }

        if (self.tab2.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.tabs.tab2);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, tab2);
        }

        if (self.tab3.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.tabs.tab3);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, tab3);
        }

        if (self.tab4.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.tabs.tab4);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, tab4);
        }

        if (self.tab5.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.tabs.tab5);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, tab5);
        }

        if (self.tab6.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.tabs.tab6);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, tab6);
        }

        if (self.tab7.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.tabs.tab7);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, tab7);
        }

        if (self.tab8.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.tabs.tab8);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, tab8);
        }

        if (self.tab9.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.tabs.tab9);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, tab9);
        }

        if (self.prev_pane.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.views.prev_view);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, prevPane);
        }

        if (self.next_pane.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.views.next_view);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, nextPane);
        }

        if (self.prev_tab.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.tabs.prev_tab);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, prevTab);
        }

        if (self.next_tab.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            accel = Accel.parse(keys.tabs.next_tab);
            c.gtk_accel_map_add_entry(p.ptr, accel.key, accel.mods);
            c.gtk_accel_group_connect_by_path(accel_group, p.ptr, nextTab);
        }
    }
};
