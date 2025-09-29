const std = @import("std");
const Fabric = @import("Fabric.zig");
const Wasm = @import("wasm");
const isWasi = Fabric.isWasi;

pub const Event = @This();
id: u32,
pub fn element_id(evt: *Event) []const u8 {
    const key_str: []const u8 = "target";
    const resp = getEventData(evt.id, key_str.ptr, key_str.len);
    return std.mem.span(resp);
}

pub fn key(evt: *Event) []const u8 {
    const key_str: []const u8 = "key";
    const resp = getEventData(evt.id, key_str.ptr, key_str.len);
    return std.mem.span(resp);
}
pub fn metaKey(evt: *Event) bool {
    const key_str: []const u8 = "metaKey";
    const resp = getEventData(evt.id, key_str.ptr, key_str.len);
    switch (resp[0]) {
        't' => return true,
        'f' => return false,
        else => return false,
    }
}
pub fn text(evt: *Event) []const u8 {
    const resp = getEventDataInput(evt.id);
    return std.mem.span(resp);
}
pub fn preventDefault(evt: *Event) void {
    Wasm.eventPreventDefault(evt.id);
}

pub fn clientX(evt: *Event) f32 {
    const key_str: []const u8 = "clientX";
    return getEventDataNumber(evt.id, key_str.ptr, key_str.len);
}

pub fn clientY(evt: *Event) f32 {
    const key_str: []const u8 = "clientY";
    return getEventDataNumber(evt.id, key_str.ptr, key_str.len);
}

pub fn offsetX(evt: *Event) f32 {
    const key_str: []const u8 = "offsetX";
    return getEventDataNumber(evt.id, key_str.ptr, key_str.len);
}

pub fn offsetY(evt: *Event) f32 {
    const key_str: []const u8 = "offsetY";
    return getEventDataNumber(evt.id, key_str.ptr, key_str.len);
}

pub fn movementX(evt: *Event) f32 {
    const key_str: []const u8 = "movementX";
    return getEventDataNumber(evt.id, key_str.ptr, key_str.len);
}

pub fn movementY(evt: *Event) f32 {
    const key_str: []const u8 = "movementY";
    return getEventDataNumber(evt.id, key_str.ptr, key_str.len);
}

// Static buffers for the dummy returns
var dummy_string_buffer: [256:0]u8 = undefined;
pub fn getEventData(id: u32, ptr: [*]const u8, len: u32) [*:0]u8 {
    if (isWasi) {
        return Wasm.getEventDataWasm(id, ptr, len);
    } else {
        // Dummy implementation - return empty string
        @memset(dummy_string_buffer[0..dummy_string_buffer.len], 0);
        const dummy_value = "dummy_event_data";
        @memcpy(dummy_string_buffer[0..dummy_value.len], dummy_value);
        return &dummy_string_buffer;
    }
}

pub fn getEventDataInput(id: u32) [*:0]u8 {
    if (isWasi) {
        return Wasm.getEventDataInputWasm(id);
    } else {
        // Dummy implementation - return empty string
        @memset(dummy_string_buffer[0..dummy_string_buffer.len], 0);
        const dummy_value = "dummy_input_value";
        @memcpy(dummy_string_buffer[0..dummy_value.len], dummy_value);
        return &dummy_string_buffer;
    }
}

pub fn getEventDataNumber(id: u32, ptr: [*]const u8, len: u32) f32 {
    if (isWasi) {
        return Wasm.getEventDataNumberWasm(id, ptr, len);
    } else {
        // Dummy implementation - return 0.0
        return 0.0;
    }
}


