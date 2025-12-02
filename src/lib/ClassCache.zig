// The ClassCache is a simple cache for reference counting of the number of element that share the same class
const std = @import("std");
const Vapor = @import("Vapor.zig");
const Wasm = Vapor.Wasm;

pub const ClassType = enum {
    layout,
    position,
    margin_padding,
    visual,
    interactive,
    animation,
    defined,
};

pub const ClassCache = struct {
    const Self = @This();

    // The Hash is the key into the map it represent the class name
    const Hash = u32;

    const Class = struct {
        name: []const u8,
        type: ClassType,
        count: u32,
        tombstone: bool = false,
    };

    map: std.AutoHashMap(Hash, Class),
    allocator: std.mem.Allocator,
    tombstones: []Class = undefined,
    tombstone_count: u32 = 0,

    pub fn init(allocator: std.mem.Allocator) !Self {
        const tombstones: []Class = try allocator.alloc(Class, 64);
        return .{
            .map = std.AutoHashMap(Hash, Class).init(allocator),
            .allocator = allocator,
            .tombstones = tombstones,
        };
    }

    pub fn getClassNameByType(class_type: ClassType) []const u8 {
        return switch (class_type) {
            .layout => "lay",
            .position => "pos",
            .margin_padding => "mapa",
            .visual => "vis",
            .interactive => "intr",
            .animation => "anim",
            .defined => "def",
        };
    }

    pub fn get(self: *Self, hash: Hash) ?Class {
        return self.map.get(hash);
    }

    pub fn set(self: *Self, hash: Hash, class_type: ClassType) !void {
        const class_type_as_str = getClassNameByType(class_type);
        const full_class = std.fmt.allocPrint(self.allocator, "{s}_{any}", .{ class_type_as_str, hash }) catch unreachable;

        var class = self.get(hash) orelse {
            const class = Class{
                .name = full_class,
                .type = class_type,
                .count = 1,
            };
            try self.map.put(hash, class);
            return;
        };
        class.count += 1;
        try self.map.put(hash, class);
    }

    pub fn decrement(self: *Self, old_hash: Hash) !void {
        var class = self.get(old_hash) orelse {
            return error.ClassNotFound;
        };
        if (class.tombstone) return;
        class.count -= 1;
        if (class.count == 0) {
            if (self.tombstone_count == 64) return error.TombstoneOverflow;
            class.tombstone = true;
            self.tombstones[self.tombstone_count] = class;
            self.tombstone_count += 1;
        }
        try self.map.put(old_hash, class);
    }

    pub fn getTombstones(self: *Self) []Class {
        return self.tombstones[0..self.tombstone_count];
    }

    pub fn clearTombstones(self: *Self) void {
        self.tombstone_count = 0;
    }

    pub fn batchRemove(self: *Self) void {
        if (self.tombstone_count < 32) return;
        if (Vapor.isWasi) {
            Wasm.batchRemoveTombStonesWasm();
        }
    }

    pub fn getTombstone(self: *Self, index: usize) Class {
        return self.tombstones[index];
    }
};

export fn getTombstoneCount() usize {
    return Vapor.class_cache.tombstone_count;
}

export fn getTombstoneClassNamePtr(index: usize) ?[*]const u8 {
    if (index >= Vapor.class_cache.tombstone_count) return null;
    const tombstone = Vapor.class_cache.getTombstone(index);
    Vapor.println("Tombstone: {s}\n", .{tombstone.name});
    return tombstone.name.ptr;
}

export fn getTombstoneClassNameLength(index: usize) usize {
    const tombstone = Vapor.class_cache.getTombstone(index);
    return tombstone.name.len;
}

export fn clearTombstones() void {
    Vapor.class_cache.clearTombstones();
}
