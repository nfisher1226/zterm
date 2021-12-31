const VTE = @import("vte");
const c = VTE.c;
const gtk = VTE.gtk;
const vte = VTE.vte;
const std = @import("std");
const allocator = std.heap.page_allocator;
const gui = @import("gui.zig");

pub const Menu = struct {
    new_tab: gtk.MenuItem,
    split_view: gtk.MenuItem,
    rotate_view: gtk.MenuItem,
    copy: gtk.MenuItem,
    paste: gtk.MenuItem,
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
            .paste = builder.get_widget("paste").?.to_menu_item().?,
            .preferences = builder.get_widget("preferences").?.to_menu_item().?,
            .close_tab = builder.get_widget("close_tab").?.to_menu_item().?,
            .quit = builder.get_widget("quit_app").?.to_menu_item().?,
        };
    }

    pub fn setAccels(self: Self) void {
        _ = self;
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

    pub fn setAccels(self: Self, accel_group: *c.GtkAccelGroup) void {
        const tab1_closure = c.g_cclosure_new(gui.goto_tab_1, null, null);
        const tab2_closure = c.g_cclosure_new(gui.goto_tab_2, null, null);
        const tab3_closure = c.g_cclosure_new(gui.goto_tab_3, null, null);
        const tab4_closure = c.g_cclosure_new(gui.goto_tab_4, null, null);
        const tab5_closure = c.g_cclosure_new(gui.goto_tab_5, null, null);
        const tab6_closure = c.g_cclosure_new(gui.goto_tab_6, null, null);
        const tab7_closure = c.g_cclosure_new(gui.goto_tab_7, null, null);
        const tab8_closure = c.g_cclosure_new(gui.goto_tab_8, null, null);
        const tab9_closure = c.g_cclosure_new(gui.goto_tab_9, null, null);
        const prev_pane_closure = c.g_cclosure_new(gui.goto_prev_pane, null, null);
        const next_pane_closure = c.g_cclosure_new(gui.goto_next_pane, null, null);
        const prev_tab_closure = c.g_cclosure_new(gui.goto_prev_tab, null, null);
        const next_tab_closure = c.g_cclosure_new(gui.goto_next_tab, null, null);

        if (self.tab1.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            if (c.gtk_accel_map_lookup_entry("<Zterm>/AppMenu/Nav/Tab1", null) == 0) {
                c.gtk_accel_map_add_entry(p, c.GDK_KEY_1, c.GDK_MOD1_MASK);
            }
            c.gtk_accel_group_connect_by_path(accel_group, p, tab1_closure);
        }

        if (self.tab2.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            if (c.gtk_accel_map_lookup_entry("<Zterm>/AppMenu/Nav/Tab2", null) == 0) {
                c.gtk_accel_map_add_entry(p, c.GDK_KEY_2, c.GDK_MOD1_MASK);
            }
            c.gtk_accel_group_connect_by_path(accel_group, p, tab2_closure);
        }

        if (self.tab3.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            if (c.gtk_accel_map_lookup_entry("<Zterm>/AppMenu/Nav/Tab3", null) == 0) {
                c.gtk_accel_map_add_entry(p, c.GDK_KEY_3, c.GDK_MOD1_MASK);
            }
            c.gtk_accel_group_connect_by_path(accel_group, p, tab3_closure);
        }

        if (self.tab4.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            if (c.gtk_accel_map_lookup_entry("<Zterm>/AppMenu/Nav/Tab4", null) == 0) {
                c.gtk_accel_map_add_entry(p, c.GDK_KEY_4, c.GDK_MOD1_MASK);
            }
            c.gtk_accel_group_connect_by_path(accel_group, p, tab4_closure);
        }

        if (self.tab5.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            if (c.gtk_accel_map_lookup_entry("<Zterm>/AppMenu/Nav/Tab5", null) == 0) {
                c.gtk_accel_map_add_entry(p, c.GDK_KEY_5, c.GDK_MOD1_MASK);
            }
            c.gtk_accel_group_connect_by_path(accel_group, p, tab5_closure);
        }

        if (self.tab6.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            if (c.gtk_accel_map_lookup_entry("<Zterm>/AppMenu/Nav/Tab6", null) == 0) {
                c.gtk_accel_map_add_entry(p, c.GDK_KEY_6, c.GDK_MOD1_MASK);
            }
            c.gtk_accel_group_connect_by_path(accel_group, p, tab6_closure);
        }

        if (self.tab7.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            if (c.gtk_accel_map_lookup_entry("<Zterm>/AppMenu/Nav/Tab7", null) == 0) {
                c.gtk_accel_map_add_entry(p, c.GDK_KEY_7, c.GDK_MOD1_MASK);
            }
            c.gtk_accel_group_connect_by_path(accel_group, p, tab7_closure);
        }

        if (self.tab8.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            if (c.gtk_accel_map_lookup_entry("<Zterm>/AppMenu/Nav/Tab8", null) == 0) {
                c.gtk_accel_map_add_entry(p, c.GDK_KEY_8, c.GDK_MOD1_MASK);
            }
            c.gtk_accel_group_connect_by_path(accel_group, p, tab8_closure);
        }

        if (self.tab9.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            if (c.gtk_accel_map_lookup_entry("<Zterm>/AppMenu/Nav/Tab9", null) == 0) {
                c.gtk_accel_map_add_entry(p, c.GDK_KEY_9, c.GDK_MOD1_MASK);
            }
            c.gtk_accel_group_connect_by_path(accel_group, p, tab9_closure);
        }

        if (self.prev_pane.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            if (c.gtk_accel_map_lookup_entry("<Zterm>/AppMenu/Nav/PrevPane", null) == 0) {
                c.gtk_accel_map_add_entry(p, c.GDK_KEY_Left, c.GDK_MOD1_MASK);
            }
            c.gtk_accel_group_connect_by_path(accel_group, p, prev_pane_closure);
        }

        if (self.next_pane.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            if (c.gtk_accel_map_lookup_entry("<Zterm>/AppMenu/Nav/NextPane", null) == 0) {
                c.gtk_accel_map_add_entry(p, c.GDK_KEY_Right, c.GDK_MOD1_MASK);
            }
            c.gtk_accel_group_connect_by_path(accel_group, p, next_pane_closure);
        }

        if (self.prev_tab.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            if (c.gtk_accel_map_lookup_entry("<Zterm>/AppMenu/Nav/PrevTab", null) == 0) {
                c.gtk_accel_map_add_entry(p, c.GDK_KEY_Up, c.GDK_MOD1_MASK);
            }
            c.gtk_accel_group_connect_by_path(accel_group, p, prev_tab_closure);
        }

        if (self.next_tab.get_accel_path(allocator)) |p| {
            defer allocator.free(p);
            if (c.gtk_accel_map_lookup_entry("<Zterm>/AppMenu/Nav/NextTab", null) == 0) {
                c.gtk_accel_map_add_entry(p, c.GDK_KEY_Down, c.GDK_MOD1_MASK);
            }
            c.gtk_accel_group_connect_by_path(accel_group, p, next_tab_closure);
        }
    }
};
