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

    pub fn save(self: Keys) void {
        if (config.getConfigDir(allocator)) |dir| {
            const tree = nt.fromArbitraryType(allocator, self) catch return;
            defer tree.deinit();
            if (config.getConfigDirHandle(dir)) |h| {
                var handle = h;
                defer handle.close();
                if (handle.createFile("keys.nt", .{ .truncate = true })) |file| {
                    tree.stringify(.{}, file.writer()) catch return;
                } else |write_err| {
                    std.debug.print("Write Error: {s}\n", .{write_err});
                    return;
                }
            }
        }
    }
};
