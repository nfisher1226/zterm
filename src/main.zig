const std = @import("std");
const clap = @import("zig-clap");
const cb = @import("callbacks.zig");
const data = @import("data.zig");
const gtk = @import("gtk.zig");
const allocator = std.heap.page_allocator;
const c = gtk.c;
const fmt = std.fmt;
const mem = std.mem;
const os = std.os;
const process = std.process;
const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();

const params = comptime [_]clap.Param(clap.Help){
    clap.parseParam("-h, --help                     Display this help and exit.") catch unreachable,
    clap.parseParam("-e, --command <COMMAND>        Command and args to execute.") catch unreachable,
    clap.parseParam("-t, --title <TITLE>            Defines the window title.") catch unreachable,
    clap.parseParam("-w, --working-directory <DIR>  Set the terminal's working directory.") catch unreachable,
};

pub fn main() !void {
    var diag: clap.Diagnostic = undefined;
    var args = clap.parse(clap.Help, &params, allocator, &diag) catch |err| {
        diag.report(stderr, err) catch {};
        return err;
    };
    defer args.deinit();
    if (args.flag("--help")) {
        usage(0);
    }

    const cmd: [*c]const u8 = if (args.option("--command")) |e| eblk: {
        const res = try mem.Allocator.dupeZ(allocator, u8, e);
        break :eblk @ptrCast([*c]const u8, res);
    } else @ptrCast([*c]const u8, os.getenvZ("SHELL") orelse "/bin/sh");
    const title: [*c]const u8 = if (args.option("--title")) |t| tblk: {
        const res = try mem.Allocator.dupeZ(allocator, u8, t);
        break :tblk @ptrCast([*c]const u8, res);
    } else @ptrCast([*c]const u8, "Zterm");
    const directory: [*c]const u8 = if (args.option("--working-directory")) |d| dblk: {
        const res = try mem.Allocator.dupeZ(allocator, u8, d);
        break :dblk @ptrCast([*c]const u8, res);
    } else @ptrCast([*c]const u8, os.getenvZ("PWD") orelse os.getenvZ("HOME") orelse "/");
    var opts = data.Opts {
        .command = cmd,
        .title = title,
        .directory = directory,
    };

    const app = c.gtk_application_new("org.hitchhiker-linux.zterm", .G_APPLICATION_FLAGS_NONE) orelse @panic("null app :(");
    defer c.g_object_unref(app);

    _ = c.g_signal_connect_data(
        app,
        "activate",
        @ptrCast(c.GCallback, cb.activate),
        // Here we cast a pointer to "opts" to a gpointer and pass it into the
        // GCallback created above
        @ptrCast(c.gpointer, &opts),
        null,
        @intToEnum(c.GConnectFlags, 0),
    );

    _ = c.g_application_run(@ptrCast(*c.GApplication, app), 0, null);
}

fn usage(status: u8) void {
    stderr.print("Usage: {s} ", .{"zterm"}) catch unreachable;
    clap.usage(stderr, &params) catch unreachable;
    stderr.print("\nFlags: \n", .{}) catch unreachable;
    clap.help(stderr, &params) catch unreachable;
    process.exit(status);
}
