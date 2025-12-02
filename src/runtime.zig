const std = @import("std");
const FrameAllocator = @import("lib/FrameAllocator.zig");

export fn vapor_hash_bytes(ptr: [*]const u8, len: usize) u32 {
    return std.hash.XxHash32.hash(0, ptr[0..len]);
}

export fn frame_arena_init(frame_arena: *FrameAllocator, backing_allocator: *std.mem.Allocator) void {
    frame_arena.* = FrameAllocator.init(backing_allocator);
}

