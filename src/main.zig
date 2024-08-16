const c = @import("gba/c.zig");
const system = @import("gba/system.zig");

export fn main(_: c_int, _: [*]const [*:0]const u8) noreturn {
    c.irqInit();
    c.irqEnable(c.IRQ_VBLANK);
    c.consoleDemoInit();

    _ = c.printf("Hello, Zig");
    while (true) {
        system.vblank_intr_wait();
    }
}
