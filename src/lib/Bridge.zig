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
const Wasm = Vapor.Wasm;
const Writer = @import("Writer.zig");
const utils = @import("utils.zig");
const hashKey = utils.hashKey;
const Kit = @import("kit/Kit.zig");
const Packer = @import("Packer.zig");

const API = struct {
    pub fn hookInstCallback(id: u32) callconv(.c) void {
        const hook_cb = Vapor.hooks_inst_callbacks.get(id).?;
        const params_str = Vapor.Kit.getWindowParams() orelse "";
        const path = Kit.getWindowPath() orelse {
            Vapor.printlnSrcErr("Hooks ERROR: Could not get window path", .{}, @src());
            return;
        };
        var params = std.StringHashMap([]const u8).init(Vapor.arena(.frame));
        if (params_str.len != 0) {
            params = Kit.parseParams(params_str, Vapor.allocator_global) catch return orelse return;
        }
        const context = Vapor.HookContext{
            .from_path = "",
            .to_path = path,
            .params = params,
            .query = params,
        };
        @call(.auto, hook_cb, .{context});
    }

    pub fn getCtxNodeChild(tree: *CommandsTree, index: usize) callconv(.c) ?*CommandsTree {
        if (tree.node.node_ptr.children == null) return null;
        const ui_node = tree.node.node_ptr.children.?.items[index];
        for (tree.children.items, 0..) |item, i| {
            if (std.mem.eql(u8, ui_node.uuid, item.node.id)) {
                return tree.children.items[i];
            }
        }
        return null;
    }

    pub fn getTreeNodeChildCommand(tree: *CommandsTree) callconv(.c) *RenderCommand {
        return tree.node;
    }

    pub fn setDirtyToFalse(node: *UINode) callconv(.c) void {
        node.dirty = false;
    }

    pub fn getDirtyNode() callconv(.c) [*]const RenderCommand {
        const node = Vapor.dirty_nodes.items.ptr;
        return node;
    }

    pub fn getAddedNodeCount() callconv(.c) usize {
        return Vapor.added_nodes.items.len;
    }

    pub fn getAddedNode() callconv(.c) [*]const RenderCommand {
        const node = Vapor.added_nodes.items.ptr;
        return node;
    }

    pub fn getNextSiblingPtr(ui_node: *UINode) callconv(.c) ?[*]const u8 {
        const parent = ui_node.parent orelse return null;
        const children = parent.children orelse return null;
        if (ui_node.index + 1 >= children.items.len) return null;
        const sibling = children.items[ui_node.index + 1];
        return sibling.uuid.ptr;
    }

    pub fn getNextSiblingLen(ui_node: *UINode) callconv(.c) usize {
        const parent = ui_node.parent orelse return 0;
        const children = parent.children orelse return 0;
        if (ui_node.index + 1 >= children.items.len) return 0;
        const sibling = children.items[ui_node.index + 1];
        return sibling.uuid.len;
    }

    pub fn checkPotentialNode(_: *UINode) callconv(.c) bool {
        // Vapor.potential_nodes.get(node.uuid) orelse return false;
        return false;
    }

    pub fn getNodeParentId(node: *UINode) callconv(.c) ?[*]const u8 {
        const parent = node.parent orelse return null;
        return parent.uuid.ptr;
    }

    pub fn getNodeParentIdLen(node: *UINode) callconv(.c) usize {
        const parent = node.parent orelse return 0;
        return parent.uuid.len;
    }
    // The first node needs to be marked as false always
    pub fn markCurrentTreeDirty() void {
        if (!Vapor.has_context) return;
        const root = Vapor.current_ctx.root orelse return;
        Vapor.markChildrenDirty(root);
    }

    pub fn markUINodeTreeDirty(node: *UINode) void {
        Vapor.markChildrenDirty(node);
    }
    pub fn inputCallback(id_ptr: [*:0]u8) void {
        const id = std.mem.span(id_ptr);
        defer Vapor.allocator_global.free(id);
        const element = Vapor.element_registry.get(hashKey(id)) orelse return;
        const text = element.getInputValue() orelse unreachable;
        element.text = text;
    }

    pub fn getElementPtr(id_ptr: [*:0]u8) ?*Vapor.Element {
        const id = std.mem.span(id_ptr);
        defer Vapor.allocator_global.free(id);
        const element = Vapor.element_registry.get(hashKey(id)) orelse return null;
        return element;
    }

    pub fn callback(callbackId: u32) void {
        const continuation = Vapor.continuations[callbackId];
        if (continuation) |cb| {
            @call(.auto, cb, .{});
        }
    }

    pub fn cleanUp() void {
        Vapor.clean_up_ctx = undefined;
    }

    pub fn timeOutCtxCallback(id_ptr: [*:0]u8) void {
        const id = std.mem.span(id_ptr);
        defer Vapor.allocator_global.free(id);
        const node = Vapor.callback_registry.get(hashKey(id)) orelse return;
        @call(.auto, node.data.runFn, .{&node.data});
    }

    pub fn timeoutCtxCallBackId(id: usize) void {
        const node = Vapor.time_out_ctx_registry.get(id) orelse return;
        defer _ = Vapor.time_out_ctx_registry.remove(id);
        @call(.auto, node.data.runFn, .{&node.data});
        if (Vapor.mode == .atomic) {
            Vapor.cycle();
        }
    }

    pub fn timeoutCallBackId(id: usize) void {
        const func = Vapor.time_out_registry.get(id) orelse return;
        defer _ = Vapor.time_out_registry.remove(id);
        @call(.auto, func, .{});
        if (Vapor.mode == .atomic) {
            Vapor.cycle();
        }
    }
};

// --- Auto-Export Magic ---
// This runs automatically when this file is imported
comptime {
    const decls = std.meta.declarations(API);

    for (decls) |decl| {
        const val = @field(API, decl.name);
        const Type = @TypeOf(val);
        if (@typeInfo(Type) == .@"fn") {
            // Export it with its own name
            @export(&val, .{ .name = decl.name });
        }
    }
}
