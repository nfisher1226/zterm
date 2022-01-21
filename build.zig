const std = @import("std");
const Builder = std.build.Builder;
const fs = std.fs;
const deps = @import("deps.zig");

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zt", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkLibC();
    exe.linkSystemLibrary("gtk+-3.0");
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
    const icon_path = fs.path.join(
        b.allocator,
        &[_][]const u8{ datadir, "/icons/hicolor/scalable/apps/zterm.svg" },
    ) catch unreachable;
    // install data files
    b.installFile("data/zterm.desktop", desktop_path);
    b.installFile("data/zterm.svg", icon_path);

    // `strip` option
    const strip = b.option(bool, "strip", "Strip the installed executable") orelse false;
    const strip_cmd = b.addSystemCommand(&[_][]const u8{"strip", "-s"});
    if (strip) {
        strip_cmd.addArtifactArg(exe);
        b.getInstallStep().dependOn(&strip_cmd.step);
    }

    // `size` option
    const size = b.option(bool, "size", "Show the installed sizes") orelse false;
    if (size) {
        const exe_absolute_path = fs.path.join(
            b.allocator,
            &[_][]const u8{ b.install_prefix, "/bin/zt" },
        ) catch unreachable;
        const desktop_absolute_path = fs.path.join(
            b.allocator,
            &[_][]const u8{ b.install_prefix, "/", desktop_path},
        ) catch unreachable;
        const icon_absolute_path = fs.path.join(
            b.allocator,
            &[_][]const u8{ b.install_prefix, "/", icon_path},
        ) catch unreachable;
        const size_cmd = b.addSystemCommand(
            &[_][]const u8{
                "du",
                "-hc",
                exe_absolute_path,
                desktop_absolute_path,
                icon_absolute_path,
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

    if (archive) {
        const Format = enum { gz, bz2, xz };
        const len = std.mem.len(archive_fmt);
        const format = std.meta.stringToEnum(Format, archive_fmt[0..len]);
        const prefix_basename = fs.path.basenamePosix(b.install_prefix);
        const exe_absolute_path = fs.path.join(
            b.allocator,
            &[_][]const u8{ prefix_basename, "/bin/zt" },
        ) catch unreachable;
        const desktop_absolute_path = fs.path.join(
            b.allocator,
            &[_][]const u8{ prefix_basename, desktop_path},
        ) catch unreachable;
        const icon_absolute_path = fs.path.join(
            b.allocator,
            &[_][]const u8{ prefix_basename, icon_path},
        ) catch unreachable;
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
            const archive_name = std.mem.join(
                b.allocator,
                ".",
                &[_][]const u8{ prefix_basename, ext },
            ) catch unreachable;
            const tar_cmd = b.addSystemCommand(
                &[_][]const u8{
                    "tar",
                    "--numeric-owner",
                    "--owner=0",
                    tar_opts,
                    archive_name,
                    exe_absolute_path,
                    desktop_absolute_path,
                    icon_absolute_path,
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
