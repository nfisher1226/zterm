const std = @import("std");
const clap = @import("clap");
const gui = @import("gui.zig");
usingnamespace @import("vte");
const allocator = std.heap.page_allocator;
const fmt = std.fmt;
const mem = std.mem;
const os = std.os;
const process = std.process;
const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();

const params = [_]clap.Param(clap.Help){
    clap.parseParam("-h, --help                     Display this help and exit.") catch unreachable,
    clap.parseParam("-e, --command <COMMAND>        Command and args to execute.") catch unreachable,
    clap.parseParam("-t, --title <TITLE>            Defines the window title.") catch unreachable,
    clap.parseParam("-w, --working-directory <DIR>  Set the terminal's working directory.") catch unreachable,
};

pub fn main() !void {
    var diag = clap.Diagnostic{};
    var args = clap.parse(clap.Help, &params, .{ .diagnostic = &diag }) catch |err| {
        diag.report(stderr, err) catch {};
        return err;
    };
    defer args.deinit();
    if (args.flag("--help")) {
        usage(0);
    }

    const cmd = if (args.option("--command")) |e| e else os.getenvZ("SHELL") orelse "/bin/sh";
    const title = if (args.option("--title")) |t| t else "Zterm";
    const directory = if (args.option("--working-directory")) |d| d else os.getenv("PWD") orelse os.getenv("HOME") orelse "/";
    var buf: [64]u8 = undefined;
    const hostname = try os.gethostname(&buf);
    var opts = gui.Opts{
        .command = try fmt.allocPrintZ(allocator, "{s}", .{cmd}),
        .title = try fmt.allocPrintZ(allocator, "{s}", .{title}),
        .directory = try fmt.allocPrintZ(allocator, "{s}", .{directory}),
        .hostname = try fmt.allocPrintZ(allocator, "{s}", .{hostname}),
    };
    defer allocator.free(opts.command);
    defer allocator.free(opts.title);
    defer allocator.free(opts.directory);
    defer allocator.free(opts.hostname);

    const app = c.gtk_application_new("org.hitchhiker-linux.zterm", c.G_APPLICATION_FLAGS_NONE) orelse @panic("null app :(");
    defer c.g_object_unref(app);

    _ = c.g_signal_connect_data(
        app,
        "activate",
        @ptrCast(c.GCallback, gui.activate),
        // Here we cast a pointer to "opts" to a gpointer and pass it into the
        // GCallback created above
        @ptrCast(c.gpointer, &opts),
        null,
        c.G_CONNECT_AFTER,
    );

    _ = c.g_application_run(@ptrCast(*c.GApplication, app), 0, null);
}

fn usage(status: u8) void {
    stderr.print("Usage: {s} ", .{"zterm"}) catch {};
    clap.usage(stderr, &params) catch {};
    stderr.print("\nFlags: \n", .{}) catch {};
    clap.help(stderr, &params) catch {};
    process.exit(status);
}
