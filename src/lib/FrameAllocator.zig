const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const Arena = std.heap.ArenaAllocator;
const println = @import("Fabric.zig").println;
const printlnColor = @import("Fabric.zig").printlnColor;
const Fabric = @import("Fabric.zig");
const Types = @import("types.zig");
const Wasm = @import("wasm");

// The FrameAllocator is a simple allocator that allocates memory per render cycle.
// It is used to allocate memory for the render commands and the UI tree, text, and styles, etc.
// It is also used to allocate memory for the persistent arena, which is used to store data that
// should persist across frames.

// For each render cycle, beginFrame() is called to reset the current frame arena and get ready to allocate memory, for
// the next frame. This means we can just deinit a single allocator and there is no need to recurse down the tree.

const FrameData = struct {
    arena: std.heap.ArenaAllocator,
    stats: Stats = .{},

    const Stats = struct {
        nodes_allocated: usize = 0,
        commands_allocated: usize = 0,
        bytes_used: usize = 0,
    };
};

const FrameAllocator = @This();
frames: [2]FrameData,
current_frame: usize = 0,
persistent_arena: Arena,

pub fn init(backing_allocator: std.mem.Allocator) FrameAllocator {
    return .{
        .frames = [_]FrameData{
            .{ .arena = std.heap.ArenaAllocator.init(backing_allocator) },
            .{ .arena = std.heap.ArenaAllocator.init(backing_allocator) },
        },
        .persistent_arena = std.heap.ArenaAllocator.init(backing_allocator),
    };
}

pub fn deinit(self: *FrameAllocator) void {
    self.frames[0].arena.deinit();
    self.frames[1].arena.deinit();
    self.persistent_arena.deinit();
}

pub fn getFrameAllocator(self: *FrameAllocator) std.mem.Allocator {
    return self.frames[self.current_frame].arena.allocator();
}

pub fn incrementNodeCount(self: *FrameAllocator) void {
    self.frames[self.current_frame].stats.nodes_allocated += 1;
}

pub fn incrementCommandCount(self: *FrameAllocator) void {
    self.frames[self.current_frame].stats.commands_allocated += 1;
}

pub fn addBytesUsed(self: *FrameAllocator, bytes: usize) void {
    self.frames[self.current_frame].stats.bytes_used += bytes;
}

/// Get allocator for data that should persist across frames
pub fn persistentAllocator(self: *FrameAllocator) std.mem.Allocator {
    return self.persistent_arena.allocator();
}

/// Start a new frame - swaps buffers and clears the old one
pub fn beginFrame(self: *FrameAllocator) void {
    if (Fabric.build_options.enable_debug and Fabric.build_options.debug_level == .all) {
        printPrevStats(self);
        println("-----------New Frame-----------", .{});
    }
    // Move to next frame
    const next_frame = (self.current_frame + 1) % 2;

    // Clear the frame we're about to use
    _ = self.frames[next_frame].arena.reset(.retain_capacity);
    self.frames[next_frame].stats = .{};

    self.current_frame = next_frame;
}

/// Get stats for current frame
pub fn getStats(self: *FrameAllocator) FrameData.Stats {
    return self.frames[self.current_frame].stats;
}

fn convertColorToString(color: Types.Color) []const u8 {
    return switch (color) {
        .Literal => |rgba| rgbaToString(rgba),
        else => "",
    };
}

fn rgbaToString(rgba: Types.Rgba) []const u8 {
    const alpha = @as(f32, @floatFromInt(rgba.a)) / 255.0;
    return std.fmt.allocPrint(Fabric.allocator_global, "rgba({d},{d},{d},{d})", .{
        rgba.r,
        rgba.g,
        rgba.b,
        alpha,
    }) catch return "";
}

pub fn printPrevStats(self: *FrameAllocator) void {
    var buffer: [4096]u8 = undefined;
    var writer = std.io.Writer.fixed(&buffer);

    const stats = self.getStats();

    const color_buf = std.fmt.allocPrint(Fabric.allocator_global, "color: {s};", .{convertColorToString(.hex("#4800FF"))}) catch return;
    writer.print("%c", .{}) catch return;
    writer.print("╔══════════════════════════════╗\n", .{}) catch return;
    writer.print("║       Prev Frame Stats       ║\n", .{}) catch return;
    writer.print("╠══════════════════════════════╣\n", .{}) catch return;
    writer.print("║ Nodes allocated    : {d: >7} ║\n", .{stats.nodes_allocated}) catch return;
    writer.print("║ Commands allocated : {d: >7} ║\n", .{stats.commands_allocated}) catch return;
    writer.print("║ Bytes used         : {d: >7} ║\n", .{stats.bytes_used}) catch return;
    writer.print("╚══════════════════════════════╝\n", .{}) catch return;
    writer.print("%c", .{}) catch return;
    const style_2 = "";
    _ = Wasm.consoleLogColoredWasm(buffer[0..writer.end].ptr, buffer[0..writer.end].len, color_buf[0..].ptr, color_buf.len, style_2[0..].ptr, style_2.len);
}

pub fn printStats(self: *FrameAllocator) void {
    var buffer: [4096]u8 = undefined;
    var writer = std.io.Writer.fixed(&buffer);

    const stats = self.getStats();

    const color_buf = std.fmt.allocPrint(Fabric.allocator_global, "color: {s};", .{convertColorToString(.hex("#4800FF"))}) catch return;
    writer.print("%c", .{}) catch return;
    writer.print("╔══════════════════════════════╗\n", .{}) catch return;
    writer.print("║    Frame Allocator Stats     ║\n", .{}) catch return;
    writer.print("╠══════════════════════════════╣\n", .{}) catch return;
    writer.print("║ Max Node count     : {d: >7} ║\n", .{Fabric.page_node_count}) catch return;
    writer.print("║ Nodes allocated    : {d: >7} ║\n", .{stats.nodes_allocated}) catch return;
    writer.print("║ Commands allocated : {d: >7} ║\n", .{stats.commands_allocated}) catch return;
    writer.print("║ Bytes used         : {d: >7} ║\n", .{stats.bytes_used}) catch return;
    writer.print("╚══════════════════════════════╝\n", .{}) catch return;
    writer.print("%c", .{}) catch return;
    const style_2 = "";
    _ = Wasm.consoleLogColoredWasm(buffer[0..writer.end].ptr, buffer[0..writer.end].len, color_buf[0..].ptr, color_buf.len, style_2[0..].ptr, style_2.len);
}
