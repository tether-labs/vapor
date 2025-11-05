const std = @import("std");
const Vapor = @import("Vapor.zig");
const isWasi = Vapor.isWasi;
const UIContext = @import("UITree.zig");
const CommandsTree = UIContext.CommandsTree;
const Types = @import("types.zig");
const EventType = Types.EventType;
const RenderCommand = Types.RenderCommand;
const UINode = UIContext.UINode;
const Event = @import("Event.zig");
const StyleCompiler = @import("convertStyleCustomWriter.zig");
const Wasm = @import("wasm");
const Writer = @import("Writer.zig");
const utils = @import("utils.zig");
const hashKey = utils.hashKey;
const Kit = @import("kit/Kit.zig");

export fn eventCallback(id: u32) void {
    const evt_node = Vapor.events_callbacks.get(id) orelse unreachable;
    var event = Event{
        .id = id,
    };
    @call(.auto, evt_node.cb, .{&event});
}

export fn eventInstCallback(id: u32) void {
    const evt_node = Vapor.events_inst_callbacks.get(id).?;
    var event = Event{
        .id = id,
    };
    @call(.auto, evt_node.data.evt_cb, .{ &evt_node.data, &event });
}

export fn hookInstCallback(id: u32) void {
    const hook_cb = Vapor.hooks_inst_callbacks.get(id).?;
    const params_str = Vapor.Kit.getWindowParams() orelse "";
    const path = Kit.getWindowPath();
    var params = std.StringHashMap([]const u8).init(Vapor.frame_arena.getFrameAllocator());
    if (params_str.len != 0) {
        params = Kit.parseParams(params_str, &Vapor.allocator_global) catch return orelse return;
    }
    const context = Vapor.HookContext{
        .from_path = "",
        .to_path = path,
        .params = params,
        .query = params,
    };
    @call(.auto, hook_cb, .{context});
}

pub export fn getRenderTreePtr() ?*UIContext.CommandsTree {
    const tree_op = Vapor.current_ctx.ui_tree;

    if (tree_op != null) {
        // iterateTreeChildren(Vapor.current_ctx.ui_tree.?);
        return Vapor.current_ctx.ui_tree.?;
    }
    return null;
}

pub export fn getRenderCommandPtr(tree: *CommandsTree) [*]u8 {
    if (std.mem.eql(u8, tree.node.id, "global-style")) {
        Vapor.println("getRenderCommandPtr {any}\n", .{tree.node.node_ptr.dirty});
    }
    return @ptrCast(tree.node);
}

export fn getTreeNodeChildrenCount(tree: *CommandsTree) usize {
    return tree.children.items.len;
}

export fn getUiNodeChildrenCount(tree: *CommandsTree) usize {
    if (tree.node.node_ptr.children == null) return 0;
    return tree.node.node_ptr.children.?.items.len;
}

export fn getTreeNodeChild(tree: *CommandsTree, index: usize) *CommandsTree {
    const child = tree.children.items[index];
    return child;
}

export fn getCtxNodeChild(tree: *CommandsTree, index: usize) ?*CommandsTree {
    if (tree.node.node_ptr.children == null) return null;
    const ui_node = tree.node.node_ptr.children.?.items[index];
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
    return Vapor.removed_nodes.items.len;
}

export fn clearRemovedNodesretainingCapacity() void {
    Vapor.removed_nodes.clearRetainingCapacity();
}

export fn getDirtyNodeCount() usize {
    return Vapor.dirty_nodes.items.len;
}

export fn getDirtyNode() [*]const RenderCommand {
    const node = Vapor.dirty_nodes.items.ptr;
    return node;
}

export fn getAddedNodeCount() usize {
    return Vapor.added_nodes.items.len;
}

export fn getAddedNode() [*]const RenderCommand {
    const node = Vapor.added_nodes.items.ptr;
    return node;
}

export fn getNextSiblingPtr(ui_node: *UINode) ?[*]const u8 {
    const parent = ui_node.parent orelse return null;
    const children = parent.children orelse return null;
    if (ui_node.index + 1 >= children.items.len) return null;
    const sibling = children.items[ui_node.index + 1];
    return sibling.uuid.ptr;
}

export fn getNextSiblingLen(ui_node: *UINode) usize {
    const parent = ui_node.parent orelse return 0;
    const children = parent.children orelse return 0;
    if (ui_node.index + 1 >= children.items.len) return 0;
    const sibling = children.items[ui_node.index + 1];
    return sibling.uuid.len;
}

