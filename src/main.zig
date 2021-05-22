const std = @import("std");
const clap = @import("zig-clap");
const gtk = @import("zig-gtk");
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

const Opts = struct {
    command: [*c]const u8,
    title: [*c]const u8,
    directory: [*c]const u8,
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
    var opts = Opts {
        .command = cmd,
        .title = title,
        .directory = directory,
    };

    const app = c.gtk_application_new("org.hitchhiker-linux.zterm", .G_APPLICATION_FLAGS_NONE) orelse @panic("null app :(");
    defer c.g_object_unref(app);

    _ = c.g_signal_connect_data(
        app,
        "activate",
        @ptrCast(c.GCallback, struct {
            fn f(a: *c.GtkApplication, data: c.gpointer) void {
                // Cast the gpointer to a normal pointer and dereference it, giving us
                // our "opts" struct initialized earlier.
                const options = @ptrCast(*Opts, @alignCast(8, data)).*;
                const window = c.gtk_application_window_new(a);
                const window_ptr = @ptrCast(*c.GtkWindow, window);
                c.gtk_window_set_title(window_ptr, options.title);

                const notebook = c.gtk_notebook_new();
                const notebook_ptr = @ptrCast(*c.GtkNotebook, notebook);

                const command = @ptrCast([*c][*c]c.gchar, &([2][*c]c.gchar{
                    c.g_strdup(options.command),
                    null,
                }));

                const term = new_tab(notebook_ptr, command);

                _ = gtk.g_signal_connect(
                    window,
                    "delete-event",
                    @ptrCast(c.GCallback, struct {
                    fn q() void {
                        c.gtk_main_quit();
                    }
                }.q),
                null,
                );

                c.gtk_container_add(@ptrCast(*c.GtkContainer, window), notebook);

                c.gtk_widget_show_all(window);
                c.gtk_widget_grab_focus(@ptrCast(*c.GtkWidget, term));
            }
        }.f),
        // Here we cast a pointer to "opts" to a gpointer and pass it into the
        // GCallback created above
        @ptrCast(c.gpointer, &opts),
        null,
        @intToEnum(c.GConnectFlags, 0),
    );

    _ = c.g_application_run(@ptrCast(*c.GApplication, app), 0, null);
}

fn new_tab(notebook: *c.GtkNotebook, command: [*c][*c]c.gchar) *c.GtkWidget {
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
        @ptrCast(c.GCallback, struct {
        fn e(t: *c.VteTerminal) void {
            c.gtk_widget_destroy(@ptrCast(*c.GtkWidget, t));
        }}.e),
        null,
    );

    const box = c.gtk_box_new(@intToEnum(c.GtkOrientation, 0), 10);
    const box_ptr = @ptrCast(*c.GtkBox, box);
    const label = c.gtk_label_new("Zterm");
    const closebutton = c.gtk_button_new_from_icon_name("window-close", @intToEnum(c.GtkIconSize, c.GTK_ICON_SIZE_MENU));
    c.gtk_button_set_relief(@ptrCast(*c.GtkButton, closebutton), @intToEnum(c.GtkReliefStyle, c.GTK_RELIEF_NONE));
    c.gtk_box_pack_start(box_ptr, label, 0, 1, 1);
    c.gtk_box_pack_start(box_ptr, closebutton, 0, 1, 1);
    c.gtk_widget_show_all(box);

    _ = gtk.g_signal_connect(
        closebutton,
        "clicked",
        @ptrCast(c.GCallback, struct {
        fn c(but: *c.GtkButton, terminal: c.gpointer) void {
            c.gtk_widget_destroy(@ptrCast(*c.GtkWidget, @alignCast(8, terminal)));
        }}.c),
        @ptrCast(c.gpointer, term),
    );


    c.gtk_widget_show(@ptrCast(*c.GtkWidget, term));
    _ = c.gtk_notebook_append_page(notebook, term, 0);
    c.gtk_notebook_set_tab_label(notebook, @ptrCast(*c.GtkWidget, term), @ptrCast(*c.GtkWidget, box));
    return @ptrCast(*c.GtkWidget, term);
}

fn usage(status: u8) void {
    stderr.print("Usage: {s} ", .{"zterm"}) catch unreachable;
    clap.usage(stderr, &params) catch unreachable;
    stderr.print("\nFlags: \n", .{}) catch unreachable;
    clap.help(stderr, &params) catch unreachable;
    process.exit(status);
}
