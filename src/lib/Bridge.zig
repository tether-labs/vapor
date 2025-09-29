const std = @import("std");
const isWasi = true;
const Fabric = @import("Fabric.zig");
const UIContext = @import("UITree.zig");
const CommandsTree = UIContext.CommandsTree;
const Types = @import("types.zig");
const EventType = Types.EventType;
const RenderCommand = Types.RenderCommand;
const UINode = UIContext.UINode;
const Event = @import("Event.zig");
const StyleCompiler = @import("convertStyleCustomWriter.zig");
const Wasm = @import("wasm");

export fn eventCallback(id: u32) void {
    const func = Fabric.events_callbacks.get(id).?;
    var event = Event{
        .id = id,
    };
    @call(.auto, func, .{&event});
}

export fn eventInstCallback(id: u32) void {
    const evt_node = Fabric.events_inst_callbacks.get(id).?;
    var event = Event{
        .id = id,
    };
    @call(.auto, evt_node.data.evt_cb, .{ &evt_node.data, &event });
}

export fn hookInstCallback(id: u32) void {
    const hook_node = Fabric.hooks_inst_callbacks.get(id).?;
    @call(.auto, hook_node.data.hook_cb, .{&hook_node.data});
}

pub export fn getRenderTreePtr() ?*UIContext.CommandsTree {
    const tree_op = Fabric.current_ctx.ui_tree;

    if (tree_op != null) {
        // iterateTreeChildren(Fabric.current_ctx.ui_tree.?);
        return Fabric.current_ctx.ui_tree.?;
    }
    return null;
}

pub export fn getRenderCommandPtr(tree: *CommandsTree) [*]u8 {
    if (std.mem.eql(u8, tree.node.id, "global-style")) {
        Fabric.println("getRenderCommandPtr {any}\n", .{tree.node.node_ptr.dirty});
    }
    return @ptrCast(tree.node);
}

export fn getTreeNodeChildrenCount(tree: *CommandsTree) usize {
    return tree.children.items.len;
}

export fn getUiNodeChildrenCount(tree: *CommandsTree) usize {
    return tree.node.node_ptr.children.items.len;
}

export fn getTreeNodeChild(tree: *CommandsTree, index: usize) *CommandsTree {
    const child = tree.children.items[index];
    return child;
}

export fn getCtxNodeChild(tree: *CommandsTree, index: usize) ?*CommandsTree {
    const ui_node = tree.node.node_ptr.children.items[index];
    for (tree.children.items, 0..) |item, i| {
        if (std.mem.eql(u8, ui_node.uuid, item.node.id)) {
            return tree.children.items[i];
        }
    }
    return null;
}

export fn getTreeNodeChildCommand(tree: *CommandsTree) *RenderCommand {
    return tree.node;
}

export fn setDirtyToFalse(node: *UINode) void {
    node.dirty = false;
}

export fn getDirtyValue(node: *UINode) bool {
    return node.dirty;
}

export fn getRemovedNodeCount() usize {
    return Fabric.removed_nodes.items.len;
}

export fn clearRemovedNodesretainingCapacity() void {
    Fabric.removed_nodes.clearRetainingCapacity();
}
// The first node needs to be marked as false always
export fn markCurrentTreeDirty() void {
    Fabric.markChildrenDirty(Fabric.current_ctx.root.?);
}

export fn markUINodeTreeDirty(node: *UINode) void {
    Fabric.markChildrenDirty(node);
}

// The first node needs to be marked as false always
export fn markCurrentTreeNotDirty() void {
    Fabric.markChildrenNotDirty(Fabric.current_ctx.root.?);
}

export fn getRemovedNode(index: usize) [*]const u8 {
    return Fabric.removed_nodes.items[index].uuid.ptr;
}

export fn getRemovedNodeIndex(index: usize) usize {
    return Fabric.removed_nodes.items[index].index;
}

export fn getRemovedNodeLength(index: usize) usize {
    return Fabric.removed_nodes.items[index].uuid.len;
}

/// Calling route renderCycle will mark eveything as dirty
export fn callRouteRenderCycle(ptr: [*:0]u8) void {
    Fabric.println("Calling route render cycle\n", .{});
    Fabric.renderCycle(ptr);
    Fabric.println("Ending route render cycle\n", .{});
    Fabric.markChildrenDirty(Fabric.current_ctx.root.?);
    return;
}
export fn setRouteRenderTree(ptr: [*:0]u8) void {
    Fabric.renderCycle(ptr);
    return;
}