export fn checkPotentialNode(node: *UINode) bool {
    Vapor.potential_nodes.get(node.uuid) orelse return false;
    return true;
}

export fn getNodeParentId(node: *UINode) ?[*]const u8 {
    const parent = node.parent orelse return null;
    return parent.uuid.ptr;
}

export fn getNodeParentIdLen(node: *UINode) usize {
    const parent = node.parent orelse return 0;
    return parent.uuid.len;
}

// The first node needs to be marked as false always
export fn markCurrentTreeDirty() void {
    if (!Vapor.has_context) return;
    const root = Vapor.current_ctx.root orelse return;
    Vapor.markChildrenDirty(root);
}

export fn markUINodeTreeDirty(node: *UINode) void {
    Vapor.markChildrenDirty(node);
}

// The first node needs to be marked as false always
export fn markCurrentTreeNotDirty() void {
    if (!Vapor.has_context) return;
    const root = Vapor.current_ctx.root orelse return;
    Vapor.markChildrenNotDirty(root);
}

export fn getRemovedNode(index: usize) [*]const u8 {
    const node = Vapor.removed_nodes.items[index];
    return node.uuid.ptr;
}

export fn getRemovedNodeIndex(index: usize) usize {
    return Vapor.removed_nodes.items[index].index;
}

export fn getRemovedNodeLength(index: usize) usize {
    return Vapor.removed_nodes.items[index].uuid.len;
}

export fn inputCallback(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Vapor.allocator_global.free(id);
    const element = Vapor.element_registry.get(hashKey(id)) orelse return;
    const text = element.getInputValue() orelse unreachable;
    element.text = text;
}

export fn getElementPtr(id_ptr: [*:0]u8) ?*Vapor.Element {
    const id = std.mem.span(id_ptr);
    defer Vapor.allocator_global.free(id);
    const element = Vapor.element_registry.get(hashKey(id)) orelse return null;
    return element;
}

export fn registerAllListenerCallbacks() void {
    // var itr = Vapor.node_events_callbacks.iterator();
    // while (itr.next()) |entry| {
    //     const ctx_node = entry.value_ptr.*;
    //     @call(.auto, ctx_node.data.runFn, .{&ctx_node.data});
    //     // if (element.on_blur) |on_blur| {
    //     //     _ = element.addInstListener(.mouseleave, element, on_blur);
    //     // }
    //     // if (element.on_change) |on_change| {
    //     //     _ = element.addInstListener(.change, element, on_change);
    //     // }
    //     // if (element.on_submit) |on_submit| {
    //     //     _ = element.addInstListener(.submit, element, on_submit);
    //     // }
    // }

    var evt_itr = Vapor.nodes_with_events.iterator();
    while (evt_itr.next()) |entry| {
        const ui_node = entry.value_ptr.*;
        if (ui_node.event_handlers) |handlers| {
            for (handlers.handlers.items) |handler| {
                if (handler.ctx_aware) {
                    const ctx_node: *const Vapor.CtxAwareEventNode = @ptrCast(@alignCast(handler.cb_opaque));
                    @call(.auto, ctx_node.data.runFn, .{&ctx_node.data});
                    // _ = Vapor.elementInstEventListener(ui_node.uuid, handler.type, ctx_node.data.arguments, ctx_node.data.runFn);
                    // _ = Vapor.elementInstEventListener(ui_node.uuid, handler.type, handler.cb_opaque, evt_node.cb);
                } else {
                    const cb: *const fn (*Vapor.Event) void = @ptrCast(@alignCast(handler.cb_opaque));
                    _ = Vapor.elementEventListener(ui_node, handler.type, cb);
                }
            }
        }
    }
}

/// Calling route renderCycle will mark eveything as dirty
export fn callRouteRenderCycle(ptr: [*:0]u8) void {
    Vapor.packed_animations.clearRetainingCapacity();
    Vapor.packed_layouts.clearRetainingCapacity();
    Vapor.packed_positions.clearRetainingCapacity();
    Vapor.packed_margins_paddings.clearRetainingCapacity();
    Vapor.packed_visuals.clearRetainingCapacity();
    Vapor.packed_interactives.clearRetainingCapacity();
    UIContext.class_map.clearRetainingCapacity();
    Vapor.renderCycle(ptr);
    Vapor.markChildrenDirty(Vapor.current_ctx.root.?);
    return;
}
export fn setRouteRenderTree(ptr: [*:0]u8) void {
    Vapor.renderCycle(ptr);
    return;
}

export fn allocUint8(length: u32) [*]const u8 {
    const slice = Vapor.allocator_global.alloc(u8, length) catch
        @panic("failed to allocate memory");
    return slice.ptr;
}

