const std = @import("std");
const clap = @import("clap");
const config = @import("config.zig");
const gui = @import("gui.zig");
const VTE = @import("vte");
const c = VTE.c;
const allocator = std.heap.page_allocator;
const fmt = std.fmt;
const mem = std.mem;
const os = std.os;
const process = std.process;
const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();
const version = @import("version.zig").version;

const params = clap.parseParamsComptime(
    \\-h, --help             Display this help and exit.
    \\-e, --command    <str> Command and args to execute.
    \\-t, --title      <str> Defines the window title.
    \\-w, --directory  <str> Set the working directory.
    \\
);

pub fn main() !void {
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{ .diagnostic = &diag }) catch |err| {
        diag.report(stderr, err) catch {};
        return err;
    };
    defer res.deinit();
    if (res.args.help) {
        try stdout.print("Zterm version {s}\nCopyright 2021 by Nathan Fisher\n\n", .{version});
        usage(0);
    }

    const cmd = if (res.args.command) |e| e else os.getenvZ("SHELL") orelse "/bin/sh";
    const title = if (res.args.title) |t| t else "Zterm";
    const directory = if (res.args.directory) |d| d else os.getenv("PWD") orelse os.getenv("HOME") orelse "/";
    var buf: [os.system.HOST_NAME_MAX]u8 = undefined;
    const hostname = try os.gethostname(&buf);
    var opts = gui.Opts{
        .command = try fmt.allocPrintZ(allocator, "{s}", .{cmd}),
        .title = try fmt.allocPrintZ(allocator, "{s}", .{title}),
        .directory = try fmt.allocPrintZ(allocator, "{s}", .{directory}),
        .hostname = try fmt.allocPrintZ(allocator, "{s}", .{hostname}),
        .config_dir = if (config.getConfigDir(allocator)) |d| d else return,
    };
    defer allocator.free(opts.command);
    defer allocator.free(opts.title);
    defer allocator.free(opts.directory);
    defer allocator.free(opts.hostname);

    const app = c.gtk_application_new("org.hitchhiker-linux.zterm", c.G_APPLICATION_FLAGS_NONE) orelse @panic("null app :(");
    // This was all a failed attempt at registering the app with dbus. Leaving it\
    // in but commented out, as it's good to know how to set up GValues for future
    // refernce, since it's set up in a C macro which doesn't translate to zig
    // properly. But even though this failed to register the session it did compile
    // and hopefulle set the GValue properly
    // var value = c.GValue{.g_type = 0, .data = undefined };
    // var t = c.g_value_init(&value, c.G_TYPE_BOOLEAN);
    // c.g_value_set_boolean(&value, 1);
    // c.g_object_set_property(@ptrCast(*c.GObject, app), "register-session", t);
    defer c.g_object_unref(app);

    _ = c.g_signal_connect_data(
        app,
        "activate",
        @ptrCast(c.GCallback, &gui.activate),
        // Here we cast a pointer to "opts" to a gpointer and pass it into the
        // GCallback created above
        @ptrCast(c.gpointer, &opts),
        null,
        c.G_CONNECT_AFTER,
    );
    _ = c.g_application_register(@ptrCast(*c.GApplication, app), null, null);
    _ = c.g_application_run(@ptrCast(*c.GApplication, app), 0, null);
}

fn usage(status: u8) void {
    stderr.print("Usage: {s} ", .{"zterm"}) catch {};
    clap.usage(stderr, clap.Help, &params) catch {};
    stderr.print("\nFlags: \n", .{}) catch {};
    clap.help(stderr, clap.Help, &params, .{}) catch {};
    process.exit(status);
}
