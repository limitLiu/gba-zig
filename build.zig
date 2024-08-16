const std = @import("std");
const emulator = "/Applications/mGBA.app/Contents/MacOS/mGBA";
const flags = .{"-lgba"};
const devkit_pro = "/opt/devkitpro";
const root = std.Build.LazyPath{ .cwd_relative = devkit_pro };

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm7tdmi },
    });

    const lib = b.addObject(.{
        .name = "gba-zig",
        .root_source_file = b.path("src/main.zig"),
        .link_libc = true,
        .target = target,
        .optimize = .ReleaseSafe,
    });
    lib.setLibCFile(b.path("libc.txt"));
    lib.addSystemIncludePath(root.path(b, "libgba/include"));

    const elf = b.addSystemCommand(&.{
        devkit_pro ++ "/devkitARM/bin/arm-none-eabi-gcc",
        "-g",
        "-mthumb",
        "-mthumb-interwork",
        "-znoexecstack",
    });
    _ = elf.addPrefixedOutputFileArg("-Wl,-Map,", "gba-zig.map");
    elf.addPrefixedFileArg("-specs=", root.path(b, "devkitARM/arm-none-eabi/lib/gba.specs"));
    elf.addFileArg(lib.getEmittedBin());
    elf.addArgs(&.{"-L" ++ devkit_pro ++ "/libgba/lib"});
    elf.addArgs(&flags);
    elf.addArg("-o");
    const elf_file = elf.addOutputFileArg("gba-zig.elf");

    const gba = b.addSystemCommand(&.{
        devkit_pro ++ "/devkitARM/bin/arm-none-eabi-objcopy",
        "-O",
        "binary",
    });
    gba.addFileArg(elf_file);
    const gba_file = gba.addOutputFileArg("gba-zig.gba");

    const fix = b.addSystemCommand(&.{devkit_pro ++ "/tools/bin/gbafix"});
    fix.addFileArg(gba_file);

    const install = b.addInstallBinFile(gba_file, "gba-zig.gba");

    b.default_step.dependOn(&install.step);
    install.step.dependOn(&fix.step);
    fix.step.dependOn(&gba.step);
    gba.step.dependOn(&elf.step);
    elf.step.dependOn(&lib.step);

    const run_step = b.step("run", "Run in mGBA");
    const mgba = b.addSystemCommand(&.{emulator});
    mgba.addFileArg(gba_file);
    run_step.dependOn(&install.step);
    run_step.dependOn(&mgba.step);
}