pub export fn allocateLayoutInfo() *u8 {
    const info_ptr: *u8 = @ptrCast(&Vapor.layout_info);
    return info_ptr;
}

// Export the size of a single RenderCommand for proper memory reading
export fn getRenderCommandSize() usize {
    return @sizeOf(RenderCommand);
}

export fn grainRerender() bool {
    return Vapor.grain_rerender;
}

export fn resetGrainRerender() void {
    Vapor.grain_rerender = false;
}

export fn shouldRerender() bool {
    return Vapor.global_rerender;
}

export fn rerenderEverything() bool {
    return Vapor.rerender_everything;
}

export fn hasDirty() bool {
    return Vapor.has_dirty;
}

export fn resetRerender() void {
    Vapor.global_rerender = false;
    Vapor.rerender_everything = false;
    Vapor.has_dirty = false;
    // Vapor.render_phase = .idle;
}

export fn setRerenderTrue() void {
    Vapor.cycle();
}
// Wrapper functions with dummy implementations for non-WASM targets

export fn callback(callbackId: u32) void {
    const continuation = Vapor.continuations[callbackId];
    if (continuation) |cb| {
        @call(.auto, cb, .{});
    }
}

export fn allocate(size: usize) ?[*]f32 {
    const buf = Vapor.allocator_global.alloc(f32, size) catch |err| {
        Vapor.println("{any}\n", .{err});
        return null;
    };
    return buf.ptr;
}
//
// Global buffer to store the CSS string for returning to JavaScript
var common_style_buffer: [8192 * 6]u8 = undefined;
var common_style: []const u8 = "";
pub export fn getBaseStyles() ?[*]const u8 {
    // var fbs = std.io.fixedBufferStream(&common_style_buffer);
    // var writer = fbs.writer();
    // const base_styles = UIContext.base_styles[0..UIContext.base_style_count];
    // var start: usize = 0;
    // var end: usize = 0;
    // var writer: Writer = undefined;
    // for (base_styles) |style| {
    //     var buffer: [4096]u8 = undefined;
    //     writer.init(buffer[0..]);
    //     writer.writeByte('.') catch |err| {
    //         Vapor.printlnSrcErr("{any}", .{err}, @src());
    //         return null;
    //     };
    //     writer.write(style.style_id.?) catch |err| {
    //         Vapor.printlnSrcErr("{any}", .{err}, @src());
    //         return null;
    //     };
    //     writer.write(" {\n") catch |err| {
    //         Vapor.printlnSrcErr("{any}", .{err}, @src());
    //         return null;
    //     };
    //     StyleCompiler.generateStylePass(null, &style, &writer);
    //     writer.write("}\n") catch |err| {
    //         Vapor.printlnSrcErr("{any}", .{err}, @src());
    //         return null;
    //     };
    //     end += writer.pos;
    //     @memcpy(common_style_buffer[start..end], buffer[0..writer.pos]);
    //     start += writer.pos;
    // }
    //
    // common_style_buffer[end] = 0;
    // common_style = common_style_buffer[0..end];
    return common_style.ptr;
}

pub export fn getBaseStylesLen() usize {
    return common_style.len;
}

var animations_str: []const u8 = "";
pub export fn getAnimationsPtr() ?[*]const u8 {
    var animations = Vapor.animations.iterator();
    var writer: Writer = undefined;
    var buffer: [4096]u8 = undefined;
    writer.init(&buffer);
    while (animations.next()) |entry| {
        const animation = entry.value_ptr.*;
        writer.write("@keyframes ") catch {};
        writer.write(animation._name) catch {};
        writer.writeByte(' ') catch {};
        writer.write("{\n") catch {};
        // From
        writer.write("from { ") catch {};
        writer.write("transform: ") catch {};
        switch (animation._type) {
            .scaleY => {
                writer.write("scaleY(") catch {};
                writer.writeF32(animation.from_value) catch {};
            },
            .scaleX => {
                writer.write("scaleX(") catch {};
                writer.writeF32(animation.from_value) catch {};
            },
            .translateX => {
                writer.write("translateX(") catch {};
                writer.writeF32(animation.from_value) catch {};
                writer.write("px") catch {};
            },
            .translateY => {
                writer.write("translateY(") catch {};
                writer.writeF32(animation.from_value) catch {};
                writer.write("px") catch {};
            },
            else => {},
        }
        writer.write(");") catch {};
        writer.write("}\n") catch {};

        writer.write("to { ") catch {};
        writer.write("transform: ") catch {};
        switch (animation._type) {
            .scaleY => {
                writer.write("scaleY(") catch {};
                writer.writeF32(animation.to_value) catch {};
            },
            .scaleX => {
                writer.write("scaleX(") catch {};
                writer.writeF32(animation.to_value) catch {};
            },
            .translateX => {
                writer.write("translateX(") catch {};
                writer.writeF32(animation.to_value) catch {};
                writer.write("px") catch {};
            },
            .translateY => {
                writer.write("translateY(") catch {};
                writer.writeF32(animation.to_value) catch {};
                writer.write("px") catch {};
            },
            else => {},
        }
        writer.write(");") catch {};
        writer.write("}\n") catch {};
        writer.write("}\n") catch {};
    }
    const len: usize = writer.pos;
    buffer[len] = 0;
    animations_str = buffer[0..len];
    return animations_str.ptr;
}

