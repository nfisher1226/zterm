const std = @import("std");
const Builder = std.build.Builder;
const fs = std.fs;
const deps = @import("deps.zig");

var icons: ?PngIcons = null;

const PngIcons = struct {
    xl: []const u8,
    lg: []const u8,
    md: []const u8,
    sm: []const u8,

    const Self = @This();

    fn paths(allocator: std.mem.Allocator, prefix_basename: []const u8) Self {
        const path128 = fs.path.join(
            allocator,
            &[_][]const u8{ prefix_basename, "/share/icons/hicolor/128x128/apps/zterm.png" },
        ) catch unreachable;
        const path64 = fs.path.join(
            allocator,
            &[_][]const u8{ prefix_basename, "/share/icons/hicolor/64x64/apps/zterm.png" },
        ) catch unreachable;
        const path48 = fs.path.join(
            allocator,
            &[_][]const u8{ prefix_basename, "/share/icons/hicolor/48x48/apps/zterm.png" },
        ) catch unreachable;
        const path32 = fs.path.join(
            allocator,
            &[_][]const u8{ prefix_basename, "/share/icons/hicolor/32x32/apps/zterm.png" },
        ) catch unreachable;
        return Self{
            .xl = path128,
            .lg = path64,
            .md = path48,
            .sm = path32,
        };
    }
};

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zt", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkLibC();
    exe.linkSystemLibrary("vte-2.91");
    exe.install();

    // support both gyro and zigmod
    if (@hasDecl(deps, "addAllTo")) {
        deps.addAllTo(exe);
    } else {
        deps.pkgs.addAllTo(exe);
    }

    // set the `datadir`
    const datadir = b.option(
        []const u8,
        "datadir",
        "Path to install data files (relative tp prefix)"
    ) orelse "share";

    // get some paths
    const desktop_path = fs.path.join(
        b.allocator,
        &[_][]const u8{ datadir, "/applications/zterm.desktop" },
    ) catch unreachable;
    defer b.allocator.free(desktop_path);
    const icon_path = fs.path.join(
        b.allocator,
        &[_][]const u8{ datadir, "/icons/hicolor/scalable/apps/zterm.svg" },
    ) catch unreachable;
    defer b.allocator.free(icon_path);
    // install data files
    b.installFile("data/zterm.desktop", desktop_path);
    b.installFile("data/zterm.svg", icon_path);

    // `png-icons` option
    const png = b.option(
        bool,
        "png-icons",
        "Export png icons (requires rsvg-convert)"
    ) orelse false;
    if (png) {
        const sizes = .{"128", "64", "48", "32"};
        inline for (sizes) |s| {
            const size = std.fmt.allocPrint(b.allocator, "{s}x{s}", .{s, s}) catch unreachable;
            defer b.allocator.free(size);
            const icon = fs.path.join(
                b.allocator,
                &[_][]const u8{
                    b.install_prefix,
                    datadir,
                    "/icons/hicolor/",
                    size,
                    "/apps/zterm.png"
                },
            ) catch unreachable;
            defer b.allocator.free(icon);
            if (fs.path.dirname(icon)) |d| {
                std.fs.cwd().makePath(d) catch unreachable;
                const exp_cmd = b.addSystemCommand(&[_][]const u8{
                    "rsvg-convert", "data/zterm.svg", "-w", s, "-h", s, "-o", icon,
                });
                b.getInstallStep().dependOn(&exp_cmd.step);
            }
        }
        const prefix_basename = fs.path.relative(
            b.allocator,
            b.build_root,
            b.install_prefix
        ) catch unreachable;
        icons = PngIcons.paths(b.allocator, prefix_basename);
    }
    defer {
        if (icons) |i| {
            b.allocator.free(i.xl);
            b.allocator.free(i.lg);
            b.allocator.free(i.md);
            b.allocator.free(i.sm);
        }
    }

    // `strip` option
    const strip = b.option(
        bool,
        "strip",
        "Strip the installed executable"
    ) orelse false;
    const strip_exe = b.option(
        []const u8,
        "strip_cmd",
        "The strip binary to use"
    ) orelse "strip";
    const strip_cmd = b.addSystemCommand(&[_][]const u8{strip_exe, "-s"});
    if (strip) {
        strip_cmd.addArtifactArg(exe);
        b.getInstallStep().dependOn(&strip_cmd.step);
    }

    // `size` option
    const size = b.option(
        bool,
        "size",
        "Show the installed sizes"
    ) orelse false;
    if (size) {
        const exe_absolute_path = fs.path.join(
            b.allocator,
            &[_][]const u8{ b.install_prefix, "/bin/zt" },
        ) catch unreachable;
        defer b.allocator.free(exe_absolute_path);
        const desktop_absolute_path = fs.path.join(
            b.allocator,
            &[_][]const u8{ b.install_prefix, "/", desktop_path},
        ) catch unreachable;
        defer b.allocator.free(desktop_absolute_path);
        const icon_absolute_path = fs.path.join(
            b.allocator,
            &[_][]const u8{ b.install_prefix, "/", icon_path},
        ) catch unreachable;
        defer b.allocator.free(icon_absolute_path);
        const size_cmd = b.addSystemCommand(
            &[_][]const u8{
                "du",
                "-hc",
                exe_absolute_path,
                desktop_absolute_path,
                icon_absolute_path,
                if (icons) |i| i.xl else "",
                if (icons) |i| i.lg else "",
                if (icons) |i| i.md else "",
                if (icons) |i| i.sm else "",
            }
        );
        b.getInstallStep().dependOn(&size_cmd.step);
    }

    const archive = b.option(
        bool,
        "archive",
        "Create an archive of the installed files",
    ) orelse false;

    const archive_fmt = b.option(
        []const u8,
        "archive_fmt",
        "The compression format to use for the package archive. One of gz, bz2 or xz",
    ) orelse "gz";

    const tar_exe = b.option(
        []const u8,
        "tar_cmd",
        "The command to run Gnu tar",
    ) orelse "tar";

    if (archive) {
        const Format = enum { gz, bz2, xz };
        const len = std.mem.len(archive_fmt);
        const format = std.meta.stringToEnum(Format, archive_fmt[0..len]);
        const prefix_basename = fs.path.relative(
            b.allocator,
            b.build_root,
            b.install_prefix
        ) catch unreachable;
        defer b.allocator.free(prefix_basename);
        const exe_absolute_path = fs.path.join(
            b.allocator,
            &[_][]const u8{ prefix_basename, "/bin/zt" },
        ) catch unreachable;
        defer b.allocator.free(exe_absolute_path);
        const desktop_absolute_path = fs.path.join(
            b.allocator,
            &[_][]const u8{ prefix_basename, desktop_path},
        ) catch unreachable;
        defer b.allocator.free(desktop_absolute_path);
        const icon_absolute_path = fs.path.join(
            b.allocator,
            &[_][]const u8{ prefix_basename, icon_path},
        ) catch unreachable;
        defer b.allocator.free(icon_absolute_path);
        if (format) |f| {
            const tar_opts: []const u8 = switch (f) {
                .gz => "-czf",
                .bz2 => "-cjf",
                .xz => "-cJf",
            };
            const ext = switch(f) {
                .gz => "tar.gz",
                .bz2 => "tar.bz2",
                .xz => "tar.xz",
            };
            const basename = if (std.mem.containsAtLeast(
                u8, prefix_basename, 1, "/")) "zterm" else prefix_basename;
            const archive_name = std.mem.join(
                b.allocator,
                ".",
                &[_][]const u8{ basename, ext },
            ) catch unreachable;
            defer b.allocator.free(archive_name);
            const tar_cmd = b.addSystemCommand(
                &[_][]const u8{
                    tar_exe,
                    "--numeric-owner",
                    "--owner=0",
                    tar_opts,
                    archive_name,
                    exe_absolute_path,
                    desktop_absolute_path,
                    icon_absolute_path,
                    if (icons) |i| i.xl else "",
                    if (icons) |i| i.lg  else "",
                    if (icons) |i| i.md else "",
                    if (icons) |i| i.sm else "",
                }
            );
            if (strip) {
                tar_cmd.step.dependOn(&strip_cmd.step);
            }
            b.getInstallStep().dependOn(&tar_cmd.step);
        }
    }

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
