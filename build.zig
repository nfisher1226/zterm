const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("zterm", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.linkLibC();
    exe.linkSystemLibrary("gtk4");
    exe.install();

    exe.addPackage(.{
        .name = "zig-clap",
        .path = "./lib/zig-clap/clap.zig",
    });

    exe.addPackage(.{
        .name = "zig-gtk",
        .path = "./lib/zig-gtk/gtk.zig",
    });

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