pub export fn getAnimationsLen() usize {
    return animations_str.len;
}

pub export fn hasExitAnimation(node_ptr: *UINode) bool {
    if (node_ptr.animation_exit != null) {
        return true;
    }
    return false;
}

pub export fn pendingClassesToAdd() void {
    // if (isWasi) {
    //     for (Vapor.classes_to_add.items) |clta| {
    //         Wasm.addClass(clta.element_id.ptr, clta.element_id.len, clta.style_id.ptr, clta.style_id.len);
    //     }
    //     Vapor.classes_to_add.clearAndFree();
    // }
}
pub export fn pendingClassesToRemove() void {
    // if (isWasi) {
    //     for (Vapor.classes_to_remove.items) |cltr| {
    //         Wasm.removeClass(cltr.element_id.ptr, cltr.element_id.len, cltr.style_id.ptr, cltr.style_id.len);
    //     }
    //     Vapor.classes_to_remove.clearAndFree();
    // }
}

export fn cleanUp() void {

    // Vapor.clean_up_ctx.deinit();
    // Vapor.allocator_global.destroy(Vapor.clean_up_ctx);
    Vapor.clean_up_ctx = undefined;
}

export fn timeOutCtxCallback(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Vapor.allocator_global.free(id);
    const node = Vapor.callback_registry.get(hashKey(id)) orelse return;
    @call(.auto, node.data.runFn, .{&node.data});
}

export fn callbackCtx(callback_ptr: [*:0]u8, data_ptr: [*:0]u8, is_in_view: bool, index: usize) void {
    const callback_name = std.mem.span(callback_ptr);
    const data = std.mem.span(data_ptr);
    // defer Vapor.allocator_global.free(callback_name);
    // defer Vapor.allocator_global.free(data);
    const opaque_node = Vapor.opaque_registry.get(hashKey(callback_name)) orelse return;
    var target = struct { url: []const u8, is_in_view: bool, index: usize }{ .url = data, .is_in_view = is_in_view, .index = index };
    @call(.auto, opaque_node.data.runFn, .{@as(*anyopaque, @ptrCast(&target))});
}

export fn onEndCallback() void {
    const length = Vapor.on_end_funcs.items.len;
    if (length == 0) return;
    var i: usize = length - 1;
    while (i >= 0) : (i -= 1) {
        const call = Vapor.on_end_funcs.orderedRemove(i);
        @call(.auto, call, .{});
        if (i == 0) return;
    }
}

export fn timeoutCtxCallBackId(id: usize) void {
    const node = Vapor.time_out_ctx_registry.get(id) orelse return;
    defer _ = Vapor.time_out_ctx_registry.remove(id);
    @call(.auto, node.data.runFn, .{&node.data});
}

// This function gets called from JavaScript when a timeout completes
export fn resumeExecution(callbackId: u32) void {
    const continuation = Vapor.continuations[callbackId];
    if (continuation) |func| {
        // Clear the slot
        Vapor.continuations[callbackId] = null;
        // Call the continuation function
        func();
    }
}

export fn getCSS() ?[*]const u8 {
    return Vapor.generator.buffer[0..Vapor.generator.end].ptr;
}

export fn getCSSLen() usize {
    return Vapor.generator.end;
}

export fn getHeadingLevel(ptr: ?*UINode) u8 {
    const node_ptr = ptr orelse return 0;
    const heading = node_ptr.type == .Heading;
    if (heading) {
        return node_ptr.level orelse return 0;
    }
    return 0;
}

export fn getVideo(node_ptr: *UINode) ?*const Types.Video {
    const video = node_ptr.video orelse return null;
    return &video;
}
