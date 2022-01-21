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
    if (strip) {
        const strip_cmd = b.addSystemCommand(&[_][]const u8{"strip", "-s"});
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

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
