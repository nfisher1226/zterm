const VTE = @import("vte");
const c = VTE.c;
const gtk = VTE.gtk;
const vte = VTE.vte;
const std = @import("std");
const config = @import("config.zig");
const prefs = @import("prefs.zig");
const version = @import("version.zig").version;
const menus = @import("menus.zig");
const Menu = menus.Menu;
const Nav = menus.Nav;
const allocator = std.heap.page_allocator;
const known_folders = @import("known-folders");
const nt = @import("nestedtext");
const fs = std.fs;
const math = std.math;
const mem = std.mem;
const os = std.os;
const path = std.fs.path;

pub fn getKeyFile(alloc: mem.Allocator) ?[]const u8 {
    const dir = known_folders.getPath(alloc, .local_configuration) catch return null;
    if (dir) |d| {
        return path.join(alloc, &[_][]const u8{ d, "zterm/keys.nt" }) catch return null;
    } else {
        return if (os.getenv("HOME")) |h| path.join(alloc, &[_][]const u8{ h, ".config/zterm/keys.nt" }) catch return null else null;
    }
}

pub const Actions = struct {
    copy: []const u8,
    paste: []const u8,
    quit: []const u8,

    const Self = @This();

    fn default() Self {
        return Self{
            .copy = "<Primary><Shift>c",
            .paste = "<Primary><Shift>v",
            .quit = "<Primary><Shift>q",
        };
    }
};

pub const Tabs = struct {
    new_tab: []const u8,
    prev_tab: []const u8,
    next_tab: []const u8,
    tab1: []const u8,
    tab2: []const u8,
    tab3: []const u8,
    tab4: []const u8,
    tab5: []const u8,
    tab6: []const u8,
    tab7: []const u8,
    tab8: []const u8,
    tab9: []const u8,

    const Self = @This();

    fn default() Self {
        return Self{
            .new_tab = "<Primary><Shift>t",
            .prev_tab = "<Alt>Up",
            .next_tab = "<Alt>Down",
            .tab1 = "<Alt>1",
            .tab2 = "<Alt>2",
            .tab3 = "<Alt>3",
            .tab4 = "<Alt>4",
            .tab5 = "<Alt>5",
            .tab6 = "<Alt>6",
            .tab7 = "<Alt>7",
            .tab8 = "<Alt>8",
            .tab9 = "<Alt>9",
        };
    }
};

pub const Views = struct {
    split_view: []const u8,
    rotate_view: []const u8,
    prev_view: []const u8,
    next_view: []const u8,

    const Self = @This();

    fn default() Self {
        return Self{
            .split_view = "<Primary><Shift>Return",
            .rotate_view = "<Alt>r",
            .prev_view = "<Alt>Left",
            .next_view = "<Alt>Right",
        };
    }
};

pub const Accel = struct {
    key: c_uint,
    mods: c.GdkModifierType,

    const Self = @This();

    pub fn parse(accel: []const u8) Self {
        var key: c_uint = undefined;
        var mods: c.GdkModifierType = undefined;
        c.gtk_accelerator_parse(@ptrCast([*c]const u8, accel.ptr), &key, &mods);
        return Self{
            .key = key,
            .mods = mods,
        };
    }
};