export fn allocUint8(length: u32) [*]const u8 {
    const slice = Fabric.allocator_global.alloc(u8, length) catch
        @panic("failed to allocate memory");
    return slice.ptr;
}

pub export fn allocateLayoutInfo() *u8 {
    const info_ptr: *u8 = @ptrCast(&Fabric.layout_info);
    return info_ptr;
}
// Export the size of a single RenderCommand for proper memory reading
export fn getRenderCommandSize() usize {
    return @sizeOf(RenderCommand);
}

export fn grainRerender() bool {
    return Fabric.grain_rerender;
}

export fn resetGrainRerender() void {
    Fabric.grain_rerender = false;
}

export fn shouldRerender() bool {
    return Fabric.global_rerender;
}

export fn rerenderEverything() bool {
    return Fabric.rerender_everything;
}

export fn hasDirty() bool {
    return Fabric.has_dirty;
}

export fn resetRerender() void {
    Fabric.global_rerender = false;
    Fabric.rerender_everything = false;
    Fabric.has_dirty = false;
}

export fn setRerenderTrue() void {
    Fabric.cycle();
}
// Wrapper functions with dummy implementations for non-WASM targets

export fn callback(callbackId: u32) void {
    const continuation = Fabric.continuations[callbackId];
    if (continuation) |cb| {
        @call(.auto, cb, .{});
    }
}

export fn allocate(size: usize) ?[*]f32 {
    const buf = Fabric.allocator_global.alloc(f32, size) catch |err| {
        Fabric.println("{any}\n", .{err});
        return null;
    };
    return buf.ptr;
}
//
const writer_t = *std.io.FixedBufferStream([]u8).Writer;
// Global buffer to store the CSS string for returning to JavaScript
var common_style_buffer: [4096]u8 = undefined;
var common_style: []const u8 = "";
pub export fn getBaseStyles() ?[*]const u8 {
    var fbs = std.io.fixedBufferStream(&common_style_buffer);
    var writer = fbs.writer();
    const base_styles = UIContext.base_styles[0..UIContext.base_style_count];
    for (base_styles) |style| {
        Fabric.generateStyle(null, &style);
        writer.writeByte('.') catch return null;
        writer.writeAll(style.style_id.?) catch return null;
        writer.writeAll(" {\n") catch return null;
        writer.writeAll(StyleCompiler.style_style) catch return null;
        writer.writeAll("}\n") catch return null;
    }

    const len: usize = @intCast(fbs.getPos() catch 0);
    common_style_buffer[len] = 0;
    common_style = common_style_buffer[0..len];
    return common_style.ptr;
}

pub export fn getBaseStylesLen() usize {
    return common_style.len;
}

pub export fn pendingClassesToAdd() void {
    if (isWasi) {
        for (Fabric.classes_to_add.items) |clta| {
            Wasm.addClass(clta.element_id.ptr, clta.element_id.len, clta.style_id.ptr, clta.style_id.len);
        }
        Fabric.classes_to_add.clearAndFree();
    }
}
pub export fn pendingClassesToRemove() void {
    if (isWasi) {
        for (Fabric.classes_to_remove.items) |cltr| {
            Wasm.removeClass(cltr.element_id.ptr, cltr.element_id.len, cltr.style_id.ptr, cltr.style_id.len);
        }
        Fabric.classes_to_remove.clearAndFree();
    }
}

export fn cleanUp() void {
    Fabric.clean_up_ctx.deinit();
    Fabric.allocator_global.destroy(Fabric.clean_up_ctx);
    Fabric.clean_up_ctx = undefined;
}

export fn timeOutCtxCallback(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Fabric.allocator_global.free(id);
    const node = Fabric.callback_registry.get(id) orelse return;
    @call(.auto, node.data.runFn, .{&node.data});
}

export fn timeoutCtxCallBackId(id: usize) void {
    const node = Fabric.time_out_ctx_registry.get(id) orelse return;
    defer _ = Fabric.time_out_ctx_registry.remove(id);
    @call(.auto, node.data.runFn, .{&node.data});
}

// This function gets called from JavaScript when a timeout completes
export fn resumeExecution(callbackId: u32) void {
    const continuation = Fabric.continuations[callbackId];
    if (continuation) |func| {
        // Clear the slot
        Fabric.continuations[callbackId] = null;
        // Call the continuation function
        func();
    }
}