pub const Keys = struct {
    actions: Actions,
    tabs: Tabs,
    views: Views,

    const Self = @This();

    pub fn default() Self {
        return Self{
            .actions = Actions.default(),
            .tabs = Tabs.default(),
            .views = Views.default(),
        };
    }

    pub fn fromFile(fd: fs.File) ?Self {
        const text = fd.reader().readAllAlloc(allocator, math.maxInt(usize)) catch return null;
        defer allocator.free(text);
        var parser = nt.Parser.init(allocator, .{});
        @setEvalBranchQuota(4000);
        const keys = parser.parseTyped(Keys, text) catch return null;
        return keys;
    }

    pub fn load(self: Self) void {
        var accel = Accel.parse(self.actions.copy);
        c.gtk_accel_map_add_entry("<Zterm>/ActionMenu/Copy", accel.key, accel.mods);
        accel = Accel.parse(self.actions.paste);
        c.gtk_accel_map_add_entry("<Zterm>/ActionMenu/Paste", accel.key, accel.mods);
        accel = Accel.parse(self.actions.quit);
        c.gtk_accel_map_add_entry("<Zterm>/AppMenu/Quit", accel.key, accel.mods);
        accel = Accel.parse(self.tabs.new_tab);
        c.gtk_accel_map_add_entry("<Zterm>/AppMenu/NewTab", accel.key, accel.mods);
        accel = Accel.parse(self.tabs.prev_tab);
        c.gtk_accel_map_add_entry("<Zterm>/NavMenu/PrevTab", accel.key, accel.mods);
        accel = Accel.parse(self.tabs.next_tab);
        c.gtk_accel_map_add_entry("<Zterm>/NavMenu/NextTab", accel.key, accel.mods);
        accel = Accel.parse(self.tabs.tab1);
        c.gtk_accel_map_add_entry("<Zterm>/NavMenu/Tab1", accel.key, accel.mods);
        accel = Accel.parse(self.tabs.tab2);
        c.gtk_accel_map_add_entry("<Zterm>/NavMenu/Tab2", accel.key, accel.mods);
        accel = Accel.parse(self.tabs.tab3);
        c.gtk_accel_map_add_entry("<Zterm>/NavMenu/Tab3", accel.key, accel.mods);
        accel = Accel.parse(self.tabs.tab4);
        c.gtk_accel_map_add_entry("<Zterm>/NavMenu/Tab4", accel.key, accel.mods);
        accel = Accel.parse(self.tabs.tab5);
        c.gtk_accel_map_add_entry("<Zterm>/NavMenu/Tab5", accel.key, accel.mods);
        accel = Accel.parse(self.tabs.tab6);
        c.gtk_accel_map_add_entry("<Zterm>/NavMenu/Tab6", accel.key, accel.mods);
        accel = Accel.parse(self.tabs.tab7);
        c.gtk_accel_map_add_entry("<Zterm>/NavMenu/Tab7", accel.key, accel.mods);
        accel = Accel.parse(self.tabs.tab8);
        c.gtk_accel_map_add_entry("<Zterm>/NavMenu/Tab8", accel.key, accel.mods);
        accel = Accel.parse(self.tabs.tab9);
        c.gtk_accel_map_add_entry("<Zterm>/NavMenu/Tab9", accel.key, accel.mods);
        accel = Accel.parse(self.views.split_view);
        c.gtk_accel_map_add_entry("<Zterm>/AppMenu/SplitView", accel.key, accel.mods);
        accel = Accel.parse(self.views.rotate_view);
        c.gtk_accel_map_add_entry("<Zterm>/AppMenu/RotateView", accel.key, accel.mods);
        accel = Accel.parse(self.views.prev_view);
        c.gtk_accel_map_add_entry("<Zterm>/NavMenu/PrevPane", accel.key, accel.mods);
        accel = Accel.parse(self.views.next_view);
        c.gtk_accel_map_add_entry("<Zterm>/NavMenu/NextPane", accel.key, accel.mods);
    }

    pub fn save(self: Self) void {
        if (config.getConfigDir(allocator)) |dir| {
            const tree = nt.fromArbitraryType(allocator, self) catch return;
            defer tree.deinit();
            if (config.getConfigDirHandle(dir)) |h| {
                var handle = h;
                defer handle.close();
                if (handle.createFile("keys.nt", .{ .truncate = true })) |file| {
                    tree.stringify(.{}, file.writer()) catch return;
                } else |write_err| {
                    std.debug.print("Write Error: {}\n", .{write_err});
                    return;
                }
            }
        }
    }
};
